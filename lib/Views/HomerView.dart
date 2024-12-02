import 'package:flutter/material.dart';

class HomerView extends StatefulWidget{
  @override
  State<HomerView> createState() => _HomerViewState();
}

class _HomerViewState extends State<HomerView> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                Center(child: Text("Mis Tiendas")), // Aquí puedes agregar contenido
                Center(child: Text("Todas las Tiendas")),
                Center(child: Text("Crear Tienda")),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.store), text: "Mis Tiendas"),
          Tab(icon: Icon(Icons.star), text: "Todas las Tiendas"),
          Tab(icon: Icon(Icons.create_new_folder), text: "Crear Tienda"),
        ],
      ),
    );
  }

}

