import 'package:cloud_firestore/cloud_firestore.dart';

// enums auxiliares
enum ModalidadeEsportiva {
  corrida,
  ciclismo,
  natacao,
  futebol,
  basquete,
  volei,
  tenis,
  musculacao,
  crossfit,
  outro,
}

enum IntensidadeTreino {
  leve,       // < 60% freq cardíaca máx (220 - idade)
  moderada,   // 60–75% fc máx
  intensa,    // 75–85% fc máx
  muitoIntensa, // > 85% fc máx
}

enum ExposicaoSolar {
  sombra,
  solParcial,
  solPleno,
}

enum TipoVestimenta {
  minima,       // shorts + camiseta leve
  media,        // agasalho leve
  pesada,       // agasalho completo / impermeável
  uniforme,     // uniforme esportivo padrão
}

// escala de cor da urina (1–8, baseada na escala de Armstrong)
// 1–3 = bem hidratado, 4–5 = levemente desidratado, 6–8 = desidratado
enum CorUrina {
  amareloPalido1,
  amareloClaro2,
  amareloMedio3,
  amareloEscuro4,
  amareloAlaranjado5,
  alaranjado6,
  marromClaro7,
  marromEscuro8,
}

enum StatusSessao {
  emAndamento,
  concluida,
  cancelada,
}

// sub-modelos
class CondicoesAmbientais {
  final double temperaturaC;       // °C
  final double umidadeRelativa;    // 0–100 %
  final double velocidadeVentoKmh; // km/h
  final ExposicaoSolar exposicaoSolar;

  const CondicoesAmbientais({
    required this.temperaturaC,
    required this.umidadeRelativa,
    required this.velocidadeVentoKmh,
    required this.exposicaoSolar,
  });

  Map<String, dynamic> toMap() => {
        'temperaturaC': temperaturaC,
        'umidadeRelativa': umidadeRelativa,
        'velocidadeVentoKmh': velocidadeVentoKmh,
        'exposicaoSolar': exposicaoSolar.name,
      };

  factory CondicoesAmbientais.fromMap(Map<String, dynamic> map) =>
      CondicoesAmbientais(
        temperaturaC: (map['temperaturaC'] as num).toDouble(),
        umidadeRelativa: (map['umidadeRelativa'] as num).toDouble(),
        velocidadeVentoKmh: (map['velocidadeVentoKmh'] as num).toDouble(),
        exposicaoSolar: ExposicaoSolar.values.byName(map['exposicaoSolar']),
      );
}

class EstadoBasalAtleta {
  final CorUrina corUrina;
  final int nivelSede;          // 1–5 (1 = sem sede, 5 = muita sede)
  final bool sintomaPrevio;     // dor de cabeça, tontura, náusea pré-sessão
  final String? descricaoSintoma;
  final double hidratacaoUltimasHoras; // estimativa de mL ingeridos nas últimas 2h

  const EstadoBasalAtleta({
    required this.corUrina,
    required this.nivelSede,
    required this.sintomaPrevio,
    this.descricaoSintoma,
    required this.hidratacaoUltimasHoras,
  });

  Map<String, dynamic> toMap() => {
        'corUrina': corUrina.name,
        'nivelSede': nivelSede,
        'sintomaPrevio': sintomaPrevio,
        'descricaoSintoma': descricaoSintoma,
        'hidratacaoUltimasHoras': hidratacaoUltimasHoras,
      };

  factory EstadoBasalAtleta.fromMap(Map<String, dynamic> map) =>
      EstadoBasalAtleta(
        corUrina: CorUrina.values.byName(map['corUrina']),
        nivelSede: map['nivelSede'] as int,
        sintomaPrevio: map['sintomaPrevio'] as bool,
        descricaoSintoma: map['descricaoSintoma'] as String?,
        hidratacaoUltimasHoras:
            (map['hidratacaoUltimasHoras'] as num).toDouble(),
      );
}

// registro individual de ingestão de fluido durante a sessão
class RegistroIngestao {
  final DateTime horario;
  final double volumeMl;
  final String? descricao; // ex: "água", "isotônico", "gel"

