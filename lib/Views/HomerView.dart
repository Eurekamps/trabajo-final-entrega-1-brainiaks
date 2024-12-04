import 'package:flutter/material.dart';
import 'package:triboo/Views/Customs/CustomDrawer.dart';
import 'package:triboo/Views/LoginView.dart';

import 'HomeView.dart';

class HomerView extends StatefulWidget {
  @override
  State<HomerView> createState() => _HomerViewState();
}

class _HomerViewState extends State<HomerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Widget _farLeftScreen = LoginView();
  final Widget _centerLeftScreen = HomeView();
  final Widget _trueCenterScreen = HomeView();
  final Widget _centerRightScreen = HomeView();
  final Widget _farRightScreen = HomeView();



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Triboo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Center(child: _farLeftScreen),
                Center(child: _centerLeftScreen),
                Center(child: _trueCenterScreen),
                Center(child: _centerRightScreen),
                Center(child: _farRightScreen),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[900],
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(), // Remove default indicator
          tabs: [
            Tab(icon: _tabController.index == 0 ? Icon(Icons.home, size: 32, color: Colors.white) : Icon(Icons.home_outlined, color: Colors.white60)),
            Tab(icon: _tabController.index == 1 ? Icon(Icons.search, size: 32, color: Colors.white) : Icon(Icons.search_outlined, color: Colors.white60)),
            Tab(icon: _tabController.index == 2 ? Icon(Icons.local_fire_department, size: 32, color: Colors.white) : Icon(Icons.local_fire_department_outlined, color: Colors.white60)),
            Tab(icon: _tabController.index == 3 ? Icon(Icons.create_new_folder, size: 32, color: Colors.white) : Icon(Icons.create_new_folder_outlined, color: Colors.white60)),
            Tab(icon: _tabController.index == 4 ? Icon(Icons.person, size: 32, color: Colors.white) : Icon(Icons.person_outlined,color: Colors.white60)),
          ],
        ),
      ),
    );
  }

}

