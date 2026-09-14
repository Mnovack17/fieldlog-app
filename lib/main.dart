import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme.dart';
import 'models/entry.dart';
import 'screens/submit_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FieldLogApp());
}

class FieldLogApp extends StatelessWidget {
  const FieldLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Log',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootGate(),
    );
  }
}

/// Signs the device in anonymously (silent, no login UI — technicians never
/// see or need a Claude/Google/Firebase account) before showing the app.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    try {
      final existing = FirebaseAuth.instance.currentUser;
      final cred = existing != null
          ? null
          : await FirebaseAuth.instance.signInAnonymously();
      if (!mounted) return;
      setState(() {
        _user = existing ?? cred?.user;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 40, color: AppColors.inkMuted),
                  const SizedBox(height: 12),
                  const Text("Couldn't connect", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _error = null;
                      _signIn();
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  final CollectionReference<Map<String, dynamic>> _entriesCol =
      FirebaseFirestore.instance.collection('entries');

  Future<void> _submitEntry(Map<String, dynamic> payload) async {
    await _entriesCol.add(payload);
  }

  @override
  Widget build(BuildContext context) {
    final entriesQuery = _entriesCol.orderBy('date', descending: true).limit(500);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: entriesQuery.snapshots(),
      builder: (context, snapshot) {
        final entries = <FieldEntry>[
          if (snapshot.hasData)
            ...snapshot.data!.docs.map(FieldEntry.fromDoc)
        ];

        final connecting = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Field Log'),
                const SizedBox(width: 10),
                if (snapshot.hasError)
                  const Tooltip(
                    message: 'Offline — showing last known data',
                    child: Icon(Icons.cloud_off, size: 18, color: AppColors.warn),
                  )
                else if (connecting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _tab,
            children: [
              SubmitScreen(entries: entries, onSubmit: _submitEntry),
              DashboardScreen(entries: entries),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: 'Submit'),
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            ],
          ),
        );
      },
    );
  }
}
