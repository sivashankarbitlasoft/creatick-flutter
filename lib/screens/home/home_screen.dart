import 'package:flutter/material.dart';

import 'create_ticket_tab.dart';
import 'dashboard_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  static const _titles = ['Dashboard', 'Create Ticket', 'My Profile'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(onProfileTap: () => _goToTab(2)),
      const CreateTicketTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(title: Text(_titles[_currentIndex])),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
