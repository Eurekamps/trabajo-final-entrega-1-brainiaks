import 'package:flutter/material.dart';
import 'package:triboo/FBObjects/FbCommunity.dart';
import 'package:triboo/Statics/DataHolder.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  late List<FbCommunity> myComunitys = DataHolder().myCommunities;

  @override
  void initState() {
    super.initState();
  }

  // Esto se tiene que cambiar cuando este creado lo de los posts
  final List<String> posts = [
    "Post 1: Welcome to Flutter!",
    "Post 2: This is a sample post.",
    "Post 3: Building UIs is fun!",
    "Post 4: Keep learning Dart!",
    "Post 5: Flutter is awesome!"
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100.0),
          child: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myComunitys.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,  // Center the items vertically
                      children: [
                        // Community Avatar (Photo)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(myComunitys[index].avatar),
                        ),
                        SizedBox(height: 4),  // Add some space between the avatar and the name
                        // Community Name
                        Text(
                          myComunitys[index].name,
                          style: TextStyle(
                            fontSize: 12,  // Adjust size as needed
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,  // In case the name is too long
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                posts[index],
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          );
        },
      ),
    );
  }
}
