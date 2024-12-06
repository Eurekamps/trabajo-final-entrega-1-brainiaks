import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Statics/Products.dart';
import 'Customs/CustomButtonSanti.dart';
import 'Customs/CustomDrawer.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() {
    return _HomeView();
  }
}

class _HomeView extends State<HomeView> {
  int _selectedIndex = 0;

  // Lista para almacenar los productos
  List<Products> _products = [];

  // Variable para alternar entre vista en lista o en celdas
  bool isGridView = false;

  // Cambiar el índice seleccionado
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Función para agregar productos a la lista
  void _addProduct(Products product) {
    setState(() {
      _products.add(product);
    });
  }

  // Función para obtener productos desde Firestore
  void _getProducts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('productos')
            .orderBy('createdAt', descending: true)
            .get();

        List<Products> fetchedProducts = snapshot.docs.map((doc) {
          return Products(
            name: doc['name'],
            price: doc['price'],
            store: doc['store'],
          );
        }).toList();

        setState(() {
          _products = fetchedProducts;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los productos')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
          "INVENTARIO",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomButtonSanti(
              icon: Icons.upload,
              label: "Tienda",
              onPressed: () {
              },
              backgroundColor: Color(0xFF00C4FF),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: 12.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child:CustomButtonSanti(
              icon: Icons.upload,
              label: "Clima",
              onPressed: () {

              },
              backgroundColor: Color(0xFF00C4FF),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: 12.0,
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Alternar entre vista en lista o en celdas
              isGridView
                  ? GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columnas en la cuadrícula
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.blueGrey[800],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          Text(
                            _products[index].name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Precio: ${_products[index].price} - Tienda: ${_products[index].store}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _products[index].name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Precio: ${_products[index].price} - Tienda: ${_products[index].store}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    leading: const Icon(Icons.shopping_cart, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Cambiar entre vista en lista y vista en celdas
            isGridView = !isGridView;
          });
        },
        backgroundColor: Colors.lightBlueAccent,
        child: Icon(isGridView ? Icons.view_list : Icons.grid_view),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueGrey[800],
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.blueGrey[900],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}