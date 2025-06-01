import 'package:cloud_firestore/cloud_firestore.dart';

class FbMensaje {
  String texto;
  String autorId;
  Timestamp fecha;
  bool visto;
  bool gustado;

  FbMensaje({
    required this.texto,
    required this.autorId,
    required this.fecha,
    required this.visto,
    required this.gustado,
  });

  factory FbMensaje.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return FbMensaje(
      texto: data['texto'],
      autorId: data['autorId'],
      fecha: data['fecha'],
      visto: data['visto'],
      gustado: data['gustado'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'autorId': autorId,
      'fecha': fecha,
      'visto': visto,
      'gustado': gustado,
    };
  }
}