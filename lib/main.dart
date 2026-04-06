import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// This handles notifications when the app is in the BACKGROUND
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Lab 6',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _deviceToken = "Fetching token...";
  String _lastMessage = "No notification received yet.";

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("Permission status: ${settings.authorizationStatus}");

    // 2. Get device token
    String? token = await messaging.getToken();
    print("FCM Token: $token");
    setState(() {
      _deviceToken = token ?? "Could not get token";
    });

    // 3. Handle notification when app is OPEN (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message: ${message.notification?.title}");

      setState(() {
        _lastMessage =
            "${message.notification?.title ?? ''}: ${message.notification?.body ?? ''}";
      });

      // Show a popup dialog
      _showNotificationDialog(
        message.notification?.title ?? "Notification",
        message.notification?.body ?? "",
      );
    });

    // 4. Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _lastMessage =
            "(Opened from background) ${message.notification?.title ?? ''}: ${message.notification?.body ?? ''}";
      });
    });
  }

  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FCM Push Notifications"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📱 Device Token:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SelectableText(
              _deviceToken,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 40),
            const Text("🔔 Last Received Notification:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _lastMessage,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}