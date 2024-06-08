import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'video_feed_screen.dart';
import 'user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Sharing App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/feed': (context) => const VideoFeedScreen(),
      },
    );
  }
}

//FirebaseAuthService
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Define _auth

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // After successful login, fetch or create user profile
      UserProfile? userProfile = await getUserProfile(userCredential.user!.uid);
      if (userProfile == null) {
        // If no profile exists, create one
        userProfile = UserProfile(
          uid: userCredential.user!.uid,
          email: email,
          username: 'new_user', // You can prompt the user to set a username later
        );
        await createOrUpdateUserProfile(userProfile);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors (e.g., invalid email, wrong password)
      return null;
    }
  }

  // Create or update user profile in Firestore
  Future<void> createOrUpdateUserProfile(UserProfile userProfile) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProfile.uid)
          .set(userProfile.toJson());
    } catch (e) {
      // Handle errors
      print('Error updating user profile: $e');
    }
  }

  // Fetch user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot snapshot = // Use the imported DocumentSnapshot
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return UserProfile.fromJson(snapshot.data() as Map<String, dynamic>);
      }
    } catch (e) {
      // Handle errors
      print('Error fetching user profile: $e');
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

// ... (Other authentication methods: register, etc.)
}


// ImagePickerService
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    return video;
  }

// ... (Other methods for picking or recording videos)
}
// Add SplashScreen widget
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    await Future.delayed(const Duration(seconds: 2)); // Simulated delay
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/feed');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

