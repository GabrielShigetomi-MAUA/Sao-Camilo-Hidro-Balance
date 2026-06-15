import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vinculo.dart';
import '../models/sessao.dart';
import '../models/usuario.dart';

class VinculoService {
  final FirebaseFirestore _db;

  VinculoService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vinculos =>
      _db.collection('vinculos');

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  // criação de vínculo:
  // busca um atleta pelo código e cria o vínculo com o profissional
  Future<Vinculo> vincularPorCodigo({
    required String codigoAtleta,
    required Usuario profissional,
  }) async {
    // buscar atleta pelo código
    final query = await _usuarios
        .where('codigoAtleta', isEqualTo: codigoAtleta.toUpperCase().trim())
        .where('perfil', isEqualTo: 'atleta')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw ArgumentError(
          'Nenhum atleta encontrado com o código "$codigoAtleta".');
    }

    final atletaDoc = query.docs.first;
    final atletaUid = atletaDoc.id;
    final nomeAtleta = atletaDoc.data()['nome'] as String? ?? 'Atleta';

    // verificar se já existe vínculo entre esses dois
    final vinculoExistente = await _vinculos
        .where('atletaUid', isEqualTo: atletaUid)
        .where('profissionalUid', isEqualTo: profissional.uid)
        .where('status', isEqualTo: StatusVinculo.ativo.name)
        .limit(1)
        .get();

    if (vinculoExistente.docs.isNotEmpty) {
      throw ArgumentError(
          'Já existe um vínculo ativo com este atleta.');
    }

    // criar vínculo
    final doc = _vinculos.doc();
    final vinculo = Vinculo(
      id: doc.id,
      atletaUid: atletaUid,
      codigoAtleta: codigoAtleta.toUpperCase().trim(),
      nomeAtleta: nomeAtleta,
      profissionalUid: profissional.uid,
      nomeProfissional: profissional.nome,
      perfilProfissional: profissional.perfil,
      status: StatusVinculo.ativo,
      criadoEm: DateTime.now(),
    );

    await doc.set(vinculo.toMap());
    return vinculo;
  }

  /// encerra um vínculo existente
  Future<void> encerrarVinculo(String vinculoId) async {
    await _vinculos.doc(vinculoId).update({
      'status': StatusVinculo.encerrado.name,
      'encerradoEm': Timestamp.fromDate(DateTime.now()),
    });
  }

  // leitura:
  // stream de atletas vinculados a um profissional (vínculos ativos)
  Stream<List<Vinculo>> streamAtletasVinculados(String profissionalUid) {
    return _vinculos
        .where('profissionalUid', isEqualTo: profissionalUid)
        .where('status', isEqualTo: StatusVinculo.ativo.name)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Vinculo.fromMap(doc.data(), doc.id))
            .toList());
  }

  // stream de profissionais vinculados a um atleta (vínculos ativos)
  Stream<List<Vinculo>> streamProfissionaisDoAtleta(String atletaUid) {
    return _vinculos
        .where('atletaUid', isEqualTo: atletaUid)
        .where('status', isEqualTo: StatusVinculo.ativo.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Vinculo.fromMap(doc.data(), doc.id))
            .toList());
  }
}

class ResumoAtletaVinculado {
  final Vinculo vinculo;
  final Sessao? ultimaSessao;
  final NivelRisco? nivelRiscoUltimaSessao;

  const ResumoAtletaVinculado({
    required this.vinculo,
    this.ultimaSessao,
    this.nivelRiscoUltimaSessao,
  });

  bool get temAlerta =>
      nivelRiscoUltimaSessao == NivelRisco.alerta ||
      nivelRiscoUltimaSessao == NivelRisco.critico;

  // busca a última sessão concluída de um atleta vinculado
  static Future<ResumoAtletaVinculado> carregar(
    Vinculo vinculo,
    FirebaseFirestore db,
  ) async {
    final query = await db
        .collection('usuarios')
        .doc(vinculo.atletaUid)
        .collection('sessoes')
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return ResumoAtletaVinculado(vinculo: vinculo);
    }

    final sessao =
        Sessao.fromMap(query.docs.first.data(), query.docs.first.id);
    final nivelRisco = sessao.resultado?.alertas.isEmpty == true
        ? NivelRisco.normal
        : sessao.resultado?.alertas
            .map((a) => a.nivel)
            .reduce((a, b) => a.index > b.index ? a : b);

    return ResumoAtletaVinculado(
      vinculo: vinculo,
      ultimaSessao: sessao,
      nivelRiscoUltimaSessao: nivelRisco,
    );
  }
}