import 'package:flutter/material.dart';

import 'HomeView.dart';

class HomerView extends StatefulWidget{
  @override
  State<HomerView> createState() => _HomerViewState();
}

class _HomerViewState extends State<HomerView> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final Widget _farRightScreen = HomeView();  //He puesto El HomeView como place holder cuando queramos cambiar alguna pantalla se cambia aqui.
  final Widget _centerRightScreen = HomeView();
  final Widget _trueCenterScreen = HomeView();
  final Widget _centerLeftScreen = HomeView();
  final Widget _farLeftScreen = HomeView();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Center(child: _farRightScreen), // Aquí puedes agregar contenido
                Center(child: _centerRightScreen),
                Center(child: _trueCenterScreen),
                Center(child: _centerLeftScreen),
                Center(child: _farLeftScreen),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.home)),
          Tab(icon: Icon(Icons.search)),
          Tab(icon: Icon(Icons.local_fire_department)),
          Tab(icon: Icon(Icons.create_new_folder)),
          Tab(icon: Icon(Icons.person)),
        ],
      ),
    );
  }

}