  const RegistroIngestao({
    required this.horario,
    required this.volumeMl,
    this.descricao,
  });

  Map<String, dynamic> toMap() => {
        'horario': Timestamp.fromDate(horario),
        'volumeMl': volumeMl,
        'descricao': descricao,
      };

  factory RegistroIngestao.fromMap(Map<String, dynamic> map) => RegistroIngestao(
        horario: (map['horario'] as Timestamp).toDate(),
        volumeMl: (map['volumeMl'] as num).toDouble(),
        descricao: map['descricao'] as String?,
      );
}

class DadosPosSessao {
  final double massaCorporalKg;
  final bool roupaEncarcada;         // roupa muito encharcada (afeta medida)
  final bool trocouVestimenta;       // houve troca durante a sessão
  final double volumeUrinarioMl;     // urina eliminada durante a sessão
  final bool sintomaGastrointestinal;
  final bool sintomaFadiga;
  final int toleranciaPlanoHidrico;  // 1–5 (quão bem seguiu o plano)
  final String? observacoes;

  const DadosPosSessao({
    required this.massaCorporalKg,
    required this.roupaEncarcada,
    required this.trocouVestimenta,
    required this.volumeUrinarioMl,
    required this.sintomaGastrointestinal,
    required this.sintomaFadiga,
    required this.toleranciaPlanoHidrico,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
        'massaCorporalKg': massaCorporalKg,
        'roupaEncarcada': roupaEncarcada,
        'trocouVestimenta': trocouVestimenta,
        'volumeUrinarioMl': volumeUrinarioMl,
        'sintomaGastrointestinal': sintomaGastrointestinal,
        'sintomaFadiga': sintomaFadiga,
        'toleranciaPlanoHidrico': toleranciaPlanoHidrico,
        'observacoes': observacoes,
      };

  factory DadosPosSessao.fromMap(Map<String, dynamic> map) => DadosPosSessao(
        massaCorporalKg: (map['massaCorporalKg'] as num).toDouble(),
        roupaEncarcada: map['roupaEncarcada'] as bool,
        trocouVestimenta: map['trocouVestimenta'] as bool,
        volumeUrinarioMl: (map['volumeUrinarioMl'] as num).toDouble(),
        sintomaGastrointestinal: map['sintomaGastrointestinal'] as bool,
        sintomaFadiga: map['sintomaFadiga'] as bool,
        toleranciaPlanoHidrico: map['toleranciaPlanoHidrico'] as int,
        observacoes: map['observacoes'] as String?,
      );
}

// modelo principal
class Sessao {
  final String? id;                          // ID do documento no firestore
  final String atletaUid;                    // UID do atleta (firebase auth)
  final String codigoAtleta;                 // código anonimizado (ex: ATL-BQG9SM)
  final DateTime dataHoraInicio;
  final DateTime? dataHoraFim;
  final StatusSessao status;

  // dados pré-sessão
  final double massaPreKg;
  final ModalidadeEsportiva modalidade;
  final IntensidadeTreino intensidade;
  final int duracaoPrevistaMin;
  final TipoVestimenta vestimenta;
  final CondicoesAmbientais condicoesAmbientais;
  final EstadoBasalAtleta estadoBasal;

  // durante a sessão
  final List<RegistroIngestao> registrosIngestao;

  // pós-sessão
  final DadosPosSessao? dadosPosSessao;

  // resultado calculado (preenchido pelo motor)
  final ResultadoSessao? resultado;

  const Sessao({
    this.id,
    required this.atletaUid,
    required this.codigoAtleta,
    required this.dataHoraInicio,
    this.dataHoraFim,
    required this.status,
    required this.massaPreKg,
    required this.modalidade,
    required this.intensidade,
    required this.duracaoPrevistaMin,
    required this.vestimenta,
    required this.condicoesAmbientais,
    required this.estadoBasal,
    this.registrosIngestao = const [],
    this.dadosPosSessao,
    this.resultado,
  });

