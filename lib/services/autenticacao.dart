import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // retorna usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // observa mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // login com email e senha
  Future<String?> login({
    required String email,
    required String senha,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return null; // obs: null=sucesso
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  // cadastro com email, senha, nome e perfil
  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String perfil,
  }) async {
    try {
      final resultado = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      // salva dados adicionais no firestore
      await _firestore
          .collection('usuarios')
          .doc(resultado.user!.uid)
          .set({
        'nome': nome.trim(),
        'email': email.trim(),
        'perfil': perfil,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  // logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // traduz códigos de erro do firebase pra português
  String _traduzirErro(String codigo) {
    switch (codigo) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'Formato de e-mail inválido.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter no mínimo 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }
}