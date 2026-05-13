import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // le o documento do usuário uma vez
  Future<Usuario?> buscarUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (!doc.exists) return null;
      return Usuario.fromMap(uid, doc.data()!);
    } catch (e) {
      print("ERRO ao buscar usuário: $e");
      return null;
    }
  }

  // stream em tempo real
  Stream<Usuario?> streamUsuario(String uid) {
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Usuario.fromMap(uid, doc.data()!) : null);
  }

  // atualiza campos específicos sem sobrescrever o documento todo
  Future<void> atualizarUsuario(String uid, Map<String, dynamic> campos) async {
    await _firestore.collection('usuarios').doc(uid).update(campos);
  }
}