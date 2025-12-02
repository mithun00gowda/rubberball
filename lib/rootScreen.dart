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
  late List<Widget> screens = [];
  int cureentIndex = 1;
  late PageController controller;

  @override
  void initState() {
    screens = [
      MatchScreen(),
      HomeScreen(),
      ProfileScreen()
    ];
    controller = PageController(initialPage: cureentIndex);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
          selectedIndex: cureentIndex,
          height: kBottomNavigationBarHeight,
          elevation: 10,
          onDestinationSelected: (index){
            setState(() {
              cureentIndex = index;
            });
            controller.jumpToPage(cureentIndex);
          },
          destinations: [
        NavigationDestination(icon: Icon(Icons.sports_cricket_outlined), label: 'Matches'),
        NavigationDestination(icon: Icon(Icons.sports), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile')
      ]),
    );
  }
}