  /// duração real em horas
  double get duracaoRealHoras {
    final fim = dataHoraFim ?? DateTime.now();
    return fim.difference(dataHoraInicio).inMinutes / 60.0;
  }

  /// total ingerido durante a sessão em mL
  double get totalIngeridoMl =>
      registrosIngestao.fold(0.0, (soma, r) => soma + r.volumeMl);

  // serialização
  Map<String, dynamic> toMap() => {
        'atletaUid': atletaUid,
        'codigoAtleta': codigoAtleta,
        'dataHoraInicio': Timestamp.fromDate(dataHoraInicio),
        'dataHoraFim':
            dataHoraFim != null ? Timestamp.fromDate(dataHoraFim!) : null,
        'status': status.name,
        'massaPreKg': massaPreKg,
        'modalidade': modalidade.name,
        'intensidade': intensidade.name,
        'duracaoPrevistaMin': duracaoPrevistaMin,
        'vestimenta': vestimenta.name,
        'condicoesAmbientais': condicoesAmbientais.toMap(),
        'estadoBasal': estadoBasal.toMap(),
        'registrosIngestao': registrosIngestao.map((r) => r.toMap()).toList(),
        'dadosPosSessao': dadosPosSessao?.toMap(),
        'resultado': resultado?.toMap(),
      };

  factory Sessao.fromMap(Map<String, dynamic> map, String docId) => Sessao(
        id: docId,
        atletaUid: map['atletaUid'] as String,
        codigoAtleta: map['codigoAtleta'] as String,
        dataHoraInicio: (map['dataHoraInicio'] as Timestamp).toDate(),
        dataHoraFim: map['dataHoraFim'] != null
            ? (map['dataHoraFim'] as Timestamp).toDate()
            : null,
        status: StatusSessao.values.byName(map['status']),
        massaPreKg: (map['massaPreKg'] as num).toDouble(),
        modalidade: ModalidadeEsportiva.values.byName(map['modalidade']),
        intensidade: IntensidadeTreino.values.byName(map['intensidade']),
        duracaoPrevistaMin: map['duracaoPrevistaMin'] as int,
        vestimenta: TipoVestimenta.values.byName(map['vestimenta']),
        condicoesAmbientais:
            CondicoesAmbientais.fromMap(map['condicoesAmbientais']),
        estadoBasal: EstadoBasalAtleta.fromMap(map['estadoBasal']),
        registrosIngestao: (map['registrosIngestao'] as List<dynamic>)
            .map((e) => RegistroIngestao.fromMap(e as Map<String, dynamic>))
            .toList(),
        dadosPosSessao: map['dadosPosSessao'] != null
            ? DadosPosSessao.fromMap(map['dadosPosSessao'])
            : null,
        resultado: map['resultado'] != null
            ? ResultadoSessao.fromMap(map['resultado'])
            : null,
      );

  /// cria uma cópia com campos alterados
  Sessao copyWith({
    String? id,
    String? atletaUid,
    String? codigoAtleta,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    StatusSessao? status,
    double? massaPreKg,
    ModalidadeEsportiva? modalidade,
    IntensidadeTreino? intensidade,
    int? duracaoPrevistaMin,
    TipoVestimenta? vestimenta,
    CondicoesAmbientais? condicoesAmbientais,
    EstadoBasalAtleta? estadoBasal,
    List<RegistroIngestao>? registrosIngestao,
    DadosPosSessao? dadosPosSessao,
    ResultadoSessao? resultado,
  }) =>
      Sessao(
        id: id ?? this.id,
        atletaUid: atletaUid ?? this.atletaUid,
        codigoAtleta: codigoAtleta ?? this.codigoAtleta,
        dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
        dataHoraFim: dataHoraFim ?? this.dataHoraFim,
        status: status ?? this.status,
        massaPreKg: massaPreKg ?? this.massaPreKg,
        modalidade: modalidade ?? this.modalidade,
        intensidade: intensidade ?? this.intensidade,
        duracaoPrevistaMin: duracaoPrevistaMin ?? this.duracaoPrevistaMin,
        vestimenta: vestimenta ?? this.vestimenta,
        condicoesAmbientais: condicoesAmbientais ?? this.condicoesAmbientais,
        estadoBasal: estadoBasal ?? this.estadoBasal,
        registrosIngestao: registrosIngestao ?? this.registrosIngestao,
        dadosPosSessao: dadosPosSessao ?? this.dadosPosSessao,
        resultado: resultado ?? this.resultado,
      );
}

// resultado calculado (preenchido pelo CalculoSudoreseService)
enum NivelRisco {
  normal,
  atencao,
  alerta,
  critico,
}

class AlertaRisco {
  final NivelRisco nivel;
  final String mensagem;
  final String? orientacao;

