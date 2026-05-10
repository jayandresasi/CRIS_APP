import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
                color: Color(0xFF008080),
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

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _schedule.map((dose) {
                final status = dose['status']!;
                return InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    constraints: const BoxConstraints(minWidth: 96),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFFFFFF),
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
        theme: ThemeData(
          primaryColor: const Color(0xFF0F766E),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F766E),
            secondary: Color(0xFF14B8A6),
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Color(0xFF1F2937),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
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
                                  color: Color(0xFF0F766E),
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
                              color: Color(0xFF0F766E),
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
                              color: Color(0xFF0F766E),
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
                              foregroundColor: const Color(0xFF0F766E),
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
                              backgroundColor: const Color(0xFF0F766E),
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
                              color: Color(0xFF0F766E),
                            ),
                            label: const Text('Capture photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF0F766E)),
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008080),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/CRIS icon.jpg',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Text(
                    'CRIS',
                    style: TextStyle(
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'CRIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
      drawer: const ProfileSidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Main buttons
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NearbyCentersPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF008080),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Locate Animal Bite Centers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SafetyInformationPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF008080),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Bite Prevention & First Aid',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF008080),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Report Incident',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF008080),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ReportBiteIncidentPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.warning),
                              label: const Text('Bite Incident'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ReportSuspiciousAnimalPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.security),
                              label: const Text('Suspicious Animal Behavior'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Report Incident',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
            // Vaccine Schedule section
            _buildVaccineScheduleCard(context),
            const SizedBox(height: 24),
            // Rabies Awareness section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Rabies Awareness',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rabies is a deadly viral disease transmitted through the saliva of infected animals, primarily through bites. Prevention includes vaccinating pets, avoiding contact with stray animals, and seeking immediate medical attention after potential exposure. Early treatment with rabies vaccine and immunoglobulin can prevent the disease.',
                    style: TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineScheduleCard(BuildContext context) {
    final schedule = [
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
                color: Color(0xFF008080),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: schedule.map((dose) {
                final status = dose['status'] as String;
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('${dose['day']} details'),
                        content: Text(
                          'Status: ${status[0].toUpperCase()}${status.substring(1)}\n'
                          'Next step: ${status == 'completed'
                              ? 'All clear'
                              : status == 'missed'
                              ? 'Follow up with healthcare provider'
                              : 'Prepare for upcoming dose'}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFFFFFF),
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
                          dose['day'] as String,
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
          ],
        ),
      ),
    );
  }
}

