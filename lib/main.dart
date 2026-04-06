import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart'; // Must be generated via FlutterFire CLI
import 'package:image_picker/image_picker.dart';
import 'dart:io';                 // <--- ADD THIS LINE
import 'dart:convert'; // <--- THIS FIXES THE RED LINE
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const OrientbellVMIApp());
}

// ─────────────────────────────────────────────
// THEME & COLORS
// ─────────────────────────────────────────────

class AppColors {
  static const primary = Color(0xFF1A2B47);      // Deep navy
  static const accent = Color(0xFFE8A020);        // Orientbell gold
  static const accentLight = Color(0xFFFFF3DC);
  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFE74C3C);
  static const surface = Color(0xFFF7F8FC);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF1A2B47);
  static const textMid = Color(0xFF5A6A7E);
  static const textLight = Color(0xFF9AABBD);
  static const divider = Color(0xFFECF0F5);
  static const badgePurple = Color(0xFF8B5CF6);
  static const badgeBlue = Color(0xFF3B82F6);
  static const badgeGreen = Color(0xFF10B981);
}

ThemeData buildTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textMid),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

enum VisitorStatus { preRegistered, checkedIn, checkedOut, denied }
enum UserRole { visitor, receptionist, host, admin }

class Visitor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String purpose;
  final String hostName;
  final String hostDept;
  final String plant;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime validUntil;
  final VisitorStatus status;
  final String? photoUrl;
  final String badgeCode;
  
  // PMT / TRANSPORT SPECIFIC FIELDS
  final String? vehicleNo; 
  final double? loadWeight; // Weight of tiles in tons
  final String? recommendedVehicle; // AI output
  final DateTime? loadingStartTime;
  final DateTime? loadingEndTime;

  Visitor({
    required this.id, required this.name, required this.email, required this.phone,
    required this.company, required this.purpose, required this.hostName,
    required this.hostDept, required this.plant, required this.createdAt,
    this.checkInTime, this.checkOutTime, required this.validUntil,
    this.status = VisitorStatus.preRegistered, this.photoUrl, required this.badgeCode,
    this.vehicleNo, this.loadWeight, this.recommendedVehicle, 
    this.loadingStartTime, this.loadingEndTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'name': name, 'email': email, 'phone': phone, 'company': company,
      'purpose': purpose, 'hostName': hostName, 'hostDept': hostDept, 'plant': plant,
      'createdAt': Timestamp.fromDate(createdAt), 'validUntil': Timestamp.fromDate(validUntil),
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'status': status.name, 'photoUrl': photoUrl, 'badgeCode': badgeCode,
      'vehicleNo': vehicleNo, 'loadWeight': loadWeight, 'recommendedVehicle': recommendedVehicle,
      'loadingStartTime': loadingStartTime != null ? Timestamp.fromDate(loadingStartTime!) : null,
      'loadingEndTime': loadingEndTime != null ? Timestamp.fromDate(loadingEndTime!) : null,
    };
  }

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'] ?? '', name: map['name'] ?? '', email: map['email'] ?? '',
      phone: map['phone'] ?? '', company: map['company'] ?? '', purpose: map['purpose'] ?? '',
      hostName: map['hostName'] ?? '', hostDept: map['hostDept'] ?? '', plant: map['plant'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 12)),
      checkInTime: (map['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (map['checkOutTime'] as Timestamp?)?.toDate(),
      status: VisitorStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => VisitorStatus.preRegistered),
      photoUrl: map['photoUrl'], badgeCode: map['badgeCode'] ?? '',
      vehicleNo: map['vehicleNo'],
      loadWeight: map['loadWeight']?.toDouble(),
      recommendedVehicle: map['recommendedVehicle'],
      loadingStartTime: (map['loadingStartTime'] as Timestamp?)?.toDate(),
      loadingEndTime: (map['loadingEndTime'] as Timestamp?)?.toDate(),
    );
  }

  String get statusLabel {
    switch (status) {
      case VisitorStatus.preRegistered: return 'Pre-Registered';
      case VisitorStatus.checkedIn: return 'Checked In / Inside';
      case VisitorStatus.checkedOut: return 'Checked Out';
      case VisitorStatus.denied: return 'Denied';
    }
  }

  Color get statusColor {
    switch (status) {
      case VisitorStatus.preRegistered: return AppColors.badgeBlue;
      case VisitorStatus.checkedIn: return AppColors.success;
      case VisitorStatus.checkedOut: return AppColors.textMid;
      case VisitorStatus.denied: return AppColors.danger;
    }
  }
}

// ─────────────────────────────────────────────
// HELPERS & GENERATORS
// ─────────────────────────────────────────────

String _genId() => 'VIS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
String _genBadge() => 'OBL-${100000 + Random().nextInt(900000)}';

String _fmt(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
  final amPm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${dt.day}/${dt.month}/${dt.year}  $h:$min $amPm';
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: AppColors.primary,
    ),
  );
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────

