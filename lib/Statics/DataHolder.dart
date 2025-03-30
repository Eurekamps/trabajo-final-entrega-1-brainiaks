import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triboo/Statics/FirebaseAdmin.dart';


import '../FBObjects/FbCommunity.dart';
import '../FBObjects/FbPerfil.dart';
import '../FBObjects/FBPost.dart';

class DataHolder {
  static final DataHolder _dataHolder = DataHolder._internal();

  // Lista de comunidades
  List<FbCommunity> _allCommunities = [];
  List<FbCommunity> _createdCommunities = [];
  List<FbCommunity> _joinedCommunities = [];

  late FbCommunity selectedCommunity;


  FbPerfil? userProfile;
  FirebaseAdmin fbAdmin = FirebaseAdmin();
  Uint8List? tempProfileImage;

  // Constructor privado
  DataHolder._internal();

  // Factory constructor para obtener la única instancia de DataHolder
  factory DataHolder() {
    return _dataHolder;
  }
  void clearTempData() {
    tempProfileImage = null;
  }
  // Método para obtener el perfil de usuario desde Firestore
 /* Future<bool> getUserProfile(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        userProfile = FbPerfil.fromFirestore(snapshot, null);
        print("Perfil cargado: ${userProfile.toString()}");
        return true;
      } else {
        print("Perfil de usuario no encontrado en Firestore.");
        userProfile = null;
        return false;
      }
    } catch (e) {
      print("Error al obtener el perfil: $e");
      userProfile = null;
      return false;
    }
  }*/

  // Método para guardar el perfil del usuario y usar un callback para manejar el error
  Future<void> saveUserProfile(FbPerfil perfil, String s,
      Function(String) onError) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(perfil.toFirestore());
      }
    } catch (e) {
      onError('Error al guardar el perfil: $e');
    }
  }

/*
  // Gestión de publicaciones (FBPost)

  // Guardar una publicación en Firebase (Diego)
  Future<void> savePost(FBPost post, Function(String) onError) async {
    try {
      await FirebaseFirestore.instance.collection('posts').add(post.toFirestore());
    } catch (e) {
      onError('Error al guardar la publicación: $e');
    }
  }

  // Sincronizar publicaciones desde Firebase (Diego)
  Future<List<FBPost>> fetchPosts() async {
    try {
      final snapshots = await FirebaseFirestore.instance.collection('posts').get();
      return snapshots.docs.map((doc) => FBPost.fromFirestore(doc, null)).toList();
    } catch (e) {
      print('Error al sincronizar publicaciones: $e');
      return [];
    }
  }*/

  // Obtener todas las comunidades
  List<FbCommunity> get allCommunities => _allCommunities;

  List<FbCommunity> get createdCommunities => _createdCommunities;

  List<FbCommunity> get joinedCommunities => _joinedCommunities;

  List<FbCommunity> get myCommunities {
    List<FbCommunity> combined = [];
    combined.addAll(_joinedCommunities);
    combined.addAll(_createdCommunities);
    return combined;
  }

  // Actualizar las comunidades
  void setCommunities(List<FbCommunity> communities) {
    _allCommunities = communities;
    _createdCommunities = communities.where((c) => c.uidCreator ==
        FirebaseAuth.instance.currentUser?.uid).toList();
    _joinedCommunities = communities.where((c) =>
        c.uidParticipants.contains(FirebaseAuth.instance.currentUser?.uid))
        .toList();
  }

  // Agregar una nueva comunidad
  void addCommunity(FbCommunity community) {
    _allCommunities.add(community);
    if (community.uidCreator == FirebaseAuth.instance.currentUser?.uid) {
      _createdCommunities.add(community);
    }
    if (community.uidParticipants.contains(
        FirebaseAuth.instance.currentUser?.uid)) {
      _joinedCommunities.add(community);
    }
  }

  // Eliminar una comunidad
  void removeCommunity(String communityId) {
    _allCommunities.removeWhere((c) => c.id == communityId);
    _createdCommunities.removeWhere((c) => c.id == communityId);
    _joinedCommunities.removeWhere((c) => c.id == communityId);
  }
// Actualiza en local
  void updateCommunity(FbCommunity updatedCommunity) {
    final index = allCommunities.indexWhere((community) => community.id == updatedCommunity.id);
    if (index != -1) {
      allCommunities[index] = updatedCommunity;
    }

    final createdIndex = createdCommunities.indexWhere((community) => community.id == updatedCommunity.id);
    if (createdIndex != -1) {
      createdCommunities[createdIndex] = updatedCommunity;
    }

    final joinedIndex = joinedCommunities.indexWhere((community) => community.id == updatedCommunity.id);
    if (joinedIndex != -1) {
      joinedCommunities[joinedIndex] = updatedCommunity;
    }
  }

  // Sincronizar comunidades desde Firebase
  Future<void> syncCommunitiesFromFirebase() async {
    final snapshots = await fbAdmin.fetchFBDataList(collectionPath: 'comunidades');
    if (snapshots != null) {
      final communities = snapshots.map((doc) => FbCommunity.fromFirestore(doc)).toList();
      setCommunities(communities);
    }
  }
}