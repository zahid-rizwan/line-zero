import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

class AppEntryGate extends StatefulWidget {
  final Widget child;

  const AppEntryGate({super.key, required this.child});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(OnboardingScreen.keyHasSeenOnboarding) ?? false;
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(targetScreen: widget.child);
    }

    return widget.child;
  }
}