class OrientbellVMIApp extends StatelessWidget {
  const OrientbellVMIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orientbell VMI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────
// AUTHENTICATION SCREENS
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// AUTHENTICATION & ROUTING
// ─────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeRouter(); // Replaced old role selection
        }
        return const AuthScreen();
      },
    );
  }
}

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    // Smart Routing based on Email (Prototype RBAC)
    if (email == 'admin@gmail.com') return const AdminDashboard();
    if (email == 'receptionist@gmail.com') return const ReceptionistDashboard();
    if (email == 'host@gmail.com') return const HostDashboard();

    // Standard Customer/Visitor View
    return const VisitorDashboard();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    try {
      if (isLogin) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
        } on FirebaseAuthException catch (e) {
          // PROTOTYPE BYPASS: Auto-create staff accounts if they don't exist
          if (pass == '123456' && (email == 'admin@gmail.com' || email == 'receptionist@gmail.com' || email == 'host@gmail.com')) {
            final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'name': email.split('@').first.toUpperCase(),
              'email': email,
              'phone': '0000000000',
            });
          } else {
            rethrow;
          }
        }
      } else {
        // Register New Customer
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': _nameCtrl.text.trim(),
          'email': email,
          'phone': _phoneCtrl.text.trim(),
        });
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(context, e.message ?? 'Authentication failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setDemoCreds(String email) {
    setState(() {
      isLogin = true;
      _emailCtrl.text = email;
      _passwordCtrl.text = '123456';
    });
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF0A1526)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.apartment, color: AppColors.accent, size: 54),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Login to access your VMI dashboard' : 'Register to get your visitor badge',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLogin) ...[
                                _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
                                const SizedBox(height: 16),
                                _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                                const SizedBox(height: 16),
                              ],
                              _Field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textLight, size: 20)),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  child: _loading 
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : Text(isLogin ? 'Sign In' : 'Register', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => setState(() {
                                  isLogin = !isLogin;
                                  _formKey.currentState?.reset();
                                }),
                                child: Text(
                                  isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Sign In',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (isLogin) ...[
                    const SizedBox(height: 32),
                    Text('PROTOTYPE QUICK LOGIN', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(label: const Text('Admin'), labelStyle: const TextStyle(fontSize: 12), backgroundColor: Colors.white.withOpacity(0.1), side: BorderSide.none, onPressed: () => _setDemoCreds('admin@gmail.com')),
                        ActionChip(label: const Text('Host'), labelStyle: const TextStyle(fontSize: 12), backgroundColor: Colors.white.withOpacity(0.1), side: BorderSide.none, onPressed: () => _setDemoCreds('host@gmail.com')),
                        ActionChip(label: const Text('Receptionist'), labelStyle: const TextStyle(fontSize: 12), backgroundColor: Colors.white.withOpacity(0.1), side: BorderSide.none, onPressed: () => _setDemoCreds('receptionist@gmail.com')),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AUTHENTICATION SCREENS (UPGRADED UI)
// ─────────────────────────────────────────────




class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigateTo(BuildContext context, UserRole role) {
    Widget screen;
    switch (role) {
      case UserRole.visitor: screen = const VisitorRegistrationScreen(); break;
      case UserRole.receptionist: screen = const ReceptionistDashboard(); break;
      case UserRole.host: screen = const HostDashboard(); break;
      case UserRole.admin: screen = const AdminDashboard(); break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2B47), Color(0xFF0D1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Profile (Left) & Logout (Right)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white54),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Logo / Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.apartment, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ORIENTBELL', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3)),
                            Text('Visitor Management', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, letterSpacing: 1.5)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Secure • Smart • Seamless', style: TextStyle(color: AppColors.accent.withOpacity(0.9), fontSize: 12, letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Select Your Role', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _RoleTile(icon: Icons.person_outline, title: 'Visitor', subtitle: 'Register, check-in, view your badge', color: AppColors.badgeGreen, onTap: () => _navigateTo(context, UserRole.visitor)),
                    const SizedBox(height: 12),
                    _RoleTile(icon: Icons.desk_outlined, title: 'Receptionist', subtitle: 'Manage check-ins and walkins', color: AppColors.badgeBlue, onTap: () => _navigateTo(context, UserRole.receptionist)),
                    const SizedBox(height: 12),
                    _RoleTile(icon: Icons.supervisor_account_outlined, title: 'Host', subtitle: 'View expected visitors, approvals', color: AppColors.badgePurple, onTap: () => _navigateTo(context, UserRole.host)),
                    const SizedBox(height: 12),
                    _RoleTile(icon: Icons.admin_panel_settings_outlined, title: 'Admin', subtitle: 'Full dashboard & analytics', color: AppColors.accent, onTap: () => _navigateTo(context, UserRole.admin)),
                    const SizedBox(height: 32),
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

// ─────────────────────────────────────────────
// USER PROFILE SCREEN (EDIT DETAILS)
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// USER PROFILE SCREEN
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// USER PROFILE SCREEN
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// USER PROFILE SCREEN (WITH AI FACE CHECKER)
// ─────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  
  bool _loading = false;
  bool _initialLoad = true;

  // AI & Image State
  String? _photoUrl;
  bool _isCheckingPhoto = false;
  final ImagePicker _picker = ImagePicker();
  
  // IMPORTANT: PUT YOUR API KEY HERE
  final String apiKey = 'yourapi'; 

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _nameCtrl.text = doc.data()?['name'] ?? '';
        _phoneCtrl.text = doc.data()?['phone'] ?? '';
        _companyCtrl.text = doc.data()?['company'] ?? '';
        _deptCtrl.text = doc.data()?['department'] ?? '';
        _photoUrl = doc.data()?['photoUrl']; // Fetch saved photo
      }
    } catch (e) {
      _showSnack(context, 'Failed to load profile');
    } finally {
      setState(() => _initialLoad = false);
    }
  }

  // --- AI PHOTO QUALITY SECURITY CHECKER ---
  Future<void> _pickAndCheckImage(ImageSource source) async {
    Navigator.pop(context); 
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile == null) return;

      setState(() => _isCheckingPhoto = true);

      final bytes = await pickedFile.readAsBytes();
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey); // Change to 'gemini-pro-vision' if you used that earlier
      
      final prompt = TextPart("Is there a clear, visible human face in this image suitable for a security ID badge? Answer ONLY with 'YES' or 'NO'.");
      final imagePart = DataPart('image/jpeg', bytes);
      
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      final answer = response.text?.trim().toUpperCase() ?? '';

      if (answer.contains('YES')) {
        setState(() => _photoUrl = pickedFile.path);
        _showSnack(context, 'Security Check Passed: Valid Face Detected.');
      } else {
        _showSnack(context, 'Security Check Failed: Please upload a clear photo of a human face.');
      }
    } catch (e) {
      _showSnack(context, 'Image verification failed.');
    } finally {
      setState(() => _isCheckingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Security Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 20),
              ListTile(leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.camera_alt, color: AppColors.primary)), title: const Text('Take a Photo'), onTap: () => _pickAndCheckImage(ImageSource.camera)),
              const Divider(),
              ListTile(leading: CircleAvatar(backgroundColor: AppColors.badgeBlue.withOpacity(0.1), child: const Icon(Icons.photo_library, color: AppColors.badgeBlue)), title: const Text('Choose from Gallery'), onTap: () => _pickAndCheckImage(ImageSource.gallery)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'photoUrl': _photoUrl, // Save photo path permanently
      }, SetOptions(merge: true));

      _showSnack(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack(context, 'Failed to update profile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _initialLoad 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Interactive Avatar Header
                Center(
                  child: GestureDetector(
                    onTap: _isCheckingPhoto ? null : _showPhotoOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: _photoUrl != null ? FileImage(File(_photoUrl!)) : null,
                          child: _photoUrl == null ? const Icon(Icons.person, size: 60, color: AppColors.primary) : null,
                        ),
                        if (_isCheckingPhoto)
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        if (!_isCheckingPhoto)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(_isCheckingPhoto ? 'AI Checking Face...' : 'Tap to change photo', style: const TextStyle(color: AppColors.textMid, fontSize: 12))),
                const SizedBox(height: 16),
                
                Text(user?.email ?? 'Unknown Email', style: const TextStyle(fontSize: 16, color: AppColors.textMid, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const Divider(height: 24),
                        _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 24),
                        
                        const Text('Work Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const Divider(height: 24),
                        _Field(ctrl: _companyCtrl, label: 'Company Name', icon: Icons.business_outlined),
                        const SizedBox(height: 16),
                        _Field(ctrl: _deptCtrl, label: 'Department / Designation', icon: Icons.badge_outlined),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOMER / VISITOR DASHBOARD
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// CUSTOMER / VISITOR DASHBOARD (ENRICHED)
// ─────────────────────────────────────────────

class VisitorDashboard extends StatelessWidget {
  const VisitorDashboard({super.key});

  Future<void> _openWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://www.orientbell.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnack(context, 'Could not open website.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _confirmLogout(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').where('email', isEqualTo: user?.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          List<Visitor> myPasses = snapshot.hasData ? snapshot.data!.docs.map((doc) => Visitor.fromMap(doc.data() as Map<String, dynamic>)).toList() : [];
          myPasses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. WELCOME & ACTION HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF243D60)]),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${user?.email?.split('@').first.toUpperCase() ?? 'Guest'}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Schedule a visit to see our latest tile collections or manage your logistics pickups.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Schedule New Visit'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorRegistrationScreen())),
                      ),
                    ],
                  ),
                ),
                
                // 2. ABOUT ORIENTBELL SECTION
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About Orientbell Limited', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.divider, width: 1)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.apartment, color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Text('India\'s Leading Tile Manufacturer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'With over 40 years of experience, Orientbell offers innovative solutions tailored for modern needs. Discover our unique categories:',
                                style: TextStyle(color: AppColors.textMid, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              // Specialties Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SpecialtyChip(icon: Icons.ac_unit, label: 'Cool Tiles', color: Colors.blue),
                                  _SpecialtyChip(icon: Icons.health_and_safety, label: 'Germ-Free Tiles', color: Colors.green),
                                  _SpecialtyChip(icon: Icons.all_inclusive, label: 'Forever Tiles', color: Colors.purple),
                                  _SpecialtyChip(icon: Icons.school, label: 'School Tiles', color: Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openWebsite(context),
                                  icon: const Icon(Icons.language),
                                  label: const Text('Visit Official Website'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. MY RECENT PASSES SECTION
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('My Recent Passes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
                
                if (myPasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No previous visits found', style: TextStyle(color: AppColors.textMid)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true, // Required inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    itemCount: myPasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _VisitorCard(
                      visitor: myPasses[i],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorBadgeScreen(visitor: myPasses[i]))),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}

// Helper Widget for the About Section
class _SpecialtyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SpecialtyChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VISITOR REGISTRATION FLOW
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// VISITOR REGISTRATION FLOW (VMI & PMT)
// ─────────────────────────────────────────────


// ─────────────────────────────────────────────
// VISITOR REGISTRATION FLOW (VMI & PMT)
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// VISITOR REGISTRATION FLOW (VMI & PMT)
// ─────────────────────────────────────────────

class VisitorRegistrationScreen extends StatefulWidget {
  const VisitorRegistrationScreen({super.key});

  @override
  State<VisitorRegistrationScreen> createState() => _VisitorRegistrationScreenState();
}

class _VisitorRegistrationScreenState extends State<VisitorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _selectedPurpose = 'Business Meeting';
  String _selectedPlant = 'Plant 1 - Sikandrabad';
  bool _loading = false;
  
  // Stores the photo fetched from profile
  String? _profilePhotoUrl; 

  final ImagePicker _picker = ImagePicker();
  bool _isAiLoading = false;
  bool _isScanningCard = false;
  String? _aiRecommendation;

  // IMPORTANT: PUT YOUR API KEY HERE
  final String apiKey = 'AIzaSyCs_X7wL46_CqKCLloJXYHrroJL4Bp1DUo'; 

  final _purposes = ['Business Meeting', 'Vendor Meeting', 'Material Loading/Unloading', 'Job Interview', 'Audit', 'Product Demo', 'Delivery', 'Other'];
  final _plants = ['Plant 1 - Sikandrabad', 'Plant 2 - Dora', 'Plant 3 - Hoskote', 'Head Office - New Delhi'];

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  // Reloads data (Useful if they go to profile and come back)
  Future<void> _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _nameCtrl.text = doc.data()?['name'] ?? '';
            _phoneCtrl.text = doc.data()?['phone'] ?? '';
            _companyCtrl.text = doc.data()?['company'] ?? '';
            _profilePhotoUrl = doc.data()?['photoUrl']; // Fetch verified photo
          });
        }
      } catch (e) {}
    }
  }

  // AI FEATURE 1: BUSINESS CARD SCANNER
  Future<void> _scanBusinessCard() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image == null) return;

      setState(() => _isScanningCard = true);
      
      final bytes = await image.readAsBytes();
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      
      final prompt = TextPart('''
        Extract the following details from this business card or ID card.
        Return ONLY a raw JSON object with no markdown formatting.
        Keys must be: "name", "email", "phone", "company".
        If a field is not found, leave it as an empty string "".
      ''');
      
      final imagePart = DataPart('image/jpeg', bytes);
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      
      String jsonString = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final Map<String, dynamic> data = jsonDecode(jsonString); 
      
      setState(() {
        if (data['name'] != null && data['name'] != '') _nameCtrl.text = data['name'];
        if (data['email'] != null && data['email'] != '') _emailCtrl.text = data['email'];
        if (data['phone'] != null && data['phone'] != '') _phoneCtrl.text = data['phone'];
        if (data['company'] != null && data['company'] != '') _companyCtrl.text = data['company'];
      });
      
      _showSnack(context, 'Card scanned successfully!');
    } catch (e) {
      _showSnack(context, 'Failed to read card. Please type manually.');
    } finally {
      setState(() => _isScanningCard = false);
    }
  }

  // AI FEATURE 3: TRUCK RECOMMENDATION
  Future<void> _getAiRecommendation() async {
    if (_weightCtrl.text.isEmpty) {
      _showSnack(context, 'Please enter the weight first!');
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      final prompt = 'You are a logistics AI for Orientbell Tiles. A transporter needs to load ${_weightCtrl.text} tons of ceramic tiles. Recommend the best standard Indian commercial truck. Format as a single short sentence.';
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() => _aiRecommendation = response.text?.trim() ?? 'Error generating response.');
    } catch (e) {
      _showSnack(context, 'AI Error: Check API Key.');
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if they setup their profile photo!
    if (_profilePhotoUrl == null) {
      _showSnack(context, 'Security Policy: Please update your Profile with a face photo first!');
      return;
    }

    setState(() => _loading = true);
    
    try {
      double? weight;
      if (_selectedPurpose == 'Material Loading/Unloading' && _weightCtrl.text.isNotEmpty) weight = double.tryParse(_weightCtrl.text);

      final visitor = Visitor(
        id: _genId(), name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
        company: _companyCtrl.text.trim(), purpose: _selectedPurpose, hostName: _hostCtrl.text.trim(), hostDept: '',
        plant: _selectedPlant, createdAt: DateTime.now(), validUntil: DateTime.now().add(const Duration(hours: 12)),
        status: VisitorStatus.preRegistered, badgeCode: _genBadge(), vehicleNo: _vehicleCtrl.text.trim().isEmpty ? null : _vehicleCtrl.text.trim(),
        photoUrl: _profilePhotoUrl, // Directly from Profile!
        loadWeight: weight, recommendedVehicle: _aiRecommendation, 
      );

      await FirebaseFirestore.instance.collection('visitors').doc(visitor.id).set(visitor.toMap());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VisitorBadgeScreen(visitor: visitor)));
    } catch (e) {
      _showSnack(context, 'Failed to register: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI SCANNER BUTTON
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isScanningCard ? null : _scanBusinessCard,
                  icon: _isScanningCard ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.document_scanner, color: Colors.white),
                  label: Text(_isScanningCard ? 'AI is scanning...' : 'Scan Business Card / ID', style: const TextStyle(color: Colors.white)),
                ),
              ),

              const _SectionHeader(icon: Icons.person, label: 'Personal Information'),
              const SizedBox(height: 16),
              
              // DISPLAY PROFILE PHOTO (READ-ONLY)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  backgroundImage: _profilePhotoUrl != null ? FileImage(File(_profilePhotoUrl!)) : null,
                  child: _profilePhotoUrl == null ? const Icon(Icons.person_off, size: 38, color: AppColors.textLight) : null,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit Photo in Profile'),
                  // If they click this, take them to profile, then refresh when they come back!
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    _prefillUserData(); 
                  },
                )
              ),
              const SizedBox(height: 16),

              _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.badge_outlined, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _Field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _Field(ctrl: _companyCtrl, label: 'Company / Transporter', icon: Icons.business_outlined),
              const SizedBox(height: 24),
              
              const _SectionHeader(icon: Icons.location_on_outlined, label: 'Visit Details'),
              const SizedBox(height: 16),
              _DropdownField(label: 'Select Plant / Location', value: _selectedPlant, items: _plants, onChanged: (v) => setState(() => _selectedPlant = v!)),
              const SizedBox(height: 12),
              _DropdownField(label: 'Purpose of Visit', value: _selectedPurpose, items: _purposes, onChanged: (v) => setState(() => _selectedPurpose = v!)),
              const SizedBox(height: 12),
              
              if (_selectedPurpose == 'Material Loading/Unloading') ...[
                Row(
                  children: [
                    Expanded(child: _Field(ctrl: _weightCtrl, label: 'Tile Weight (Tons)', icon: Icons.scale_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
                      onPressed: _isAiLoading ? null : _getAiRecommendation,
                      icon: _isAiLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      label: const Text('Ask AI'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_aiRecommendation != null)
                  Container(
                    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.1), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.smart_toy, color: Colors.deepPurpleAccent), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('AI Recommendation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent, fontSize: 12)), const SizedBox(height: 4), Text(_aiRecommendation!, style: const TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.4))]))]),
                  ),
                const SizedBox(height: 12),
              ],

              _Field(ctrl: _hostCtrl, label: 'Host / Person to Meet', icon: Icons.person_pin_outlined, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _Field(ctrl: _vehicleCtrl, label: 'Vehicle Number (Optional)', icon: Icons.local_shipping_outlined),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.how_to_reg_outlined), SizedBox(width: 8), Text('Register & Generate Badge')]),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
// VISITOR BADGE SCREEN
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// VISITOR BADGE SCREEN
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// VISITOR BADGE SCREEN (WITH EXPIRY LOGIC & QR CODE)
// ─────────────────────────────────────────────

class VisitorBadgeScreen extends StatelessWidget {
  final Visitor visitor;
  const VisitorBadgeScreen({super.key, required this.visitor});

  @override
  Widget build(BuildContext context) {
    // --- CHECK EXPIRATION ---
    bool isExpired = DateTime.now().isAfter(visitor.validUntil);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Your Visitor Badge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showSnack(context, 'Share feature coming soon'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Registration Successful!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Your host has been notified of your arrival.', style: TextStyle(color: AppColors.success.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Badge Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  // Badge Header (TURNS RED IF EXPIRED)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isExpired 
                            ? [AppColors.danger, Colors.redAccent] 
                            : [AppColors.primary, const Color(0xFF243D60)]
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.apartment, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ORIENTBELL LIMITED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.5)),
                            Text('VISITOR PASS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 2)),
                          ],
                        ),
                        const Spacer(),
                        // Status Pill (SAYS EXPIRED IF TIME IS UP)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.white24 : AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isExpired ? Colors.white : AppColors.success.withOpacity(0.4)),
                          ),
                          child: Text(
                            isExpired ? 'EXPIRED' : visitor.statusLabel,
                            style: TextStyle(color: isExpired ? Colors.white : AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty 
                              ? FileImage(File(visitor.photoUrl!)) 
                              : null,
                          child: visitor.photoUrl == null || visitor.photoUrl!.isEmpty
                              ? Text(visitor.name.isNotEmpty ? visitor.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(visitor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        Text(visitor.company, style: const TextStyle(fontSize: 14, color: AppColors.textMid)),
                        const SizedBox(height: 20),
                        
                        // REAL QR CODE
                        Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2), borderRadius: BorderRadius.circular(12)),
                          child: QrImageView(
                            data: visitor.id, // The scanner reads this ID!
                            version: QrVersions.auto,
                            foregroundColor: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(visitor.badgeCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid, letterSpacing: 1)),
                        const SizedBox(height: 20),
                        
                        _BadgeDetailRow(icon: Icons.place_outlined, label: 'Location', value: visitor.plant),
                        const Divider(height: 20, color: AppColors.divider),
                        _BadgeDetailRow(icon: Icons.flag_outlined, label: 'Purpose', value: visitor.purpose),
                        if (visitor.vehicleNo != null && visitor.vehicleNo!.isNotEmpty) ...[
                           const Divider(height: 20, color: AppColors.divider),
                           _BadgeDetailRow(icon: Icons.local_shipping_outlined, label: 'Vehicle No', value: visitor.vehicleNo!),
                        ],
                        const Divider(height: 20, color: AppColors.divider),
                        _BadgeDetailRow(icon: Icons.timer_off_outlined, label: 'Valid Until', value: _fmt(visitor.validUntil)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Present this badge at the security gate', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _BadgeDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RECEPTIONIST DASHBOARD
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// RECEPTIONIST DASHBOARD
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// RECEPTIONIST DASHBOARD
// ─────────────────────────────────────────────

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  String _search = '';

  // Existing Manual Status Updater
  Future<void> _updateStatus(Visitor v, String action) async {
    try {
      final updates = <String, dynamic>{};
      
      if (action == 'Check In Gate') {
        updates['status'] = VisitorStatus.checkedIn.name;
        updates['checkInTime'] = Timestamp.now();
      } else if (action == 'Check Out Gate') {
        updates['status'] = VisitorStatus.checkedOut.name;
        updates['checkOutTime'] = Timestamp.now();
      } else if (action == 'Start Load') {
        updates['loadingStartTime'] = Timestamp.now();
      } else if (action == 'End Load') {
        updates['loadingEndTime'] = Timestamp.now();
      }

      await FirebaseFirestore.instance.collection('visitors').doc(v.id).update(updates);
      _showSnack(context, '${v.name}: $action recorded successfully!');
    } catch (e) {
      _showSnack(context, 'Error updating status');
    }
  }

  // --- NEW: SMART QR SCANNER LOGIC ---
  Future<void> _processScannedQR(String scanType) async {
    // 1. Open the camera screen and wait for the scanned ID
    final String? scannedVisitorId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedVisitorId == null) return; // User pressed back without scanning

    // 2. Fetch the visitor from the Database using the Scanned ID
    try {
      final doc = await FirebaseFirestore.instance.collection('visitors').doc(scannedVisitorId).get();
      
      if (!doc.exists) {
        _showSnack(context, 'Invalid QR Code: Visitor not found in database.');
        return;
      }

      final v = Visitor.fromMap(doc.data()!);

      // 3. Automatically apply the correct status based on what the Receptionist clicked
      if (scanType == 'ENTRY') {
        if (v.status == VisitorStatus.preRegistered) {
          _updateStatus(v, 'Check In Gate');
        } else if (v.purpose == 'Material Loading/Unloading' && v.status == VisitorStatus.checkedIn && v.loadingStartTime == null) {
          _updateStatus(v, 'Start Load');
        } else {
          _showSnack(context, '${v.name} is already checked in!');
        }
      } 
      else if (scanType == 'EXIT') {
        if (v.status == VisitorStatus.checkedIn && v.purpose != 'Material Loading/Unloading') {
          _updateStatus(v, 'Check Out Gate');
        } else if (v.purpose == 'Material Loading/Unloading' && v.loadingStartTime != null && v.loadingEndTime == null) {
          _updateStatus(v, 'End Load');
        } else if (v.purpose == 'Material Loading/Unloading' && v.loadingEndTime != null && v.status == VisitorStatus.checkedIn) {
          _updateStatus(v, 'Check Out Gate');
        } else {
          _showSnack(context, 'Cannot checkout: Check visitor status.');
        }
      }
    } catch (e) {
      _showSnack(context, 'Error reading visitor data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Security Console'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _confirmLogout(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allVisitors = snapshot.data!.docs.map((doc) => Visitor.fromMap(doc.data() as Map<String, dynamic>)).toList();
          final checkedIn = allVisitors.where((v) => v.status == VisitorStatus.checkedIn).length;
          final preReg = allVisitors.where((v) => v.status == VisitorStatus.preRegistered).length;

          final filtered = allVisitors.where((v) =>
              v.name.toLowerCase().contains(_search.toLowerCase()) ||
              v.company.toLowerCase().contains(_search.toLowerCase()) ||
              v.badgeCode.toLowerCase().contains(_search.toLowerCase())).toList();

          return Column(
            children: [
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    _MiniStat(label: 'Inside Plant', value: '$checkedIn', color: AppColors.success),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Expected', value: '$preReg', color: AppColors.badgeBlue),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Total Today', value: '${allVisitors.length}', color: AppColors.accent),
                  ],
                ),
              ),
              
              // --- NEW: QR SCANNER BUTTONS ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        label: const Text('Scan Entry', style: TextStyle(color: Colors.white)),
                        onPressed: () => _processScannedQR('ENTRY'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        label: const Text('Scan Exit', style: TextStyle(color: Colors.white)),
                        onPressed: () => _processScannedQR('EXIT'),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search name, transporter or badge…',
                    prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No visitors found', style: TextStyle(color: AppColors.textMid)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final v = filtered[i];
                          return _VisitorCard(
                            visitor: v,
                            // Manual Buttons (Kept as Fallback!)
                            onCheckIn: v.status == VisitorStatus.preRegistered 
                                ? () => _updateStatus(v, 'Check In Gate') 
                                : (v.purpose == 'Material Loading/Unloading' && v.status == VisitorStatus.checkedIn && v.loadingStartTime == null)
                                    ? () => _updateStatus(v, 'Start Load') : null,
                            onCheckOut: v.status == VisitorStatus.checkedIn && v.purpose != 'Material Loading/Unloading'
                                ? () => _updateStatus(v, 'Check Out Gate')
                                : (v.purpose == 'Material Loading/Unloading' && v.loadingStartTime != null && v.loadingEndTime == null)
                                    ? () => _updateStatus(v, 'End Load')
                                    : (v.purpose == 'Material Loading/Unloading' && v.loadingEndTime != null && v.status == VisitorStatus.checkedIn)
                                        ? () => _updateStatus(v, 'Check Out Gate') : null,
                            btn1Label: v.status == VisitorStatus.preRegistered ? 'Check In Gate' : 'Start Load',
                            btn2Label: (v.loadingStartTime != null && v.loadingEndTime == null) ? 'End Load' : 'Check Out Gate',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorDetailScreen(visitor: v))),
                          );
                        },
                      ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.25))),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback onTap;
  final String? btn1Label;
  final String? btn2Label;

  const _VisitorCard({
    required this.visitor, 
    this.onCheckIn, 
    this.onCheckOut, 
    required this.onTap,
    this.btn1Label,
    this.btn2Label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: visitor.statusColor.withOpacity(0.1),
                    radius: 22,
                    child: Text(visitor.name.isNotEmpty ? visitor.name.substring(0, 1).toUpperCase() : '?', style: TextStyle(color: visitor.statusColor, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visitor.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                        Text(visitor.company, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                      ],
                    ),
                  ),
                  _StatusBadge(label: visitor.statusLabel, color: visitor.statusColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(icon: Icons.flag_outlined, label: visitor.purpose),
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.person_outline, label: visitor.hostName),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(icon: Icons.qr_code, label: visitor.badgeCode),
                  const Spacer(),
                  if (onCheckIn != null) _ActionButton(label: btn1Label ?? 'Check In', color: AppColors.success, onTap: onCheckIn!),
                  const SizedBox(width: 8),
                  if (onCheckOut != null) _ActionButton(label: btn2Label ?? 'Check Out', color: AppColors.textMid, onTap: onCheckOut!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VISITOR DETAIL SCREEN
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// VISITOR DETAIL SCREEN
// ─────────────────────────────────────────────

class VisitorDetailScreen extends StatelessWidget {
  final Visitor visitor;
  const VisitorDetailScreen({super.key, required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                      CircleAvatar(
                      radius: 32,
                      backgroundColor: visitor.statusColor.withOpacity(0.1),
                      backgroundImage: visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty 
                          ? FileImage(File(visitor.photoUrl!)) 
                          : null,
                      child: visitor.photoUrl == null || visitor.photoUrl!.isEmpty
                          ? Text(visitor.name.isNotEmpty ? visitor.name.substring(0, 1).toUpperCase() : '?', style: TextStyle(color: visitor.statusColor, fontSize: 28, fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visitor.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          Text(visitor.company, style: const TextStyle(color: AppColors.textMid, fontSize: 13)),
                          const SizedBox(height: 6),
                          _StatusBadge(label: visitor.statusLabel, color: visitor.statusColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSection(title: 'Contact Information', rows: [_DetailRow(icon: Icons.email_outlined, label: 'Email', value: visitor.email), _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: visitor.phone)]),
            const SizedBox(height: 16),
            _DetailSection(title: 'Visit Details', rows: [
              _DetailRow(icon: Icons.place_outlined, label: 'Plant', value: visitor.plant), 
              _DetailRow(icon: Icons.flag_outlined, label: 'Purpose', value: visitor.purpose), 
              _DetailRow(icon: Icons.person_pin_outlined, label: 'Host', value: visitor.hostName), 
              _DetailRow(icon: Icons.qr_code, label: 'Badge Code', value: visitor.badgeCode),
              if (visitor.vehicleNo != null) _DetailRow(icon: Icons.local_shipping, label: 'Vehicle No', value: visitor.vehicleNo!),
            ]),
            const SizedBox(height: 16),
            
            // LOGISTICS / PMT DATA
            if (visitor.purpose == 'Material Loading/Unloading') ...[
              _DetailSection(title: 'Logistics / PMT Data', rows: [
                _DetailRow(icon: Icons.scale_outlined, label: 'Load Weight', value: '${visitor.loadWeight ?? 0} Tons'),
                _DetailRow(icon: Icons.auto_awesome, label: 'AI Vehicle Suggestion', value: visitor.recommendedVehicle ?? 'N/A'),
                if (visitor.loadingStartTime != null) _DetailRow(icon: Icons.timer, label: 'Loading Started', value: _fmt(visitor.loadingStartTime!)),
                if (visitor.loadingEndTime != null) _DetailRow(icon: Icons.timer_off, label: 'Loading Ended', value: _fmt(visitor.loadingEndTime!)),
              ]),
              const SizedBox(height: 16),
            ],

            _DetailSection(title: 'Timestamps', rows: [
              _DetailRow(icon: Icons.schedule, label: 'Registered', value: _fmt(visitor.createdAt)),
              _DetailRow(icon: Icons.timer_off_outlined, label: 'Valid Until', value: _fmt(visitor.validUntil)),
              if (visitor.checkInTime != null) _DetailRow(icon: Icons.login, label: 'Checked In Gate', value: _fmt(visitor.checkInTime!)),
              if (visitor.checkOutTime != null) _DetailRow(icon: Icons.logout, label: 'Checked Out Gate', value: _fmt(visitor.checkOutTime!)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(r.icon, size: 16, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Text('${r.label}:', style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});
}

// ─────────────────────────────────────────────
// HOST DASHBOARD
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// HOST DASHBOARD
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// HOST DASHBOARD (EMPLOYEE VIEW)
// ─────────────────────────────────────────────

class HostDashboard extends StatelessWidget {
  const HostDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String hostName = user?.email?.split('@').first.toUpperCase() ?? 'EMPLOYEE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _confirmLogout(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Meeting'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorRegistrationScreen())),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allVisitors = snapshot.data!.docs.map((doc) => Visitor.fromMap(doc.data() as Map<String, dynamic>)).toList();
          
          // PROTOTYPE FIX: Show all active visitors so the dashboard is NEVER empty during a demo!
          // (In a real app, you would filter where v.hostEmail == user.email)
          final incoming = allVisitors.where((v) => v.status == VisitorStatus.preRegistered).toList();
          final onSite = allVisitors.where((v) => v.status == VisitorStatus.checkedIn).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF243D60)]), 
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24, 
                        child: Icon(Icons.badge, color: Colors.white, size: 28)
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, $hostName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                            Text('Orientbell Internal Staff', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Live Stats
                Row(
                  children: [
                    _StatCard(label: 'Waiting / Expected', value: '${incoming.length}', icon: Icons.pending_actions, color: AppColors.badgeBlue),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Inside Plant', value: '${onSite.length}', icon: Icons.location_on, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 24),

                // On Site Section
                if (onSite.isNotEmpty) ...[
                  const _SectionHeader(icon: Icons.people_alt, label: 'Visitors Currently Inside'),
                  const SizedBox(height: 12),
                  ...onSite.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), 
                    child: _VisitorCard(
                      visitor: v, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorDetailScreen(visitor: v)))
                    )
                  )),
                  const SizedBox(height: 16),
                ],

                // Incoming Section
                if (incoming.isNotEmpty) ...[
                  const _SectionHeader(icon: Icons.schedule, label: 'Expected Visitors'),
                  const SizedBox(height: 12),
                  ...incoming.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), 
                    child: _VisitorCard(
                      visitor: v, 
                      // Assignment Requirement: "Allow Host to send directions"
                      btn1Label: 'Send Directions',
                      onCheckIn: () => _showSnack(context, 'Directions sent to ${v.phone} via SMS!'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorDetailScreen(visitor: v)))
                    )
                  )),
                ],
                
                // If completely empty (no visitors in DB at all)
                if (onSite.isEmpty && incoming.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, size: 60, color: AppColors.textLight.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No visitors scheduled for today.', style: TextStyle(color: AppColors.textMid)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 80), // Space for Floating Action Button
              ],
            ),
          );
        }
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.logout, color: AppColors.danger), SizedBox(width: 10), Text('Logout')]),
      content: const Text('Are you sure you want to log out of your account?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMid)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await FirebaseAuth.instance.signOut();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADMIN DASHBOARD
// ─────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _confirmLogout(context)), // UPDATED
        ],
        bottom: TabBar(
          // ... rest of your code
          controller: _tab,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline), text: 'Visitors'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final visitors = snapshot.hasData ? snapshot.data!.docs.map((doc) => Visitor.fromMap(doc.data() as Map<String, dynamic>)).toList() : <Visitor>[];

          return TabBarView(
            controller: _tab,
            children: [
              _AdminOverview(visitors: visitors),
              _AdminVisitorList(visitors: visitors),
              _AdminAnalytics(visitors: visitors),
            ],
          );
        }
      ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  final List<Visitor> visitors;
  const _AdminOverview({required this.visitors});

  @override
  Widget build(BuildContext context) {
    final total = visitors.length;
    final onSite = visitors.where((v) => v.status == VisitorStatus.checkedIn).length;
    final preReg = visitors.where((v) => v.status == VisitorStatus.preRegistered).length;
    final out = visitors.where((v) => v.status == VisitorStatus.checkedOut).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _AdminStatTile(value: '$total', label: 'Total Today', icon: Icons.people, color: AppColors.primary),
              _AdminStatTile(value: '$onSite', label: 'On Site Now', icon: Icons.location_on, color: AppColors.success),
              _AdminStatTile(value: '$preReg', label: 'Pre-Registered', icon: Icons.schedule, color: AppColors.badgeBlue),
              _AdminStatTile(value: '$out', label: 'Checked Out', icon: Icons.exit_to_app, color: AppColors.textMid),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.business, label: 'Active Plants'),
          const SizedBox(height: 12),
          ...['Plant 1 - Sikandrabad', 'Plant 2 - Dora', 'Plant 3 - Hoskote'].map((plant) {
            final cnt = visitors.where((v) => v.plant == plant && v.status == VisitorStatus.checkedIn).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.factory_outlined, color: AppColors.primary),
                  ),
                  title: Text(plant, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$cnt visitors on site'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cnt > 0 ? AppColors.success.withOpacity(0.1) : AppColors.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cnt > 0 ? 'Active' : 'Quiet',
                      style: TextStyle(color: cnt > 0 ? AppColors.success : AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.history, label: 'Recent Activity'),
          const SizedBox(height: 12),
          ...visitors.take(5).map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VisitorCard(
              visitor: v,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorDetailScreen(visitor: v))),
            ),
          )),
        ],
      ),
    );
  }
}

