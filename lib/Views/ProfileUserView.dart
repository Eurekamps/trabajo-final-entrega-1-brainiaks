import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../FBObjects/FbPerfil.dart';
import '../Statics/DataHolder.dart';
import 'LoadingView.dart';


class ProfileUserView extends StatefulWidget {
  @override
  State<ProfileUserView> createState() => _ProfileUserViewState();
}

class _ProfileUserViewState extends State<ProfileUserView> {
  TextEditingController tecName = TextEditingController();
  TextEditingController tecNickname = TextEditingController();
  String errorMessage = '';
  File? profileImage;
  final ImagePicker picker = ImagePicker();
  DateTime? selectedBirthday;

  // Método para manejar los errores y actualizar el estado
  void handleError(String error) {
    setState(() {
      errorMessage = error;
    });
  }

  Future<void> selectImage() async {
    final pickedFile = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Seleccionar Imagen"),
          content: Text("¿Quieres tomar una foto o seleccionar de la galería?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: Text("Tomar Foto"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: Text("Seleccionar de la Galería"),
            ),
          ],
        );
      },
    );

    if (pickedFile != null) {
      final XFile? file = await picker.pickImage(source: pickedFile);
      if (file != null) {
        setState(() {
          profileImage = File(file.path);
        });
      }
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('imagenes/usuarios/${FirebaseAuth.instance.currentUser?.uid}/avatar.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      setState(() {
        errorMessage = 'Error al subir la imagen: $e';
      });
      return null;
    }
  }

  Future<void> uploadProfileData() async {
    if (tecName.text.isEmpty || tecNickname.text.isEmpty || selectedBirthday == null) {
      setState(() {
        errorMessage = 'Por favor, complete todos los campos.';
      });
      return;
    }

    // Navegar a la pantalla de carga
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoadingView()),
    );

    String? imageUrl;
    if (profileImage != null) {
      imageUrl = await uploadImage(profileImage!);
      if (imageUrl == null) {
        Navigator.pop(context); // Cierra la pantalla de carga
        setState(() {
          errorMessage = 'Error al subir la imagen.';
        });
        return;
      }
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final perfil = FbPerfil(
        nombre: tecName.text,
        apodo: tecNickname.text,
        imagenURL: imageUrl ?? '',
        cumple: "${selectedBirthday?.day}-${selectedBirthday?.month}-${selectedBirthday?.year}",
      );

      // Guarda el perfil en Firestore a través de DataHolder
      await DataHolder().saveUserProfile(perfil, uid!, handleError);

      // Cierra la pantalla de carga y navega a la vista de inicio
      Navigator.pop(context);
      Navigator.popAndPushNamed(context, "/HomeView");
    } catch (e) {
      Navigator.pop(context); // Cierra la pantalla de carga
      setState(() {
        errorMessage = 'Error al subir los datos del perfil.';
      });
    }
  }

  void clearFields() {
    tecName.clear();
    tecNickname.clear();
    selectedBirthday = null;
    profileImage = null;
    setState(() {
      errorMessage = '';
    });
  }

  Future<void> selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedBirthday) {
      setState(() {
        selectedBirthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          "Perfil de Usuario",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Crear Perfil",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: selectImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                  backgroundColor: Colors.white10,
                  child: profileImage == null ? Icon(Icons.add_a_photo, color: Colors.white70) : null,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tecNickname,
                decoration: InputDecoration(
                  labelText: 'Apodo',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  prefixIcon: Icon(Icons.person, color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tecName,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  prefixIcon: Icon(Icons.person, color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => selectBirthday(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Cumpleaños',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white10,
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                    ),
                    style: TextStyle(color: Colors.white),
                    controller: TextEditingController(
                      text: selectedBirthday != null
                          ? "${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}"
                          : '',
                    ),
                  ),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: FaIcon(FontAwesomeIcons.userEdit),
                    label: Text("Guardar Perfil"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: uploadProfileData,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.clear),
                    label: Text("Limpiar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: clearFields,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
