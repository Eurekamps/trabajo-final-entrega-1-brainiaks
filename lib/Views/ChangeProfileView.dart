import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:triboo/FBObjects/FbPerfil.dart';
import 'dart:io';

import '../Statics/DataHolder.dart';
import '../Theme/AppColors.dart';
import 'HomeView.dart';
import 'HomerView.dart';
import 'LoadingView.dart';

class ChangeProfileView extends StatefulWidget {
  @override
  State<ChangeProfileView> createState() => _ChangeProfileViewState();
}

class _ChangeProfileViewState extends State<ChangeProfileView> {
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
    if (tecName.text.isEmpty || tecNickname.text.isEmpty || selectedBirthday == null) {
      setState(() {
        errorMessage = 'Por favor, complete todos los campos.';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoadingView()),
    );

    String? imageUrl;
    if (profileImage != null) {
      imageUrl = await uploadImage(profileImage!);
      if (imageUrl == null) {
        Navigator.pop(context);
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

      await DataHolder().saveUserProfile(perfil, uid!, handleError,);

      Navigator.pop(context);
      Navigator.popAndPushNamed(context, "/HomeView");
    } catch (e) {
      Navigator.pop(context);
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: theme.iconTheme,
        title: Text(
          "",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          double horizontalPadding = maxWidth > 600 ? 64 : 32;
          double avatarRadius = maxWidth > 600 ? 80 : 50;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      "Editar Perfil",
                      style: TextStyle(
                        fontSize: maxWidth > 600 ? 36 : 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(height: maxWidth > 600 ? 30 : 20),
                    GestureDetector(
                      onTap: selectImage,
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: kIsWeb
                            ? (_imageBytes != null ? MemoryImage(_imageBytes!) : null)
                            : (profileImage != null ? FileImage(File(profileImage!.path)) : null),
                        backgroundColor: colorScheme.surface,
                        child: (profileImage == null && _imageBytes == null)
                            ? Icon(
                          Icons.add_a_photo,
                          color: colorScheme.onSurface.withOpacity(0.5),
                          size: avatarRadius * 0.6,
                        )
                            : null,
                      ),
                    ),
                    SizedBox(height: maxWidth > 600 ? 24 : 16),
                    // Aquí aplica el estilo igual
                    _buildTextField(
                      context,
                      controller: tecNickname,
                      label: 'Apodo',
                      icon: Icons.person,
                    ),
                    SizedBox(height: maxWidth > 600 ? 24 : 16),
                    _buildTextField(
                      context,
                      controller: tecName,
                      label: 'Nombre',
                      icon: Icons.person,
                    ),
                    SizedBox(height: maxWidth > 600 ? 24 : 16),
                    GestureDetector(
                      onTap: () => selectBirthday(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          context,
                          controller: TextEditingController(
                            text: selectedBirthday != null
                                ? "${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}"
                                : '',
                          ),
                          label: 'Cumpleaños',
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: maxWidth > 600 ? 40 : 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _gradientButton(
                            "Guardar Perfil",
                            FontAwesomeIcons.userEdit,
                                () async {
                              await uploadProfileData();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomerView()),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _gradientButton("Limpiar", Icons.clear, clearFields),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

// Reutiliza exactamente como el ejemplo que diste
  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required IconData icon,
        bool isPassword = false,
        bool obscure = false,
        bool visible = false,
        VoidCallback? toggleVisibility,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.all(6),
          child: Icon(icon, color: colorScheme.primary),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
      ),
      style: TextStyle(color: colorScheme.onSurface),
    );
  }

  Widget _gradientButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


}