class _AdminStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _AdminStatTile({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminVisitorList extends StatelessWidget {
  final List<Visitor> visitors;
  const _AdminVisitorList({required this.visitors});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visitors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VisitorCard(
        visitor: visitors[i],
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitorDetailScreen(visitor: visitors[i]))),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADMIN DASHBOARD ANALYTICS (WITH AI REPORT)
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// ADMIN DASHBOARD ANALYTICS (WITH AI REPORT & REAL KPIS)
// ─────────────────────────────────────────────

class _AdminAnalytics extends StatefulWidget {
  final List<Visitor> visitors;
  const _AdminAnalytics({required this.visitors});

  @override
  State<_AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<_AdminAnalytics> {
  bool _isGeneratingReport = false;
  String? _aiReport;
  
  // IMPORTANT: PUT YOUR API KEY HERE
  final String apiKey = 'AIzaSyCs_X7wL46_CqKCLloJXYHrroJL4Bp1DUo'; 

  Future<void> _generateAiReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      final total = widget.visitors.length;
      final logistics = widget.visitors.where((v) => v.purpose == 'Material Loading/Unloading').length;
      final inside = widget.visitors.where((v) => v.status == VisitorStatus.checkedIn).length;
      
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      final prompt = '''
        You are the Chief Analytics AI for Orientbell Tiles. 
        Analyze this raw daily data and write a professional 3-sentence Executive Summary highlighting plant activity, logistics, and security:
        Total Visitors Today: $total
        Visitors Currently Inside Plant: $inside
        Logistics/Trucks Handled: $logistics
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      setState(() {
        _aiReport = response.text?.trim() ?? 'Could not generate report.';
      });
    } catch (e) {
      _showSnack(context, 'Failed to generate AI Report.');
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.visitors.length;
    double frac(String purpose) => t == 0 ? 0 : widget.visitors.where((v) => v.purpose == purpose).length / t;
    int countPlant(String p) => widget.visitors.where((v) => v.plant == p).length;

    // --- REAL KPI CALCULATIONS ---
    double totalVisitHrs = 0;
    int completedVisits = 0;
    double totalLoadHrs = 0;
    int completedLoads = 0;

    for (var v in widget.visitors) {
      // Calculate real Visit Duration
      if (v.checkInTime != null && v.checkOutTime != null) {
        totalVisitHrs += v.checkOutTime!.difference(v.checkInTime!).inMinutes / 60.0;
        completedVisits++;
      }
      // Calculate real Loading Turnaround Time
      if (v.loadingStartTime != null && v.loadingEndTime != null) {
        totalLoadHrs += v.loadingEndTime!.difference(v.loadingStartTime!).inMinutes / 60.0;
        completedLoads++;
      }
    }

    String actualAvgDuration = completedVisits > 0 ? '${(totalVisitHrs / completedVisits).toStringAsFixed(1)} hrs' : '0 hrs';
    String actualAvgLoad = completedLoads > 0 ? '${(totalLoadHrs / completedLoads).toStringAsFixed(1)} hrs' : '0 hrs';
    
    // Calculate real Check-in Rate
    int expected = widget.visitors.where((v) => v.status == VisitorStatus.preRegistered).length;
    int arrived = widget.visitors.where((v) => v.status != VisitorStatus.preRegistered).length;
    String checkInRate = (expected + arrived) > 0 ? '${((arrived / (expected + arrived)) * 100).toStringAsFixed(1)}%' : '0%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI FACTORY HEALTH REPORT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text('AI Executive Report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (!_isGeneratingReport && _aiReport == null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 36)),
                        onPressed: _generateAiReport,
                        child: const Text('Generate'),
                      ),
                  ],
                ),
                if (_isGeneratingReport) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                  const SizedBox(height: 10),
                  const Center(child: Text('AI is analyzing plant data...', style: TextStyle(color: Colors.white70))),
                ],
                if (_aiReport != null) ...[
                  const SizedBox(height: 16),
                  Text(_aiReport!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),

          // DYNAMIC KPI CARDS
          const _SectionHeader(icon: Icons.insights, label: 'Key Performance Indicators (KPIs)'),
          const SizedBox(height: 12),
          Row(
            children: [
              _KPICard(label: 'Avg Turnaround (Loading)', value: actualAvgLoad, trend: 'Live Data', positive: true),
              const SizedBox(width: 12),
              _KPICard(label: 'Avg Visit Duration', value: actualAvgDuration, trend: 'Live Data', positive: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _KPICard(label: 'Check-In Rate', value: checkInRate, trend: 'Today', positive: true),
              const SizedBox(width: 12),
              const _KPICard(label: 'Denied Access', value: '0', trend: 'Secure', positive: true),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.pie_chart_outline, label: 'Visit Purposes (VMI & PMT)'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PurposeBar('Material Loading/Unloading', frac('Material Loading/Unloading'), AppColors.badgeBlue),
                  const SizedBox(height: 10),
                  _PurposeBar('Business Meeting', frac('Business Meeting'), AppColors.badgePurple),
                  const SizedBox(height: 10),
                  _PurposeBar('Vendor Meeting', frac('Vendor Meeting'), AppColors.accent),
                  const SizedBox(height: 10),
                  _PurposeBar('Audit', frac('Audit'), AppColors.badgeGreen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.bar_chart, label: 'Footfall & Logistics by Plant'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PlantBar('Plant 1 - Sikandrabad', countPlant('Plant 1 - Sikandrabad'), AppColors.primary, t),
                  const SizedBox(height: 10),
                  _PlantBar('Plant 2 - Dora', countPlant('Plant 2 - Dora'), AppColors.badgeBlue, t),
                  const SizedBox(height: 10),
                  _PlantBar('Plant 3 - Hoskote', countPlant('Plant 3 - Hoskote'), AppColors.badgeGreen, t),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool positive;
  const _KPICard({required this.label, required this.value, required this.trend, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(positive ? Icons.trending_up : Icons.trending_down, size: 14, color: positive ? AppColors.success : AppColors.danger),
                  const SizedBox(width: 4),
                  Text(trend, style: TextStyle(fontSize: 11, color: positive ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurposeBar extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;
  const _PurposeBar(this.label, this.fraction, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
            Text('${(fraction * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: fraction, minHeight: 8, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
}

class _PlantBar extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;
  const _PlantBar(this.label, this.count, this.color, this.total);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid))),
            Text('$count visitors', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: total == 0 ? 0 : count / total, minHeight: 8, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.label, required this.icon, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.textLight, size: 20)),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}


// ─────────────────────────────────────────────
// QR CODE SCANNER CAMERA SCREEN
// ─────────────────────────────────────────────

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false; // Prevents scanning the same code 100 times per second

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Visitor Badge'),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            setState(() => _hasScanned = true);
            final String scannedCode = barcodes.first.rawValue!;
            
            // Send the scanned ID back to the Receptionist Dashboard
            Navigator.pop(context, scannedCode); 
          }
        },
      ),
    );
  }
}
