import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusVinculo {
  ativo,
  encerrado,
}

class Vinculo {
  final String? id;
  final String atletaUid;
  final String codigoAtleta;
  final String nomeAtleta;
  final String profissionalUid;
  final String nomeProfissional;
  final String perfilProfissional;
  final StatusVinculo status;
  final DateTime criadoEm;
  final DateTime? encerradoEm;

  const Vinculo({
    this.id,
    required this.atletaUid,
    required this.codigoAtleta,
    required this.nomeAtleta,
    required this.profissionalUid,
    required this.nomeProfissional,
    required this.perfilProfissional,
    required this.status,
    required this.criadoEm,
    this.encerradoEm,
  });

  Map<String, dynamic> toMap() => {
        'atletaUid': atletaUid,
        'codigoAtleta': codigoAtleta,
        'nomeAtleta': nomeAtleta,
        'profissionalUid': profissionalUid,
        'nomeProfissional': nomeProfissional,
        'perfilProfissional': perfilProfissional,
        'status': status.name,
        'criadoEm': Timestamp.fromDate(criadoEm),
        'encerradoEm':
            encerradoEm != null ? Timestamp.fromDate(encerradoEm!) : null,
      };

  factory Vinculo.fromMap(Map<String, dynamic> map, String docId) => Vinculo(
        id: docId,
        atletaUid: map['atletaUid'] as String,
        codigoAtleta: map['codigoAtleta'] as String,
        nomeAtleta: map['nomeAtleta'] as String,
        profissionalUid: map['profissionalUid'] as String,
        nomeProfissional: map['nomeProfissional'] as String,
        perfilProfissional: map['perfilProfissional'] as String,
        status: StatusVinculo.values.byName(map['status']),
        criadoEm: (map['criadoEm'] as Timestamp).toDate(),
        encerradoEm: map['encerradoEm'] != null
            ? (map['encerradoEm'] as Timestamp).toDate()
            : null,
      );
}