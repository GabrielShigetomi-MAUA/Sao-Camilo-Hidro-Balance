import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sessao.dart';
import 'calculo_sudorese.dart';

class SessaoService {
  final FirebaseFirestore _db;

  SessaoService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  // referências
  CollectionReference<Map<String, dynamic>> _sessoesRef(String atletaUid) =>
      _db.collection('usuarios').doc(atletaUid).collection('sessoes');

  // pré-sessão:

  // inicia uma nova sessão com os dados pré-treino
  // retorna o ID do documento criado no firestore
  Future<String> iniciarSessao(Sessao sessao) async {
    final doc = _sessoesRef(sessao.atletaUid).doc();
    final sessaoComId = sessao.copyWith(id: doc.id);
    await doc.set(sessaoComId.toMap());
    return doc.id;
  }

  // atualização durante a sessão:

  // adiciona um registro de ingestão de fluido à sessão em andamento
  Future<void> adicionarIngestao(
    String atletaUid,
    String sessaoId,
    RegistroIngestao ingestao,
  ) async {
    await _sessoesRef(atletaUid).doc(sessaoId).update({
      'registrosIngestao': FieldValue.arrayUnion([ingestao.toMap()]),
    });
  }

  // remove um registro de ingestão
  Future<void> removerIngestao(
    String atletaUid,
    String sessaoId,
    RegistroIngestao ingestao,
  ) async {
    await _sessoesRef(atletaUid).doc(sessaoId).update({
      'registrosIngestao': FieldValue.arrayRemove([ingestao.toMap()]),
    });
  }

  // pós-sessão e cálculo:

  // salva os dados pós-sessão, executa o motor de cálculo e persiste o resultado
  Future<Sessao> finalizarSessao(
    String atletaUid,
    String sessaoId,
    DadosPosSessao dadosPos,
  ) async {
    final sessaoAtual = await buscarSessao(atletaUid, sessaoId);
    if (sessaoAtual == null) {
      throw StateError(
        'Sessão $sessaoId não encontrada para o atleta $atletaUid.',
      );
    }

    final sessaoCompleta = sessaoAtual.copyWith(
      dataHoraFim: DateTime.now(),
      status: StatusSessao.concluida,
      dadosPosSessao: dadosPos,
    );

    final resultado = CalculoSudoreseService.calcular(sessaoCompleta);
    if (resultado == null) {
      throw StateError(
        'Não foi possível calcular o resultado — dados insuficientes.',
      );
    }

    final sessaoFinal = sessaoCompleta.copyWith(resultado: resultado);

    await _sessoesRef(atletaUid).doc(sessaoId).set(sessaoFinal.toMap());

    return sessaoFinal;
  }

  // cancela sessão em andamento
  Future<void> cancelarSessao(String atletaUid, String sessaoId) async {
    await _sessoesRef(atletaUid).doc(sessaoId).update({
      'status': StatusSessao.cancelada.name,
      'dataHoraFim': Timestamp.fromDate(DateTime.now()),
    });
  }

  // leitura:

