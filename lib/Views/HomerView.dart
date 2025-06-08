import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triboo/Statics/FirebaseAdmin.dart';
import 'package:triboo/Views/CommunitySearchView.dart';
import 'package:triboo/Views/CommunityView.dart';
import 'package:triboo/Views/Customs/CustomDrawer.dart';
import 'package:triboo/Views/LoginView.dart';
import 'package:triboo/Views/MiPerfilView.dart';
import 'package:triboo/Views/NotificacionesView.dart';


import '../Statics/DataHolder.dart';
import 'ChatsListScreenView.dart';
import 'CommunityGridView.dart';
import 'HomeView.dart';

class HomerView extends StatefulWidget {
  @override
  State<HomerView> createState() => _HomerViewState();
}

class _HomerViewState extends State<HomerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;

  final Widget _farLeftScreen = HomeView();
  final Widget _centerLeftScreen = CommunitySearchView();
  final Widget _trueCenterScreen = CommunityView();
  final Widget _centerRightScreen = NotificacionesView();
  final Widget _farRightScreen = MiPerfilView();



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sincronizar las comunidades desde Firebase al DataHolder
      await DataHolder().syncCommunitiesFromFirebase();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar las comunidades: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Triboo',
                style: TextStyle(color: theme.appBarTheme.foregroundColor),
              ),
            ),
            IconButton(
              icon:  Icon(Icons.chat_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: false, // por defecto
                      builder: (_) => Scaffold(
                        body: ChatListScreenView(),
                      ),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Center(child: _isLoading ? const CircularProgressIndicator() : _farLeftScreen),
                Center(child: _isLoading ? const CircularProgressIndicator() : _centerLeftScreen),
                Center(child: _isLoading ? const CircularProgressIndicator() : _trueCenterScreen),
                Center(child: _isLoading ? const CircularProgressIndicator() : _centerRightScreen),
                Center(child: _isLoading ? const CircularProgressIndicator() : _farRightScreen),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: theme.appBarTheme.backgroundColor,
        child: TabBar(
          controller: _tabController,
          indicator: const BoxDecoration(), // Sin indicador por defecto
          tabs: [
            Tab(icon: Icon(
              _tabController.index == 0 ? Icons.home : Icons.home_outlined,
              size: 32,
              color: _tabController.index == 0
                  ? theme.iconTheme.color
                  : theme.iconTheme.color?.withOpacity(0.6),
            )),
            Tab(icon: Icon(
              _tabController.index == 1 ? Icons.search : Icons.search_outlined,
              size: 32,
              color: _tabController.index == 1
                  ? theme.iconTheme.color
                  : theme.iconTheme.color?.withOpacity(0.6),
            )),
            Tab(icon: Icon(
              _tabController.index == 2 ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              size: 32,
              color: _tabController.index == 2
                  ? theme.iconTheme.color
                  : theme.iconTheme.color?.withOpacity(0.6),
            )),
            Tab(icon: Icon(
              _tabController.index == 3 ? Icons.notification_important_rounded : Icons.notification_important_outlined,
              size: 32,
              color: _tabController.index == 3
                  ? theme.iconTheme.color
                  : theme.iconTheme.color?.withOpacity(0.6),
            )),
            Tab(icon: Icon(
              _tabController.index == 4 ? Icons.person : Icons.person_outlined,
              size: 32,
              color: _tabController.index == 4
                  ? theme.iconTheme.color
                  : theme.iconTheme.color?.withOpacity(0.6),
            )),
          ],
        ),
      ),
    );
  }


}

