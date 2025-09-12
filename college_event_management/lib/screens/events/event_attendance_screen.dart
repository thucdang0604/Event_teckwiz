import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/registration_model.dart';
import '../../services/registration_service.dart';
import '../../providers/auth_provider.dart';
import '../qr/qr_scanner_screen.dart';

class EventAttendanceScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventAttendanceScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventAttendanceScreen> createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final RegistrationService _registrationService = RegistrationService();
  List<RegistrationModel> _all = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final regs = await _registrationService.getEventRegistrations(
        widget.eventId,
      );
      setState(() {
        _all = regs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RegistrationModel> _filterForTab(int tab) {
    Iterable<RegistrationModel> src = _all;
    if (_search.isNotEmpty) {
      src = src.where(
        (r) =>
            r.userName.toLowerCase().contains(_search.toLowerCase()) ||
            r.userEmail.toLowerCase().contains(_search.toLowerCase()),
      );
    }
    switch (tab) {
      case 0:
        return src.where((r) => r.isApproved && !r.attended).toList();
      case 1:
        return src.where((r) => r.attended && r.checkedOutAt == null).toList();
      default:
        return src.where((r) => r.checkedOutAt != null).toList();
    }
  }

  Future<void> _checkIn(RegistrationModel r) async {
    try {
      await _registrationService.markAttendance(r.id);
      _load();
      _toast('Successfully checked in ${r.userName}');
    } catch (e) {
      _toast('Check-in error: $e', isError: true);
    }
  }

  Future<void> _checkOut(RegistrationModel r) async {
    try {
      await _registrationService.markCheckout(r.id);
      _load();
      _toast('Successfully checked out ${r.userName}');
    } catch (e) {
      _toast('Check-out error: $e', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Management - ${widget.eventTitle}'),
        actions: [
          IconButton(
            onPressed: () async {
              final refreshed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
              if (refreshed == true) _load();
            },
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Not Attended'),
            Tab(text: 'Checked In'),
            Tab(text: 'Checked Out'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF10b981)),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_filterForTab(0), showCheckIn: true),
                      _buildList(_filterForTab(1), showCheckOut: true),
                      _buildList(_filterForTab(2)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildList(
    List<RegistrationModel> items, {
    bool showCheckIn = false,
    bool showCheckOut = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No participants found in this category',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10b981), Color(0xFF34d399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (r.attendedAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.login,
                              size: 14,
                              color: Color(0xFF10b981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Checked in: ${_formatDateTime(r.attendedAt!.toString())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10b981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (r.checkedOutAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              size: 14,
                              color: Color(0xFFf59e0b),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Checked out: ${_formatDateTime(r.checkedOutAt!.toString())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFf59e0b),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (showCheckIn || showCheckOut) ...[
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      if (showCheckIn)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10b981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _checkIn(r),
                            icon: const Icon(
                              Icons.login,
                              color: Color(0xFF10b981),
                              size: 20,
                            ),
                            tooltip: 'Check In',
                          ),
                        ),
                      if (showCheckOut) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFf59e0b).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _checkOut(r),
                            icon: const Icon(
                              Icons.logout,
                              color: Color(0xFFf59e0b),
                              size: 20,
                            ),
                            tooltip: 'Check Out',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
