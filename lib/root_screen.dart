import 'package:flutter/material.dart';
import 'package:rubberball/screens/home_screen.dart';
import 'package:rubberball/screens/match_screen.dart';
import 'package:rubberball/screens/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  // Use 'late' sparingly; initializing immediately is often safer for simple lists
  final List<Widget> _screens = [
    const MatchScreen(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  int _currentIndex = 1;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Smooth animation for a modern feel
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend body behind nav bar if you want transparency,
      // but standard is usually false for this layout.
      body: PageView(
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to force nav bar usage
        controller: _controller,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // Add a subtle border on top to separate from content like a pitch boundary
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          // Animation duration for the indicator pill
          animationDuration: const Duration(milliseconds: 600),
          // Destinations using icons that fit the sport theme
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.sports_cricket_outlined),
              selectedIcon: Icon(Icons.sports_cricket),
              label: 'Matches',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.stadium), // Stadium icon for Home
              label: 'Home',
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