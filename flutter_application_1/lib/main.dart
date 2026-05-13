import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'package:pdfx/pdfx.dart';

import 'models/report.dart';
import 'models/sab_report.dart';
import 'utils/permissions_helper.dart';

// Notification Model
class Notification {
  final String id;
  final String message;
  final String emoji;
  final Color color;
  bool isRead;

  Notification({
    required this.id,
    required this.message,
    required this.emoji,
    required this.color,
    this.isRead = false,
  });
}

// Profile Notifier
class ProfileNotifier extends ChangeNotifier {
  String _name = 'John Doe';
  String _gender = 'Prefer not to say';
  String _age = '34';
  String _dob = '1991-05-18';
  String _phone = '';
  String _email = '';
  String _address = '123 Main Street';
  String _profileImagePath = '';
  String _emergencyName = 'Jane Doe';
  String _emergencyRelationship = 'Spouse';
  String _emergencyPhone = '09123456789';

  String get name => _name;
  String get gender => _gender;
  String get age => _age;
  String get dob => _dob;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  String get profileImagePath => _profileImagePath;
  String get emergencyName => _emergencyName;
  String get emergencyRelationship => _emergencyRelationship;
  String get emergencyPhone => _emergencyPhone;

  void updateProfile({
    required String name,
    required String gender,
    required String age,
    required String dob,
    required String phone,
    String? email,
    required String address,
    required String profileImagePath,
    required String emergencyName,
    required String emergencyRelationship,
    required String emergencyPhone,
  }) {
    _name = name;
    _gender = gender;
    _age = age;
    _dob = dob;
    _phone = phone;
    _email = email ?? '';
    _address = address;
    _profileImagePath = profileImagePath;
    _emergencyName = emergencyName;
    _emergencyRelationship = emergencyRelationship;
    _emergencyPhone = emergencyPhone;
    notifyListeners();
  }
}

class VaccineScheduleCard extends StatefulWidget {
  const VaccineScheduleCard({Key? key}) : super(key: key);

  @override
  State<VaccineScheduleCard> createState() => _VaccineScheduleCardState();
}

class _VaccineScheduleCardState extends State<VaccineScheduleCard> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _schedule = [
    {'day': 'Day 0', 'status': 'completed'},
    {'day': 'Day 3', 'status': 'completed'},
    {'day': 'Day 7', 'status': 'completed'},
    {'day': 'Day 14', 'status': 'upcoming'},
    {'day': 'Day 28', 'status': 'missed'},
  ];

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return const Color(0xFFFF4C4C);
      case 'upcoming':
      default:
        return const Color(0xFFFFC107);
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'missed':
        return Icons.error;
      default:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vaccine Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Calendar placed above the day buttons
            SizedBox(
              height: 320,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _schedule.map((dose) {
                  final status = dose['status']!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      constraints: const BoxConstraints(minWidth: 96),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon(status),
                            color: statusColor(status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dose['day']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notifications Notifier
class NotificationsNotifier extends ChangeNotifier {
  final List<Notification> _notifications = [
    Notification(
      id: '1',
      message: '⚠️ Confirmed rabies case detected 4 km from your address.',
      emoji: '⚠️',
      color: const Color(0xFFFF4C4C),
      isRead: false,
    ),
    Notification(
      id: '2',
      message: '💉 Your 3rd vaccine dose is due tomorrow.',
      emoji: '💉',
      color: const Color(0xFF5BC0EB),
      isRead: false,
    ),
  ];

  List<Notification> get notifications => _notifications;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void addNotification(Notification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ReportAdapter());
  Hive.registerAdapter(SABReportAdapter());
  await Hive.openBox<Report>('reports');
  await Hive.openBox<SABReport>('sab_reports');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider(create: (_) => NotificationsNotifier()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRIS App',
        theme: AppTheme.lightTheme(),
        home: const LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _obscure = true;
  String? _capturedImagePath;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera permission required'),
            content: const Text(
              'Camera permission is required to capture an image. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission denied. Unable to open camera.'),
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return;
      }
      setState(() {
        _capturedImagePath = image.path;
      });
      debugPrint('Captured image path: ${image.path}');
    } catch (e) {
      debugPrint('Camera capture failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to capture image. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/loginpage-bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color.fromRGBO(0, 0, 0, 0.3)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/CRIS icon.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Text(
                                'CRIS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CRIS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rabies Monitoring & Response System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Report. Locate. Get Treated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F6F8),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F6F8),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _openCamera,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primary,
                            ),
                            label: const Text('Capture photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        if (_capturedImagePath != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Photo path:\n$_capturedImagePath',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Be responsible. Protect lives.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _socialCircle({required IconData icon, required Color color}) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
    child: IconButton(
      onPressed: () {},
      icon: Icon(icon, color: color),
    ),
  );
}
