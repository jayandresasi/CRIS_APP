import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_notifier.dart';
import '../providers/profile_notifier.dart';
import 'login_page.dart';
import '../widgets/vaccine_schedule_card.dart';
import '../theme.dart';
import 'locate_centers_page.dart';
import 'safety_info_page.dart';
import 'reporting_page.dart';
import 'qr_scanner_page.dart';
import 'sab_reporting_page.dart';
import 'history_page.dart';
import 'user_info_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoggingOut = false;
  bool _isConfirmingLogout = false;

  String _scanFlagKey(String uid) => 'abtc_qr_scanned_$uid';
  String _scanFacilityIdKey(String uid) => 'abtc_facility_id_$uid';
  String _scanFacilityNameKey(String uid) => 'abtc_facility_name_$uid';
  String _scanFacilityCodeKey(String uid) => 'abtc_facility_code_$uid';

  Future<void> _openPreAbtcFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    final settings = Hive.box('settings');
    final hasScanned = user != null &&
        settings.get(_scanFlagKey(user.uid), defaultValue: false) == true;
    ScannedFacility? facility;

    if (!hasScanned || user == null) {
      final scanned = await Navigator.of(context).push<ScannedFacility>(
        MaterialPageRoute(builder: (_) => const QrScannerPage()),
      );
      if (scanned == null || !mounted) return;
      facility = scanned;

      final scannedUser = FirebaseAuth.instance.currentUser;
      if (scannedUser != null) {
        await settings.put(_scanFlagKey(scannedUser.uid), true);
        await settings.put(_scanFacilityIdKey(scannedUser.uid), scanned.facilityId);
        await settings.put(_scanFacilityNameKey(scannedUser.uid), scanned.name);
        // FIX: the facility code was never saved on the first scan.
        await settings.put(_scanFacilityCodeKey(scannedUser.uid), scanned.facilityAcronym);
      }
    } else {
      final facilityId = settings.get(_scanFacilityIdKey(user.uid)) as String?;
      final facilityName =
          settings.get(_scanFacilityNameKey(user.uid)) as String?;
      if (facilityId == null || facilityName == null) {
        final scanned = await Navigator.of(context).push<ScannedFacility>(
          MaterialPageRoute(builder: (_) => const QrScannerPage()),
        );
        if (scanned == null || !mounted) return;
        facility = scanned;
        await settings.put(_scanFacilityIdKey(user.uid), scanned.facilityId);
        await settings.put(_scanFacilityNameKey(user.uid), scanned.name);
        await settings.put(_scanFacilityCodeKey(user.uid), scanned.facilityAcronym);
      } else {
        final facilityCode =
            settings.get(_scanFacilityCodeKey(user.uid)) as String?;
        facility = ScannedFacility(
            facilityId: facilityId,
            name: facilityName,
            facilityAcronym: facilityCode ?? '');
      }
    }

    // FIX: null-check instead of using the `!` operator.
    if (!mounted || facility == null) return;
    _showReportChoiceDialog(facility);
  }

  Future<void> _showReportChoiceDialog(ScannedFacility facility) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReportChoice(
                  icon: Icons.person_outline,
                  label: 'Report for Self',
                  onTap: () => _openSelfReport(dialogContext, facility),
                ),
                const SizedBox(height: 4),
                _ReportChoice(
                  icon: Icons.note_add_outlined,
                  label: 'New Report',
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportingPage(
                          facilityId: facility.facilityId,
                          facilityAcronym: facility.facilityAcronym,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSelfReport(
      BuildContext dialogContext, ScannedFacility facility) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showNoAccountSavedMessage();
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(user.uid)
          .get();
      if (!profile.exists) {
        _showNoAccountSavedMessage();
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Unable to check the saved account. Please try again.'),
        ));
      return;
    }

    // FIX: also make sure the dialog's own context is still valid.
    if (!mounted || !dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportingPage(
          reportingForSelf: true,
          facilityId: facility.facilityId,
          facilityAcronym: facility.facilityAcronym,
        ),
      ),
    );
  }

  void _showNoAccountSavedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('No account saved\nUse New Report instead.'),
      ));
  }

  Future<void> _confirmAndLogout() async {
    if (_isLoggingOut || _isConfirmingLogout) return;
    setState(() => _isConfirmingLogout = true);
    final profileNotifier = context.read<ProfileNotifier>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isConfirmingLogout = false);
      return;
    }

    setState(() {
      _isConfirmingLogout = false;
      _isLoggingOut = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
      return;
    }

    // A local cache issue should not keep a user on an authenticated screen
    // after Firebase has successfully signed them out.
    try {
      await profileNotifier.clearForLogout();
    } catch (error) {
      debugPrint('Unable to clear cached profile during logout: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
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
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _NotificationsSheet(notifier: notifs),
                    ),
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
      drawer: _AppDrawer(
        notifier: notifs,
        isLoggingOut: _isLoggingOut || _isConfirmingLogout,
        onLogout: _confirmAndLogout,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          48 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavCard(
              icon: Icons.location_on_outlined,
              label: 'Locate Animal Bite Centers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocateCentersPage()),
              ),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.health_and_safety_outlined,
              label: 'Bite Prevention & First Aid',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyInfoPage()),
              ),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.history_outlined,
              label: 'View History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _openPreAbtcFlow,
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                label: const Text(
                  'Patient Form',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SABReportingPage()),
                ),
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
            ),
            const SizedBox(height: 16),
            const VaccineScheduleCard(),
          ],
        ),
      ),
    );
  }
}

class _ReportChoice extends StatelessWidget {
  const _ReportChoice({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  const _NavCard(
      {required this.label, required this.onTap, required this.icon});

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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 20),
            ],
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          if (notifier.notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No notifications'),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: notifier.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = notifier.notifications[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.color.withValues(alpha: 0.15),
                      child: Text(n.emoji),
                    ),
                    title: Text(
                      n.message,
                      style: TextStyle(
                        fontWeight:
                            n.isRead ? FontWeight.normal : FontWeight.bold,
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
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final NotificationsNotifier notifier;
  final bool isLoggingOut;
  final VoidCallback onLogout;
  const _AppDrawer({
    required this.notifier,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>();
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
            leading: const Icon(Icons.person_outline, color: AppColors.primary),
            title: const Text('User Information'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserInfoPage()),
              );
            },
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
            onTap: isLoggingOut ? null : onLogout,
          ),
        ],
      ),
    );
  }
}
