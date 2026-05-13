import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String perfil;
  final String codigoAtleta;
  final String? modalidadePadrao;
  final bool consentimentoLGPD;
  final Map<String, dynamic> resumo;
  final DateTime criadoEm;

  Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.codigoAtleta,
    this.modalidadePadrao,
    required this.consentimentoLGPD,
    required this.resumo,
    required this.criadoEm,
  });

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      uid: uid,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      perfil: map['perfil'] ?? 'atleta',
      codigoAtleta: map['codigoAtleta'] ?? _gerarCodigo(uid),
      modalidadePadrao: map['modalidadePadrao'],
      consentimentoLGPD: map['consentimentoLGPD'] ?? false,
      resumo: Map<String, dynamic>.from(map['resumo'] ?? {
        'totalSessoes': 0,
        'taxaSudorMediaL_h': 0.0,
        'mediaVariacaoMassaPct': 0.0,
      }),
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'perfil': perfil,
      'codigoAtleta': codigoAtleta,
      'modalidadePadrao': modalidadePadrao,
      'consentimentoLGPD': consentimentoLGPD,
      'resumo': resumo,
      'criadoEm': criadoEm,
    };
  }

  static String _gerarCodigo(String uid) {
    return 'ATL-${uid.substring(0, 6).toUpperCase()}';
  }
}