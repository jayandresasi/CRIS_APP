import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_notifier.dart';
import '../providers/profile_notifier.dart';
import '../widgets/vaccine_schedule_card.dart';
import '../theme.dart';
import 'locate_centers_page.dart';
import 'safety_info_page.dart';
import 'reporting_page.dart';
import 'sab_reporting_page.dart';
import 'history_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Report Incident',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportingPage()),
                );
              },
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                'Bite Incident',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SABReportingPage()),
                );
              },
              icon: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                'Suspicious Animal Behavior',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.primary, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<NotificationsNotifier>();
    final unreadCount = notifs.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/CRIS icon.jpg',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CRIS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => _NotificationsSheet(notifier: notifs),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _AppDrawer(notifier: notifs),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavCard(
              label: 'Locate Animal Bite Centers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocateCentersPage()),
              ),
            ),
            const SizedBox(height: 10),
            _NavCard(
              label: 'Bite Prevention & First Aid',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyInfoPage()),
              ),
            ),
            const SizedBox(height: 10),
            _NavCard(
              label: 'View History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showReportSheet(context),
                child: const Text(
                  'Report Incident',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const VaccineScheduleCard(),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  final NotificationsNotifier notifier;
  const _NotificationsSheet({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        if (notifier.notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No notifications'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            itemCount: notifier.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notifier.notifications[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.color.withOpacity(0.15),
                  child: Text(n.emoji),
                ),
                title: Text(
                  n.message,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                trailing: n.isRead
                    ? null
                    : TextButton(
                        onPressed: () => notifier.markAsRead(n.id),
                        child: const Text('Mark read'),
                      ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final NotificationsNotifier notifier;
  const _AppDrawer({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileNotifier>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/CRIS icon.jpg',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Locate Animal Bite Centers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocateCentersPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Bite Prevention & First Aid'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyInfoPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history_outlined,
              color: AppColors.primary,
            ),
            title: const Text('View History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
