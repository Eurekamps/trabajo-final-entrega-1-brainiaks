import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../FBObjects/FbCommunity.dart';
import '../Statics/DataHolder.dart';

class CommunityGridView extends StatefulWidget {
  @override
  State<CommunityGridView> createState() => _CommunityGridViewState();
}

class _CommunityGridViewState extends State<CommunityGridView> {
  final List<FbCommunity> communities = DataHolder().myCommunities;
  int? selectedGridIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Número de columnas
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1.0,
        ),
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          final isSelected = selectedGridIndex == index;

          return GestureDetector(
            onTap: () {
              // Actualiza el valor en DataHolder y selecciona el índice
              setState(() {
                selectedGridIndex = index;
              });
              DataHolder().selectedCommunity = community;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Seleccionaste: ${community.name}')),
              );
            },
            child: Card(
              color: isSelected ? Colors.blue : Colors.white, // Cambia el color si está seleccionado
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8.0),
                  Text(
                    community.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black, // Cambia el color del texto
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
