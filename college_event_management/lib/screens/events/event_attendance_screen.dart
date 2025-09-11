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
      _toast('Đã check-in cho ${r.userName}');
    } catch (e) {
      _toast('Lỗi check-in: $e', isError: true);
    }
  }

  Future<void> _checkOut(RegistrationModel r) async {
    try {
      await _registrationService.markCheckout(r.id);
      _load();
      _toast('Đã check-out cho ${r.userName}');
    } catch (e) {
      _toast('Lỗi check-out: $e', isError: true);
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
        title: Text('Quản lý điểm danh - ${widget.eventTitle}'),
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
            tooltip: 'Quét QR',
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chưa điểm danh'),
            Tab(text: 'Đã check-in'),
            Tab(text: 'Đã check-out'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                'Lỗi: $_errorMessage',
                style: const TextStyle(color: AppColors.error),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên hoặc email...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
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
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
              ),
            ),
            title: Text(r.userName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.userEmail),
                if (r.attendedAt != null) Text('Check-in: ${r.attendedAt}'),
                if (r.checkedOutAt != null)
                  Text('Check-out: ${r.checkedOutAt}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCheckIn)
                  IconButton(
                    onPressed: () => _checkIn(r),
                    icon: const Icon(Icons.login, color: AppColors.success),
                    tooltip: 'Check-in',
                  ),
                if (showCheckOut)
                  IconButton(
                    onPressed: () => _checkOut(r),
                    icon: const Icon(Icons.logout, color: AppColors.warning),
                    tooltip: 'Check-out',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
