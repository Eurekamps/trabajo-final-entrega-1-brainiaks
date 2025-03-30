import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
  XFile? profileImage;
  final ImagePicker picker = ImagePicker();
  DateTime? selectedBirthday;
  Uint8List? _imageBytes;

  void handleError(String error) {
    setState(() {
      errorMessage = error;
    });
  }

  Future<void> selectImage() async {
    try {
      final ImageSource? pickedSource = await showDialog<ImageSource>(
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

      if (pickedSource != null) {
        final XFile? file = await picker.pickImage(source: pickedSource);
        if (file != null) {
          final bytes = await file.readAsBytes();
          setState(() {
            profileImage = file;
            _imageBytes = bytes;
          });
          print('Imagen cargada desde ${pickedSource == ImageSource.camera ? 'la cámara' : 'la galería'}');
        } else {
          print('No se pudo obtener la imagen seleccionada');
        }
      } else {
        print('No se seleccionó ninguna opción');
      }
    } catch (e) {
      print('Error al seleccionar la imagen: $e');
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      if (kIsWeb) {
        final Uint8List imageBytes = await image.readAsBytes();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('imagenes/usuarios/${FirebaseAuth.instance.currentUser?.uid}/avatar.jpg');
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        await storageRef.putData(imageBytes, metadata);
        String downloadUrl = await storageRef.getDownloadURL();

        print('URL de la imagen subida en la web: $downloadUrl');
        return downloadUrl;
      } else {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('imagenes/usuarios/${FirebaseAuth.instance.currentUser?.uid}/avatar.jpg');
        final file = File(image.path);
        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();

        print('URL de la imagen subida en dispositivo móvil: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      print("Error uploading image: $e");
      setState(() {
        errorMessage = 'Error al subir la imagen: $e';
      });
      return null;
    }
  }

  Future<void> uploadProfileData() async {
    // Validación de campos
    if (tecName.text.isEmpty || tecNickname.text.isEmpty || selectedBirthday == null) {
      setState(() => errorMessage = 'Complete todos los campos');
      return;
    }

    // Mostrar loading
    final loadingContext = Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => LoadingView())
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Subir imagen si existe
      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await uploadImage(profileImage!);
        if (imageUrl == null) throw Exception('Error al subir imagen');
      }

      // 2. Crear objeto perfil
      final perfil = FbPerfil(
        nombre: tecName.text,
        apodo: tecNickname.text,
        imagenURL: imageUrl ?? '',
        cumple: "${selectedBirthday!.day}-${selectedBirthday!.month}-${selectedBirthday!.year}",
      );

      // 3. Guardar en Firestore (con confirmación explícita)
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.set(perfil.toFirestore());

      // 4. Esperar y confirmar que el perfil se guardó correctamente
      final confirmedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!confirmedDoc.exists) {
        throw Exception('El perfil no se guardó correctamente');
      }

      // 5. Actualizar DataHolder con los datos confirmados
      DataHolder().userProfile = FbPerfil.fromFirestore(confirmedDoc, null);

      // 6. Navegación segura con limpieza completa del stack
      Navigator.of(loadingContext as BuildContext).pop();
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/HomeView',
              (Route<dynamic> route) => false
      );

      // Debug: Verificar en consola
      print('Perfil guardado y confirmado para UID: ${user.uid}');
      print('Datos confirmados: ${confirmedDoc.data()}');

    } on TimeoutException {
      Navigator.of(loadingContext as BuildContext).pop();
      setState(() => errorMessage = 'Tiempo de espera agotado. Verifica tu conexión');
    } catch (e) {
      Navigator.of(loadingContext as BuildContext).pop();
      setState(() => errorMessage = 'Error: ${e.toString()}');
      print('Error completo al guardar perfil: ${e.toString()}');
      debugPrintStack(stackTrace: e is Error ? e.stackTrace : null);
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
                  backgroundImage: kIsWeb
                      ? (_imageBytes != null ? MemoryImage(_imageBytes!) : null)
                      : (profileImage != null ? FileImage(File(profileImage!.path)) : null),
                  backgroundColor: Colors.white10,
                  child: (profileImage == null && _imageBytes == null)
                      ? Icon(Icons.add_a_photo, color: Colors.white70)
                      : null,
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