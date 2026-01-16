import 'package:flutter/material.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_notification_screen.dart';
import 'package:ncc_cadet/officer/officer_dashboard.dart';
import 'package:ncc_cadet/officer/officer_profile.dart';
import 'package:ncc_cadet/utils/theme.dart';

class OfficerNavBar extends StatefulWidget {
  const OfficerNavBar({super.key});

  @override
  State<OfficerNavBar> createState() => _OfficerNavBarState();
}

class _OfficerNavBarState extends State<OfficerNavBar> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    OfficerDashboardScreen(),
    CadetNotificationsScreen(), // Reusing Cadet Screen or should be officer specific? Using existing import logic for now.
    OfficerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppTheme.navyBlue,
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.grey);
          }),
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
