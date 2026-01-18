import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard/dashboard_screen.dart';
import 'translate/translate_screen.dart';
import 'learn/learn_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../providers/auth_provider.dart';
import '../services/time_tracking_service.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final TimeTrackingService _timeTrackingService = TimeTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeTrackingService.stopTracking();
    super.dispose();
  }

  void _startTimeTracking() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId != null) {
        _timeTrackingService.startTracking(authProvider.userId!);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background - pause tracking
        _timeTrackingService.pauseTracking();
        break;
      case AppLifecycleState.resumed:
        // App coming to foreground - resume tracking
        _timeTrackingService.resumeTracking();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          TranslateScreen(),
          LearnScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}