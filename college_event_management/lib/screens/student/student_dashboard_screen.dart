import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../events/event_registration_screen.dart';
import '../../services/registration_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadUpcomingEvents();
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.currentUser?.fullName ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xfff9fafb),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(userName),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _HomeTab(),
                  _EventsTab(),
                  _TicketsTab(),
                  _CertificatesTab(),
                  _ProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF8b5cf6)],
                  ),
                ),
                child: Text(
                  userName.isNotEmpty ? userName.trim()[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _circleIconButton(Icons.notifications_outlined),
              const SizedBox(width: 8),
              _circleIconButton(Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF6b7280),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Certificates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: const Color(0xFF4b5563)),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(context),
          const SizedBox(height: 16),
          _quickActions(context),
          const SizedBox(height: 16),
          _sectionHeader('Featured Events'),
          const SizedBox(height: 8),
          if (eventProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (eventProvider.filteredEvents.isEmpty)
            _emptyState(
              icon: Icons.event_busy,
              title: 'No events yet',
              desc: 'Please check back later for new events.',
            )
          else
            Column(
              children: eventProvider.filteredEvents
                  .take(5)
                  .map((e) => _eventCard(e, context))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _welcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8b5cf6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Welcome!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explore and join exciting campus events.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _actionCard(
          icon: Icons.qr_code_scanner,
          color: const Color(0xFFEEF2FF),
          iconColor: AppColors.primary,
          title: 'Scan QR',
          desc: 'Event check-in',
          onTap: () => Navigator.of(context).pushNamed('/qr-scanner'),
        ),
        _actionCard(
          icon: Icons.search,
          color: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF3b82f6),
          title: 'Search',
          desc: 'Find events',
          onTap: () {},
        ),
        _actionCard(
          icon: Icons.event_available,
          color: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF10b981),
          title: 'Registered',
          desc: 'Your events',
          onTap: () {},
        ),
        _actionCard(
          icon: Icons.chat_bubble_outline,
          color: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF64748b),
          title: 'Support',
          desc: 'Contact organizers',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String desc,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }

  Widget _eventCard(EventModel event, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.bookmark_border, color: Color(0xFF6b7280)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF9ca3af),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.startDate.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF9ca3af),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
                flex: 0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  if (user == null) return;
                  try {
                    final service = RegistrationService();
                    final already = await service.isUserRegisteredForEvent(
                      event.id,
                      user.id,
                    );
                    if (already) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn đã đăng ký sự kiện này.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventRegistrationScreen(event: event),
                      ),
                    );
                  } catch (_) {}
                },
                child: const Text('Register'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Details')),
            ],
          ),
        ],
      ),
    );
  }

  // Full events tab
  // Shows all events and allows registration similar to Home
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('All Events'),
          const SizedBox(height: 8),
          if (eventProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (eventProvider.events.isEmpty)
            _emptyState(
              icon: Icons.event_busy,
              title: 'No events',
              desc: 'Currently there are no events available.',
            )
          else
            Column(
              children: eventProvider.events
                  .map((e) => _eventCard2(e, context))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 56, color: const Color(0xFF9ca3af)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: Color(0xFF6b7280))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Explore events')),
        ],
      ),
    );
  }

  Widget _eventCard2(EventModel event, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.bookmark_border, color: Color(0xFF6b7280)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF9ca3af),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.startDate.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF9ca3af),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
                flex: 0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  if (user == null) return;
                  try {
                    final service = RegistrationService();
                    final already = await service.isUserRegisteredForEvent(
                      event.id,
                      user.id,
                    );
                    if (already) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn đã đăng ký sự kiện này.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventRegistrationScreen(event: event),
                      ),
                    );
                  } catch (_) {}
                },
                child: const Text('Register'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Details')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Your tickets'),
          const SizedBox(height: 8),
          _ticketCard(),
          _ticketCard(),
        ],
      ),
    );
  }

  Widget _ticketCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Fusion Fiesta 2025',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '10:00 10/15/2025 • Hall A',
                  style: TextStyle(color: Color(0xFF6b7280), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.qr_code,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Certificates'),
          const SizedBox(height: 8),
          _certificateCard(),
          _certificateCard(),
        ],
      ),
    );
  }

  Widget _certificateCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Certificate of Participation',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Event: Innovation Day 2025',
            style: TextStyle(color: Color(0xFF6b7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card (centered)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(42),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF8b5cf6)],
                          ),
                        ),
                        child: Text(
                          (user?.fullName ?? 'S').trim().isNotEmpty
                              ? (user!.fullName.trim()[0]).toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'Student',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Student',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Information card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _infoTile(
                    icon: Icons.person_outline,
                    label: 'Full name',
                    value: user?.fullName ?? '',
                  ),
                  const Divider(height: 1),
                  _infoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '',
                  ),
                  if ((user?.phoneNumber ?? '').isNotEmpty) ...[
                    const Divider(height: 1),
                    _infoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user!.phoneNumber!,
                    ),
                  ],
                  if ((user?.studentId ?? '').isNotEmpty) ...[
                    const Divider(height: 1),
                    _infoTile(
                      icon: Icons.badge_outlined,
                      label: 'Student ID',
                      value: user!.studentId!,
                    ),
                  ],
                  if ((user?.department ?? '').isNotEmpty) ...[
                    const Divider(height: 1),
                    _infoTile(
                      icon: Icons.apartment_outlined,
                      label: 'Department',
                      value: user!.department!,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sign out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => auth.signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