  // busca sessão específica por ID, retorna null se não existir
  Future<Sessao?> buscarSessao(String atletaUid, String sessaoId) async {
    final doc = await _sessoesRef(atletaUid).doc(sessaoId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Sessao.fromMap(doc.data()!, doc.id);
  }

  // stream em tempo real de uma sessão (manter UI sincronizada durante coleta)
  Stream<Sessao?> streamSessao(String atletaUid, String sessaoId) {
    return _sessoesRef(atletaUid)
        .doc(sessaoId)
        .snapshots()
        .map(
          (snap) => snap.exists && snap.data() != null
              ? Sessao.fromMap(snap.data()!, snap.id)
              : null,
        );
  }

  // lista sessões concluídas do atleta
  Future<List<Sessao>> listarSessoesConcluidas(String atletaUid) async {
    final query = await _sessoesRef(atletaUid)
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .get();

    return query.docs.map((doc) => Sessao.fromMap(doc.data(), doc.id)).toList();
  }

  // stream da lista de sessões concluídas (exibir ultimas sessões em tempo real)
  Stream<List<Sessao>> streamSessoesConcluidas(
    String atletaUid, {
    int limite = 10,
  }) {
    return _sessoesRef(atletaUid)
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .limit(limite)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Sessao.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // busca a sessão em andamento do atleta
  Future<Sessao?> buscarSessaoEmAndamento(String atletaUid) async {
    final query = await _sessoesRef(
      atletaUid,
    ).where('status', isEqualTo: StatusSessao.emAndamento.name).limit(1).get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Sessao.fromMap(doc.data(), doc.id);
  }

  // estatísticas para a home:
  
  // calcula média de taxa de sudorese e variação de massa das últimas sessoes
  Future<EstatisticasResumidas> calcularEstatisticasResumidas(
    String atletaUid, {
    int quantidade = 10,
  }) async {
    final sessoes = await _sessoesRef(atletaUid)
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .limit(quantidade)
        .get();

    if (sessoes.docs.isEmpty) {
      return const EstatisticasResumidas(
        totalSessoes: 0,
        mediaSudoreseLh: 0.0,
        mediaVariacaoMassaPercent: 0.0,
      );
    }

    final resultados = sessoes.docs
        .map((doc) => Sessao.fromMap(doc.data(), doc.id).resultado)
        .whereType<ResultadoSessao>()
        .toList();

    if (resultados.isEmpty) {
      return EstatisticasResumidas(
        totalSessoes: sessoes.docs.length,
        mediaSudoreseLh: 0.0,
        mediaVariacaoMassaPercent: 0.0,
      );
    }

    final mediaSudorese =
        resultados.map((r) => r.taxaSudoreseLh).reduce((a, b) => a + b) /
        resultados.length;

    final mediaVariacao =
        resultados.map((r) => r.variacaoMassaPercent).reduce((a, b) => a + b) /
        resultados.length;

    return EstatisticasResumidas(
      totalSessoes: sessoes.docs.length,
      mediaSudoreseLh: mediaSudorese,
      mediaVariacaoMassaPercent: mediaVariacao,
    );
  }

  Stream<EstatisticasResumidas> streamEstatisticasResumidas(
    String atletaUid, {
    int quantidade = 10,
  }) {
    return _sessoesRef(atletaUid)
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .limit(quantidade)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) {
            return const EstatisticasResumidas(
              totalSessoes: 0,
              mediaSudoreseLh: 0.0,
              mediaVariacaoMassaPercent: 0.0,
            );
          }

          final resultados = snap.docs
              .map((doc) => Sessao.fromMap(doc.data(), doc.id).resultado)
              .whereType<ResultadoSessao>()
              .toList();

          if (resultados.isEmpty) {
            return EstatisticasResumidas(
              totalSessoes: snap.docs.length,
              mediaSudoreseLh: 0.0,
              mediaVariacaoMassaPercent: 0.0,
            );
          }

          final mediaSudorese =
              resultados.map((r) => r.taxaSudoreseLh).reduce((a, b) => a + b) /
              resultados.length;

          final mediaVariacao =
              resultados
                  .map((r) => r.variacaoMassaPercent)
                  .reduce((a, b) => a + b) /
              resultados.length;

          return EstatisticasResumidas(
            totalSessoes: snap.docs.length,
            mediaSudoreseLh: mediaSudorese,
            mediaVariacaoMassaPercent: mediaVariacao,
          );
        });
  }

  // agrupamento por contexto:

  Future<List<GrupoContexto>> agruparSessoesPorContexto(
    String atletaUid,
  ) async {
    final sessoes = await listarSessoesConcluidas(atletaUid);
    return _agrupar(sessoes);
  }

  // stream agrupamento
  Stream<List<GrupoContexto>> streamGruposContexto(String atletaUid) {
    return _sessoesRef(atletaUid)
        .where('status', isEqualTo: StatusSessao.concluida.name)
        .orderBy('dataHoraInicio', descending: true)
        .snapshots()
        .map((snap) {
          final sessoes = snap.docs
              .map((doc) => Sessao.fromMap(doc.data(), doc.id))
              .toList();
          return _agrupar(sessoes);
        });
  }

  List<GrupoContexto> _agrupar(List<Sessao> sessoes) {
    // cada chave identifica uma combinação de contexto
    final Map<String, List<Sessao>> buckets = {};

    for (final s in sessoes) {
      final faixa = FaixaTemperatura.de(s.condicoesAmbientais.temperaturaC);
      final chave = '${s.modalidade.name}|${faixa.name}|${s.intensidade.name}';
      buckets.putIfAbsent(chave, () => []).add(s);
    }

    final grupos = buckets.entries.map((entry) {
      // reconstrói os três critérios a partir da chave
      final partes = entry.key.split('|');
      final modalidade = ModalidadeEsportiva.values.byName(partes[0]);
      final faixa = FaixaTemperatura.values.byName(partes[1]);
      final intensidade = IntensidadeTreino.values.byName(partes[2]);
      final lista = entry.value;

      // considera apenas sessões que têm resultado calculado
      final resultados = lista
          .map((s) => s.resultado)
          .whereType<ResultadoSessao>()
          .toList();

      final mediaSudorese = resultados.isEmpty
          ? 0.0
          : resultados.map((r) => r.taxaSudoreseLh).reduce((a, b) => a + b) /
                resultados.length;

      final mediaVariacao = resultados.isEmpty
          ? 0.0
          : resultados
                    .map((r) => r.variacaoMassaPercent)
                    .reduce((a, b) => a + b) /
                resultados.length;

      // data da sessão mais recente do grupo
      final maisRecente = lista
          .map((s) => s.dataHoraInicio)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      return GrupoContexto(
        modalidade: modalidade,
        faixaTemperatura: faixa,
        intensidade: intensidade,
        totalSessoes: lista.length,
        mediaSudoreseLh: mediaSudorese,
        mediaVariacaoMassaPercent: mediaVariacao,
        ultimaSessao: maisRecente,
        sessoes: lista,
      );
    }).toList();

    // grupos com mais sessões aparecem primeiro
    grupos.sort((a, b) => b.totalSessoes.compareTo(a.totalSessoes));
    return grupos;
  }

  // remove sessão permanentemente
  Future<void> excluirSessao(String atletaUid, String sessaoId) async {
    await _sessoesRef(atletaUid).doc(sessaoId).delete();
  }
}

