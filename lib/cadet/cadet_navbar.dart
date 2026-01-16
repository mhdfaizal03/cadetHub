import 'package:flutter/material.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_dashboard.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_notification_screen.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_profile_screen.dart';
import 'package:ncc_cadet/utils/theme.dart';

class CadetNavbar extends StatefulWidget {
  const CadetNavbar({super.key});

  @override
  State<CadetNavbar> createState() => _CadetNavbarState();
}

class _CadetNavbarState extends State<CadetNavbar> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CadetDashboardScreen(),
    CadetNotificationsScreen(),
    CadetProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppTheme.gold,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.navyBlue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: AppTheme.navyBlue),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.navyBlue),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
