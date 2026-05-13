import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_notifier.dart';
import '../providers/profile_notifier.dart';
import '../widgets/vaccine_schedule_card.dart';
import '../theme.dart';
import 'reporting_page.dart';

/// Dashboard page
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();
    final notifs = context.watch<NotificationsNotifier>();
    final unreadCount = notifs.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${profile.name}'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [VaccineScheduleCard()]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReportingPage())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.report_outlined, color: Colors.white),
        label: const Text(
          'Report Incident',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