// DTO de estatísticas resumidas
class EstatisticasResumidas {
  final int totalSessoes;
  final double mediaSudoreseLh;
  final double mediaVariacaoMassaPercent;

  const EstatisticasResumidas({
    required this.totalSessoes,
    required this.mediaSudoreseLh,
    required this.mediaVariacaoMassaPercent,
  });
}

// faixas de temperatura para agrupamento
enum FaixaTemperatura {
  fria, // < 15 °C
  amena, // 15–25 °C
  quente; // > 25 °C

  // constrói a faixa a partir de um valor numérico
  static FaixaTemperatura de(double tempC) {
    if (tempC < 15) return FaixaTemperatura.fria;
    if (tempC <= 25) return FaixaTemperatura.amena;
    return FaixaTemperatura.quente;
  }

  String get label => switch (this) {
    FaixaTemperatura.fria => 'Frio (<15 °C)',
    FaixaTemperatura.amena => 'Ameno (15–25 °C)',
    FaixaTemperatura.quente => 'Quente (>25 °C)',
  };
}

// resultado de um grupo de sessões com contexto semelhante
class GrupoContexto {
  final ModalidadeEsportiva modalidade;
  final FaixaTemperatura faixaTemperatura;
  final IntensidadeTreino intensidade;
  final int totalSessoes;
  final double mediaSudoreseLh;
  final double mediaVariacaoMassaPercent;
  final DateTime ultimaSessao;
  final List<Sessao> sessoes;

  const GrupoContexto({
    required this.modalidade,
    required this.faixaTemperatura,
    required this.intensidade,
    required this.totalSessoes,
    required this.mediaSudoreseLh,
    required this.mediaVariacaoMassaPercent,
    required this.ultimaSessao,
    required this.sessoes,
  });
}