class NearbyCentersPage extends StatelessWidget {
  const NearbyCentersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final centers = [
      {
        "name": "Iloilo City Health Office ABTC",
        "address": "M.H. del Pilar Street, Iloilo City",
        "phone": "033-333-1111",
        "schedule": "Monday–Friday, 8:00 AM – 5:00 PM",
        "services": [
          {"name": "Anti-rabies vaccine (ARV)", "price": "₱500 per dose"},
          {
            "name": "Equine Rabies Immunoglobulin (ERIG)",
            "price": "₱2,500 per vial",
          },
        ],
        "availableDates": "March 18–22",
        "lat": 10.7005,
        "lng": 122.5660,
      },
      {
        "name": "Western Visayas Medical Center ABTC",
        "address": "Q. Abeto Street, Mandurriao, Iloilo City",
        "phone": "033-321-2841",
        "schedule": "Monday–Saturday, 8:00 AM – 6:00 PM",
        "services": [
          {"name": "Anti-rabies vaccine (ARV)", "price": "₱450 per dose"},
          {
            "name": "Human Rabies Immunoglobulin (HRIG)",
            "price": "₱3,000 per vial",
          },
        ],
        "availableDates": "March 19–23",
        "lat": 10.7080,
        "lng": 122.5370,
      },
      {
        "name": "RavAlert Animal Bite Clinic",
        "address": "33 M.H. Del Pilar Street, Molo, Iloilo City",
        "phone": "0916-566-6070",
        "schedule": "Monday–Sunday, 8:00 AM – 5:00 PM",
        "services": [
          {"name": "Anti-rabies vaccine (ARV)", "price": "₱400 per dose"},
          {
            "name": "Equine Rabies Immunoglobulin (ERIG)",
            "price": "₱2,200 per vial",
          },
        ],
        "availableDates": "March 20–24",
        "lat": 10.6930,
        "lng": 122.5430,
      },
      {
        "name": "La Paz Health Center ABTC",
        "address": "La Paz District, Iloilo City",
        "phone": "033-335-1122",
        "schedule": "Monday–Friday, 8:00 AM – 4:00 PM",
        "services": [
          {"name": "Anti-rabies vaccine (ARV)", "price": "₱500 per dose"},
        ],
        "availableDates": "March 21–25",
        "lat": 10.7150,
        "lng": 122.5620,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A3D9),
        title: const Text('Locate Animal Bite Centers'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search centers or address',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Google Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 360,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(10.7000, 122.5620),
                      zoom: 13,
                    ),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: centers.map((c) {
                      return Marker(
                        markerId: MarkerId(c['name'] as String),
                        position: LatLng(
                          c['lat'] as double,
                          c['lng'] as double,
                        ),
                        infoWindow: InfoWindow(
                          title: c['name'] as String,
                          snippet: c['address'] as String,
                        ),
                      );
                    }).toSet(), // Convert Iterable<Marker> to Set<Marker>
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Nearby ABTC',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: centers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = centers[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CenterDetailPage(center: c),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c['address'] as String,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      c['phone'] as String,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Schedule: ${c['schedule'] as String}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Available: ${c['availableDates'] as String}',
                                  style: const TextStyle(
                                    color: Color(0xFF008080),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CenterDetailPage extends StatelessWidget {
  final Map<String, dynamic> center;

  const CenterDetailPage({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    final services = center['services'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A3D9),
        title: Text(center['name'] as String),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center Information Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center['name'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              center['address'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            center['phone'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              center['schedule'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF008080),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available: ${center['availableDates'] as String}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF008080),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Services Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services & Pricing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...services.map((service) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  service['name'] as String,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Text(
                                service['price'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008080),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Map Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 300,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          center['lat'] as double,
                          center['lng'] as double,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(center['name'] as String),
                          position: LatLng(
                            center['lat'] as double,
                            center['lng'] as double,
                          ),
                          infoWindow: InfoWindow(
                            title: center['name'] as String,
                            snippet: center['address'] as String,
                          ),
                        ),
                      },
                      zoomControlsEnabled: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportBiteIncidentPage extends StatefulWidget {
  const ReportBiteIncidentPage({super.key});

  @override
  State<ReportBiteIncidentPage> createState() => _ReportBiteIncidentPageState();
}

class _ReportBiteIncidentPageState extends State<ReportBiteIncidentPage> {
  final _formKey = GlobalKey<FormState>();

  // Patient Information
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleInitialController;
  late TextEditingController _suffixController;
  late TextEditingController _ageController;
  late TextEditingController _contactNumberController;
  late TextEditingController _addressController;

  // Incident Details
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _animalSpeciesController;
  late TextEditingController _incidentDescriptionController;

  String _gender = 'Male';
  String _exposureType = 'Bite';
  String _animalOwnership = 'Owned';
  String _vaccinationStatus = 'Vaccinated';

  // Medical Action
  String _firstAidGiven = 'Washed wound with soap and water';
  String _patientVaccinationStatus = 'Not vaccinated';

  @override
  void initState() {
    super.initState();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleInitialController = TextEditingController();
    _suffixController = TextEditingController();
    _ageController = TextEditingController();
    _contactNumberController = TextEditingController();
    _addressController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _locationController = TextEditingController();
    _animalSpeciesController = TextEditingController();
    _incidentDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _suffixController.dispose();
    _ageController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _animalSpeciesController.dispose();
    _incidentDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    final report = Report(
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      middleInitial: _middleInitialController.text.trim(),
      suffix: _suffixController.text.trim(),
      age: _ageController.text.trim(),
      gender: _gender,
      contactNumber: _contactNumberController.text.trim(),
      address: _addressController.text.trim(),
      dateOfIncident: _dateController.text.trim(),
      timeOfIncident: _timeController.text.trim(),
      locationOfIncident: _locationController.text.trim(),
      exposureType: _exposureType,
      animalSpecies: _animalSpeciesController.text.trim(),
      animalOwnership: _animalOwnership,
      animalVaccinationStatus: _vaccinationStatus,
      incidentDescription: _incidentDescriptionController.text.trim(),
      firstAidGiven: _firstAidGiven,
      patientVaccinationStatus: _patientVaccinationStatus,
      reportedAt: DateTime.now(),
    );

    final box = Hive.box<Report>('reports');
    box.add(report);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bite Incident Report submitted successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to history so the user can immediately see the saved report.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HistoryPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A3D9),
        title: const Text('Report Bite Incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _middleInitialController,
                              decoration: InputDecoration(
                                labelText: 'Middle Initial',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _suffixController,
                              decoration: InputDecoration(
                                labelText: 'Suffix',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _gender = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Incident Details Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          labelText: 'Date of Incident',
                          hintText: 'YYYY-MM-DD',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: () => _selectTime(context),
                        decoration: InputDecoration(
                          labelText: 'Time of Incident',
                          hintText: 'HH:MM',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location of Incident',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _exposureType,
                        decoration: InputDecoration(
                          labelText: 'Type of Exposure',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Bite', child: Text('Bite')),
                          DropdownMenuItem(
                            value: 'Scratch',
                            child: Text('Scratch'),
                          ),
                          DropdownMenuItem(
                            value: 'Lick on broken skin',
                            child: Text('Lick on broken skin'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _exposureType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _animalSpeciesController,
                        decoration: InputDecoration(
                          labelText: 'Animal Species',
                          hintText: 'e.g., dog, cat, others',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _animalOwnership,
                        decoration: InputDecoration(
                          labelText: 'Ownership of Animal',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Owned',
                            child: Text('Owned'),
                          ),
                          DropdownMenuItem(
                            value: 'Stray',
                            child: Text('Stray'),
                          ),
                          DropdownMenuItem(
                            value: 'Unknown',
                            child: Text('Unknown'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _animalOwnership = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _vaccinationStatus,
                        decoration: InputDecoration(
                          labelText: 'Vaccination Status of Animal',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Vaccinated',
                            child: Text('Vaccinated'),
                          ),
                          DropdownMenuItem(
                            value: 'Unvaccinated',
                            child: Text('Unvaccinated'),
                          ),
                          DropdownMenuItem(
                            value: 'Unknown',
                            child: Text('Unknown'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _vaccinationStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _incidentDescriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description of Incident',
                          hintText:
                              'Provide detailed narrative of the incident',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Medical Action Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Action',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _firstAidGiven,
                        decoration: InputDecoration(
                          labelText: 'First Aid Given',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Washed wound with soap and water',
                            child: Text('Washed wound with soap and water'),
                          ),
                          DropdownMenuItem(
                            value: 'Applied antiseptic',
                            child: Text('Applied antiseptic'),
                          ),
                          DropdownMenuItem(value: 'None', child: Text('None')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _firstAidGiven = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _patientVaccinationStatus,
                        decoration: InputDecoration(
                          labelText: 'Rabies Vaccination Status of Patient',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Previously vaccinated',
                            child: Text('Previously vaccinated'),
                          ),
                          DropdownMenuItem(
                            value: 'Not vaccinated',
                            child: Text('Not vaccinated'),
                          ),
                          DropdownMenuItem(
                            value: 'Unknown',
                            child: Text('Unknown'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _patientVaccinationStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportSuspiciousAnimalPage extends StatefulWidget {
  const ReportSuspiciousAnimalPage({super.key});

  @override
  State<ReportSuspiciousAnimalPage> createState() =>
      _ReportSuspiciousAnimalPageState();
}

class _ReportSuspiciousAnimalPageState
    extends State<ReportSuspiciousAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Reporter Information
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleInitialController;
  late TextEditingController _suffixController;
  late TextEditingController _contactNumberController;
  late TextEditingController _addressController;

  // Incident Details
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  String _behaviorObserved = 'Aggressive chasing/biting';

  // Evidence
  String? _photoPath;
  double? _longitude;
  double? _latitude;

  @override
  void initState() {
    super.initState();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleInitialController = TextEditingController();
    _suffixController = TextEditingController();
    _contactNumberController = TextEditingController();
    _addressController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _suffixController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionsHelper.requestImagePermissions();
    if (!hasPermission) {
      final bool isPermanentlyDenied = Platform.isAndroid
          ? await Permission.storage.isPermanentlyDenied
          : await Permission.photos.isPermanentlyDenied;
      if (!mounted) return;
      if (isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Storage permission is permanently denied. Please enable it in app settings.',
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
            content: Text('Storage permission is required to select photos'),
          ),
        );
      }
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
      await _extractGPS(image.path);
    }
  }

  Future<void> _takePhoto() async {
    final hasPermission = await PermissionsHelper.requestImagePermissions();
    if (!hasPermission) {
      final bool isPermanentlyDenied =
          await Permission.camera.isPermanentlyDenied;
      if (!mounted) return;
      if (isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Camera permission is permanently denied. Please enable it in app settings.',
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
            content: Text('Camera permission is required to take photos'),
          ),
        );
      }
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
      await _extractGPS(image.path);
    }
  }

  Future<void> _extractGPS(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final data = await readExifFromBytes(bytes);
      if (data.containsKey('GPS GPSLatitude') &&
          data.containsKey('GPS GPSLongitude') &&
          data.containsKey('GPS GPSLatitudeRef') &&
          data.containsKey('GPS GPSLongitudeRef')) {
        final latTag = data['GPS GPSLatitude'];
        final lonTag = data['GPS GPSLongitude'];
        final latRefTag = data['GPS GPSLatitudeRef'];
        final lonRefTag = data['GPS GPSLongitudeRef'];

        if (latTag != null &&
            lonTag != null &&
            latRefTag != null &&
            lonRefTag != null) {
          // Parse GPS coordinates from EXIF rational format
          double latitude = _parseGPSCoordinate(
            latTag.values,
            latRefTag.printable,
          );
          double longitude = _parseGPSCoordinate(
            lonTag.values,
            lonRefTag.printable,
          );

          setState(() {
            _latitude = latitude;
            _longitude = longitude;
          });
        }
      }
    } catch (e) {
      // GPS extraction failed, ignore
    }
  }

  double _parseGPSCoordinate(dynamic coord, String ref) {
    if (coord is! List || coord.length != 3) return 0.0;

    // Each element is a rational (numerator/denominator)
    double degrees = coord[0] is List
        ? coord[0][0] / coord[0][1]
        : coord[0].toDouble();
    double minutes = coord[1] is List
        ? coord[1][0] / coord[1][1]
        : coord[1].toDouble();
    double seconds = coord[2] is List
        ? coord[2][0] / coord[2][1]
        : coord[2].toDouble();

    double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);

    // Apply reference (N/S for latitude, E/W for longitude)
    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }

    return decimal;
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    final report = SABReport(
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      middleInitial: _middleInitialController.text.trim(),
      suffix: _suffixController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      address: _addressController.text.trim(),
      dateOfObservation: _dateController.text.trim(),
      timeOfObservation: _timeController.text.trim(),
      location: _locationController.text.trim(),
      behaviorObserved: _behaviorObserved,
      description: _descriptionController.text.trim(),
      photoPath: _photoPath ?? '',
      longitude: _longitude,
      latitude: _latitude,
      reportedAt: DateTime.now(),
    );

    final box = Hive.box<SABReport>('sab_reports');
    box.add(report);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Suspicious Animal Behavior Report submitted successfully!',
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HistoryPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A3D9),
        title: const Text('Report Suspicious Animal Behavior'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reporter Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reporter Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _middleInitialController,
                              decoration: InputDecoration(
                                labelText: 'Middle Initial',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _suffixController,
                              decoration: InputDecoration(
                                labelText: 'Suffix',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Incident Details Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          labelText: 'Date of Observation',
                          hintText: 'YYYY-MM-DD',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: () => _selectTime(context),
                        decoration: InputDecoration(
                          labelText: 'Time of Observation',
                          hintText: 'HH:MM',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _behaviorObserved,
                        decoration: InputDecoration(
                          labelText: 'Behavior Observed',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Aggressive chasing/biting',
                            child: Text('Aggressive chasing/biting'),
                          ),
                          DropdownMenuItem(
                            value: 'Excessive drooling/foaming',
                            child: Text('Excessive drooling/foaming'),
                          ),
                          DropdownMenuItem(
                            value: 'Unusual vocalization',
                            child: Text('Unusual vocalization'),
                          ),
                          DropdownMenuItem(
                            value: 'Paralysis/staggering',
                            child: Text('Paralysis/staggering'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _behaviorObserved = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description of Incident',
                          hintText: 'Provide detailed narrative',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Evidence Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Select Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BC0EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BC0EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_photoPath != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photoPath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _longitude?.toString(),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _latitude?.toString(),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class SABReportDetailPage extends StatelessWidget {
  const SABReportDetailPage({super.key, required this.report});

  final SABReport report;

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<Widget> children) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008080),
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
    }

    Widget rowItem(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(value.isEmpty ? '-' : value)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAB Report Details'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section('Reporter Information', [
            rowItem('Name', report.fullName),
            rowItem('Contact', report.contactNumber),
            rowItem('Address', report.address),
          ]),
          section('Incident Details', [
            rowItem('Date', report.dateOfObservation),
            rowItem('Time', report.timeOfObservation),
            rowItem('Location', report.location),
            rowItem('Behavior Observed', report.behaviorObserved),
            rowItem('Description', report.description),
          ]),
          if (report.photoPath.isNotEmpty) ...[
            section('Evidence', [
              const Text(
                'Photo:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(report.photoPath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (report.longitude != null && report.latitude != null) ...[
                const SizedBox(height: 12),
                rowItem('Longitude', report.longitude!.toString()),
                rowItem('Latitude', report.latitude!.toString()),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(report.latitude!, report.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('location'),
                        position: LatLng(report.latitude!, report.longitude!),
                      ),
                    },
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}

class SafetyInformationPage extends StatelessWidget {
  const SafetyInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A3D9),
        title: const Text('Safety Information'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Immediate actions (red panel)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'What to do if you are bitten',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Stay calm. Wash the wound thoroughly with soap and running water for at least 15 minutes.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. Apply an antiseptic (e.g., iodine or alcohol) and cover with a clean dressing.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3. Control bleeding with gentle pressure if needed. Do not close deep wounds tightly.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '4. Seek medical care immediately — tell the clinician the bite details and follow their advice.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5. Post-exposure prophylaxis (PEP) can prevent rabies if started promptly; bring the animal for observation or report it to local authorities when safe.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick action buttons (placeholders)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Clean Wound'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Get Help'),
                      ),
                    ),
                  ),
                ],
              ),

              // Action tiles matching prototype (2x2)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: const [
                  _SafetyActionCard(
                    title: 'Clean Wound',
                    subtitle: 'Rinse with clean water and mild soap',
                  ),
                  _SafetyActionCard(
                    title: 'Apply Bandage',
                    subtitle: 'Use sterile dressing to cover',
                  ),
                  _SafetyActionCard(
                    title: 'Call for Help',
                    subtitle: 'Contact medical services',
                  ),
                  _SafetyActionCard(
                    title: 'Act Quickly',
                    subtitle: 'Time is critical for treatment',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // About Rabies (green panel)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E68A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'About Rabies',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rabies is a viral disease that affects the nervous system. It is usually transmitted through the bite of an infected animal and is fatal once symptoms appear. Prompt treatment after exposure prevents the disease.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Symptoms
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Symptoms',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Early signs (may be mild): fever, headache, pain or tingling at the wound site.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Advanced signs: agitation, confusion, difficulty swallowing, fear of water (hydrophobia), and paralysis.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prevention tips (green)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E68A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Prevention Tips',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Avoid contact with unfamiliar or stray animals.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Keep pets vaccinated against rabies and follow local vaccination schedules.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Teach children not to approach animals and to tell an adult if bitten.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // PEP note (white card)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'About PEP (Post‑Exposure Prophylaxis)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PEP consists of wound care, a series of rabies vaccinations, and sometimes immunoglobulin. It is highly effective when started as soon as possible after exposure.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Emergency Hotline
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Emergency Hotline',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '0143',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SafetyActionCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactPersonController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _photoPath;

  @override
  void dispose() {
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionsHelper.requestImagePermissions();
    if (!hasPermission) {
      final bool isPermanentlyDenied = Platform.isAndroid
          ? await Permission.storage.isPermanentlyDenied
          : await Permission.photos.isPermanentlyDenied;
      if (!mounted) return;
      if (isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Storage permission is permanently denied. Please enable it in app settings.',
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
            content: Text('Storage permission is required to select photos'),
          ),
        );
      }
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _takePhoto() async {
    final hasPermission = await PermissionsHelper.requestImagePermissions();
    if (!hasPermission) {
      final bool isPermanentlyDenied =
          await Permission.camera.isPermanentlyDenied;
      if (!mounted) return;
      if (isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Camera permission is permanently denied. Please enable it in app settings.',
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
            content: Text('Camera permission is required to take photos'),
          ),
        );
      }
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact person';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BC0EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_photoPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Submit the form
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSidebar extends StatelessWidget {
  const ProfileSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFFF7F9FA),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Consumer<ProfileNotifier>(
            builder: (context, profileNotifier, child) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF008080),
                          backgroundImage:
                              (profileNotifier.profileImagePath.isNotEmpty &&
                                  !kIsWeb)
                              ? FileImage(
                                      File(profileNotifier.profileImagePath),
                                    )
                                    as ImageProvider?
                              : null,
                          child:
                              (profileNotifier.profileImagePath.isEmpty ||
                                  kIsWeb)
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileNotifier.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileNotifier.gender,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${profileNotifier.age} • DOB: ${profileNotifier.dob}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${profileNotifier.address}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emergency: ${profileNotifier.emergencyName} (${profileNotifier.emergencyRelationship}) • ${profileNotifier.emergencyPhone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF008080),
                          ),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Color(0xFF008080)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF008080)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Notifications Section with Dropdown
          Consumer<NotificationsNotifier>(
            builder: (context, notificationsNotifier, child) {
              final unreadCount = notificationsNotifier.notifications
                  .where((n) => !n.isRead)
                  .length;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Notifications Dropdown Button
                      PopupMenuButton<int>(
                        onSelected: (int id) {
                          notificationsNotifier.markAsRead(id.toString());
                        },
                        itemBuilder: (BuildContext context) {
                          return notificationsNotifier.notifications.map((n) {
                            int notificationId = int.parse(n.id);
                            return PopupMenuItem<int>(
                              value: notificationId,
                              child: Container(
                                width: 280,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        color: n.color,
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Click to mark as read',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black45,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF008080),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notifications',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008080),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? const Color(0xFFFF4C4C)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$unreadCount unread notification${unreadCount != 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
           const Divider(),
          ListTile(
            leading: const Icon(Icons.login, color: Color(0xFF008080)),
            title: const Text(
              'Back to Login',
              style: TextStyle(color: Color(0xFF008080)),
            ),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationshipController;
  late TextEditingController _emergencyPhoneController;

  late String _gender;
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    final profileNotifier = context.read<ProfileNotifier>();
    _nameController = TextEditingController(text: profileNotifier.name);
    _ageController = TextEditingController(text: profileNotifier.age);
    _dobController = TextEditingController(text: profileNotifier.dob);
    _phoneController = TextEditingController(text: profileNotifier.phone);
    _emailController = TextEditingController(text: profileNotifier.email);
    _addressController = TextEditingController(text: profileNotifier.address);
    _emergencyNameController = TextEditingController(
      text: profileNotifier.emergencyName,
    );
    _emergencyRelationshipController = TextEditingController(
      text: profileNotifier.emergencyRelationship,
    );
    _emergencyPhoneController = TextEditingController(
      text: profileNotifier.emergencyPhone,
    );
    _gender = profileNotifier.gender;
    _profileImagePath = profileNotifier.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final hasPermission = await PermissionsHelper.requestImagePermissions();
    if (!hasPermission) {
      final bool isPermanentlyDenied = source == ImageSource.camera
          ? await Permission.camera.isPermanentlyDenied
          : Platform.isAndroid
          ? await Permission.storage.isPermanentlyDenied
          : await Permission.photos.isPermanentlyDenied;
      if (!mounted) return;
      if (isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: Text(
              '${source == ImageSource.camera ? 'Camera' : 'Storage'} permission is permanently denied. Please enable it in app settings.',
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
            content: Text('Camera and storage permissions are required'),
          ),
        );
      }
      return;
    }
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _profileImagePath = picked.path;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileNotifier>().updateProfile(
      name: _nameController.text,
      gender: _gender,
      age: _ageController.text,
      dob: _dobController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      profileImagePath: _profileImagePath,
      emergencyName: _emergencyNameController.text,
      emergencyRelationship: _emergencyRelationshipController.text,
      emergencyPhone: _emergencyPhoneController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile details saved.'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Profile photo
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFF008080),
                          backgroundImage: _profileImagePath.isNotEmpty
                              ? (kIsWeb
                                    ? null
                                    : FileImage(File(_profileImagePath))
                                          as ImageProvider)
                              : null,
                          child: _profileImagePath.isEmpty
                              ? const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        hintText: 'YYYY-MM-DD',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _gender = value;
                            });
                          }
                        },
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008080),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emergencyNameController,
                        label: 'Name',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emergencyRelationshipController,
                        label: 'Relationship',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008080),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF008080),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bite Incidents'),
            Tab(text: 'Suspicious Animal Behavior'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [BiteIncidentsTab(), SuspiciousAnimalBehaviorTab()],
      ),
    );
  }
}

class BiteIncidentsTab extends StatelessWidget {
  const BiteIncidentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Report>('reports');

    return ValueListenableBuilder<Box<Report>>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final reports = box.values.toList().cast<Report>().reversed.toList();

        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'No bite incident reports yet.\nSubmit a bite incident report to see history.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportDetailPage(report: report),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.fullName.isEmpty
                            ? 'Unknown Patient'
                            : report.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.dateOfIncident,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.exposureType} · ${report.animalSpecies}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SuspiciousAnimalBehaviorTab extends StatelessWidget {
  const SuspiciousAnimalBehaviorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<SABReport>('sab_reports');

    return ValueListenableBuilder<Box<SABReport>>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final reports = box.values.toList().cast<SABReport>().reversed.toList();

        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'No suspicious animal behavior reports yet.\nSubmit a suspicious animal behavior report to see history.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SABReportDetailPage(report: report),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.behaviorObserved,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.dateOfObservation,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.location,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<Widget> children) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008080),
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
    }

    Widget rowItem(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(value.isEmpty ? '-' : value)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: const Color(0xFF008080),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section('Patient Information', [
            rowItem('Name', report.fullName),
            rowItem('Age', report.age),
            rowItem('Gender', report.gender),
            rowItem('Contact', report.contactNumber),
            rowItem('Address', report.address),
          ]),
          section('Incident Details', [
            rowItem('Date', report.dateOfIncident),
            rowItem('Time', report.timeOfIncident),
            rowItem('Location', report.locationOfIncident),
            rowItem('Exposure Type', report.exposureType),
            rowItem('Animal Species', report.animalSpecies),
            rowItem('Ownership', report.animalOwnership),
            rowItem('Animal Vaccination', report.animalVaccinationStatus),
            rowItem('Description', report.incidentDescription),
          ]),
          section('Medical Action', [
            rowItem('First Aid Given', report.firstAidGiven),
            rowItem(
              'Rabies Vaccination Status',
              report.patientVaccinationStatus,
            ),
          ]),
        ],
      ),
    );
  }
}