  const AlertaRisco({
    required this.nivel,
    required this.mensagem,
    this.orientacao,
  });

  Map<String, dynamic> toMap() => {
        'nivel': nivel.name,
        'mensagem': mensagem,
        'orientacao': orientacao,
      };

  factory AlertaRisco.fromMap(Map<String, dynamic> map) => AlertaRisco(
        nivel: NivelRisco.values.byName(map['nivel']),
        mensagem: map['mensagem'] as String,
        orientacao: map['orientacao'] as String?,
      );
}

class ResultadoSessao {
  // métricas calculadas
  final double perdaMassaAjustadaKg;   // perda real corrigida por ingestao e urina
  final double taxaSudoreseLh;          // L/h
  final double variacaoMassaPercent;    // % de variação de massa corporal
  final double balanceHidricoMl;        // ingestao realizada - perda estimada

  // recomendações
  final double ingestaoAlvoMlH;         // mL/h recomendados
  final int intervaloIngestaoMin;       // a cada x minutos beber
  final double volumePorDoseMl;         // mL por dose

  // triagem de risco
  final List<AlertaRisco> alertas;
  final bool encaminhamentoRecomendado;

  const ResultadoSessao({
    required this.perdaMassaAjustadaKg,
    required this.taxaSudoreseLh,
    required this.variacaoMassaPercent,
    required this.balanceHidricoMl,
    required this.ingestaoAlvoMlH,
    required this.intervaloIngestaoMin,
    required this.volumePorDoseMl,
    required this.alertas,
    required this.encaminhamentoRecomendado,
  });

  Map<String, dynamic> toMap() => {
        'perdaMassaAjustadaKg': perdaMassaAjustadaKg,
        'taxaSudoreseLh': taxaSudoreseLh,
        'variacaoMassaPercent': variacaoMassaPercent,
        'balanceHidricoMl': balanceHidricoMl,
        'ingestaoAlvoMlH': ingestaoAlvoMlH,
        'intervaloIngestaoMin': intervaloIngestaoMin,
        'volumePorDoseMl': volumePorDoseMl,
        'alertas': alertas.map((a) => a.toMap()).toList(),
        'encaminhamentoRecomendado': encaminhamentoRecomendado,
      };

  factory ResultadoSessao.fromMap(Map<String, dynamic> map) => ResultadoSessao(
        perdaMassaAjustadaKg:
            (map['perdaMassaAjustadaKg'] as num).toDouble(),
        taxaSudoreseLh: (map['taxaSudoreseLh'] as num).toDouble(),
        variacaoMassaPercent: (map['variacaoMassaPercent'] as num).toDouble(),
        balanceHidricoMl: (map['balanceHidricoMl'] as num).toDouble(),
        ingestaoAlvoMlH: (map['ingestaoAlvoMlH'] as num).toDouble(),
        intervaloIngestaoMin: map['intervaloIngestaoMin'] as int,
        volumePorDoseMl: (map['volumePorDoseMl'] as num).toDouble(),
        alertas: (map['alertas'] as List<dynamic>)
            .map((e) => AlertaRisco.fromMap(e as Map<String, dynamic>))
            .toList(),
        encaminhamentoRecomendado: map['encaminhamentoRecomendado'] as bool,
      );
}