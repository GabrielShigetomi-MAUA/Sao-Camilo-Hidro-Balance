import '../models/sessao.dart';

class CalculoSudoreseService {
  // constantes clínicas:

  /// limiar de desidratação leve: perda >= 2% da massa corporal
  static const double _limiarDesidratacaoLevePercent = 2.0;

  /// limiar de desidratação moderada: perda >= 3%
  static const double _limiarDesidratacaoModeradaPercent = 3.0;

  /// limiar de desidratação grave: perda >= 5%
  static const double _limiarDesidratacaoGravePercent = 5.0;

  /// limiar de hiperidratação: ganho >= 2% da massa corporal
  static const double _limiarHiperidratacaoPercent = 2.0;

  /// taxa de sudorese muito baixa (possível erro de medida): < 0.2 L/h
  static const double _limiarSudoreseBaixaLh = 0.2;

  /// taxa de sudorese muito alta (possível erro de medida): > 3.5 L/h
  static const double _limiarSudoreseAltaLh = 3.5;

  /// intervalo padrão de ingestão em min
  static const int _intervaloIngestaoMinPadrao = 15;

  // ponto de entrada principal:
  // calcula o resultado completo de uma sessão concluída

  // retorna null se os dados pós-sessão ainda não foram preenchidos
  static ResultadoSessao? calcular(Sessao sessao) {
    final pos = sessao.dadosPosSessao;
    if (pos == null) return null;

    final duracaoHoras = sessao.duracaoRealHoras > 0
        ? sessao.duracaoRealHoras
        : sessao.duracaoPrevistaMin / 60.0;

    // 1- perda de massa ajustada
    final perdaAjustadaKg = _calcularPerdaMassaAjustada(
      massaPreKg: sessao.massaPreKg,
      massaPosKg: pos.massaCorporalKg,
      totalIngeridoMl: sessao.totalIngeridoMl,
      volumeUrinarioMl: pos.volumeUrinarioMl,
    );

    // 2- taxa de sudorese
    final taxaSudoreseLh = _calcularTaxaSudorese(
      perdaAjustadaKg: perdaAjustadaKg,
      duracaoHoras: duracaoHoras,
    );

    // 3- variação percentual de massa
    final variacaoPercent = _calcularVariacaoMassa(
      massaPreKg: sessao.massaPreKg,
      massaPosKg: pos.massaCorporalKg,
    );

    // 4- balanço hídrico
    final balanco = _calcularBalancoHidrico(
      perdaAjustadaKg: perdaAjustadaKg,
      totalIngeridoMl: sessao.totalIngeridoMl,
    );

    // 5- recomendações de ingestão futura
    final recomendacao = _gerarRecomendacao(
      taxaSudoreseLh: taxaSudoreseLh,
      duracaoHoras: duracaoHoras,
    );

    // 6- triagem de risco
    final alertas = _triarRiscos(
      variacaoPercent: variacaoPercent,
      taxaSudoreseLh: taxaSudoreseLh,
      balanco: balanco,
      estadoBasal: sessao.estadoBasal,
      dadosPos: pos,
    );

    final encaminhamento = alertas.any(
      (a) => a.nivel == NivelRisco.alerta || a.nivel == NivelRisco.critico,
    );

    return ResultadoSessao(
      perdaMassaAjustadaKg: perdaAjustadaKg,
      taxaSudoreseLh: taxaSudoreseLh,
      variacaoMassaPercent: variacaoPercent,
      balanceHidricoMl: balanco,
      ingestaoAlvoMlH: recomendacao.ingestaoAlvoMlH,
      intervaloIngestaoMin: recomendacao.intervaloMin,
      volumePorDoseMl: recomendacao.volumePorDoseMl,
      alertas: alertas,
      encaminhamentoRecomendado: encaminhamento,
    );
  }

  // cálculos individuais:

  // perda de massa ajustada em kg
  // fórmula: (massaPré - massaPós) + (ingestão em kg) - (urina em kg)
  // assume densidade da água = 1 kg/L -> 1 mL = 0.001 kg
  static double calcularPerdaMassaAjustada({
    required double massaPreKg,
    required double massaPosKg,
    required double totalIngeridoMl,
    required double volumeUrinarioMl,
  }) =>
      _calcularPerdaMassaAjustada(
        massaPreKg: massaPreKg,
        massaPosKg: massaPosKg,
        totalIngeridoMl: totalIngeridoMl,
        volumeUrinarioMl: volumeUrinarioMl,
      );

  // taxa de sudorese em L/h
  static double calcularTaxaSudorese({
    required double perdaAjustadaKg,
    required double duracaoHoras,
  }) =>
      _calcularTaxaSudorese(
        perdaAjustadaKg: perdaAjustadaKg,
        duracaoHoras: duracaoHoras,
      );

  // variação percentual de massa corporal
  // positivo = ganho (hiperidratação), negativo = perda (desidratação)
  static double calcularVariacaoMassa({
    required double massaPreKg,
    required double massaPosKg,
  }) =>
      _calcularVariacaoMassa(
        massaPreKg: massaPreKg,
        massaPosKg: massaPosKg,
      );

  // balanço hídrico em mL: ingestão realizada - perda estimada
  // positivo = ingestão maior que perda, negativo = deficit
  static double calcularBalancoHidrico({
    required double perdaAjustadaKg,
    required double totalIngeridoMl,
  }) =>
      _calcularBalancoHidrico(
        perdaAjustadaKg: perdaAjustadaKg,
        totalIngeridoMl: totalIngeridoMl,
      );

  // implementações privadas:

  static double _calcularPerdaMassaAjustada({
    required double massaPreKg,
    required double massaPosKg,
    required double totalIngeridoMl,
    required double volumeUrinarioMl,
  }) {
    final diferencaBruta = massaPreKg - massaPosKg;
    final ingeridoKg = totalIngeridoMl / 1000.0;
    final urinaKg = volumeUrinarioMl / 1000.0;
    return diferencaBruta + ingeridoKg - urinaKg;
  }

  static double _calcularTaxaSudorese({
    required double perdaAjustadaKg,
    required double duracaoHoras,
  }) {
    if (duracaoHoras <= 0) return 0.0;
    return perdaAjustadaKg / duracaoHoras;
  }

  static double _calcularVariacaoMassa({
    required double massaPreKg,
    required double massaPosKg,
  }) {
    if (massaPreKg <= 0) return 0.0;
    return ((massaPosKg - massaPreKg) / massaPreKg) * 100.0;
  }

  static double _calcularBalancoHidrico({
    required double perdaAjustadaKg,
    required double totalIngeridoMl,
  }) {
    final perdaMl = perdaAjustadaKg * 1000.0;
    return totalIngeridoMl - perdaMl;
  }

  // gerador de recomendações
  static _RecomendacaoHidrica _gerarRecomendacao({
    required double taxaSudoreseLh,
    required double duracaoHoras,
  }) {
    // alvo: repor 80% da taxa de sudorese (evitar superingestão e hiperidratação)
    final ingestaoAlvoMlH = taxaSudoreseLh * 1000.0 * 0.8;

    // intervalo: padrão 15 min, ajusta se a dose por intervalo ficar > 350 mL
    int intervaloMin = _intervaloIngestaoMinPadrao;
    double volumePorDose = ingestaoAlvoMlH * (intervaloMin / 60.0);

    if (volumePorDose > 350) {
      // Aumenta o intervalo pra manter volume por dose até 350 mL
      intervaloMin = ((350.0 / ingestaoAlvoMlH) * 60).round();
      intervaloMin = intervaloMin.clamp(10, 20);
      volumePorDose = ingestaoAlvoMlH * (intervaloMin / 60.0);
    }

    return _RecomendacaoHidrica(
      ingestaoAlvoMlH: ingestaoAlvoMlH,
      intervaloMin: intervaloMin,
      volumePorDoseMl: volumePorDose,
    );
  }

  // triagem de risco:
  static List<AlertaRisco> _triarRiscos({
    required double variacaoPercent,
    required double taxaSudoreseLh,
    required double balanco,
    required EstadoBasalAtleta estadoBasal,
    required DadosPosSessao dadosPos,
  }) {
    final alertas = <AlertaRisco>[];

    // desidratação
    if (variacaoPercent <= -_limiarDesidratacaoGravePercent) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.critico,
        mensagem: 'Desidratação grave detectada (perda ≥ 5% da massa corporal).',
        orientacao:
            'Encaminhar imediatamente para avaliação médica. Não retomar atividade.',
      ));
    } else if (variacaoPercent <= -_limiarDesidratacaoModeradaPercent) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.alerta,
        mensagem: 'Desidratação moderada (perda entre 3–5% da massa corporal).',
        orientacao:
            'Reidratação supervisionada recomendada. Evitar novo esforço intenso.',
      ));
    } else if (variacaoPercent <= -_limiarDesidratacaoLevePercent) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.atencao,
        mensagem: 'Desidratação leve (perda entre 2–3% da massa corporal).',
        orientacao: 'Reidratar nas próximas 2–4h antes da próxima sessão.',
      ));
    }

    // hiperidratação
    if (variacaoPercent >= _limiarHiperidratacaoPercent) {
      alertas.add(AlertaRisco(
        nivel: variacaoPercent >= 3.0 ? NivelRisco.alerta : NivelRisco.atencao,
        mensagem:
            'Possível hiperidratação (ganho de ${variacaoPercent.toStringAsFixed(1)}% de massa).',
        orientacao:
            'Investigar ingestão excessiva de fluidos. Risco de hiponatremia associada ao exercício.',
      ));
    }

    // hiponatremia (sinal combinado: hiperidratação + sintomas)
    if (variacaoPercent >= _limiarHiperidratacaoPercent &&
        (dadosPos.sintomaGastrointestinal || estadoBasal.nivelSede <= 1)) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.critico,
        mensagem:
            'Sinais compatíveis com hiponatremia associada ao exercício (EAH).',
        orientacao:
            'Avaliação médica urgente. Não administrar fluidos hipotônicos.',
      ));
    }

    // taxa de sudorese muito fora do normal (possível erro de medida)
    if (taxaSudoreseLh < _limiarSudoreseBaixaLh && taxaSudoreseLh > 0) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.atencao,
        mensagem: 'Taxa de sudorese muito baixa (< 0,2 L/h). Possível erro de medida.',
        orientacao: 'Verificar condições de pesagem (mesma balança, bexiga esvaziada, vestimenta padronizada).',
      ));
    } else if (taxaSudoreseLh > _limiarSudoreseAltaLh) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.atencao,
        mensagem: 'Taxa de sudorese muito alta (> 3,5 L/h). Verificar medições.',
        orientacao: 'Confirmar condições de pesagem antes de usar este resultado como referência.',
      ));
    }

    // cor da urina pré-sessão elevada
    final indiceUrina = estadoBasal.corUrina.index;
    if (indiceUrina >= 5) {
      alertas.add(AlertaRisco(
        nivel: indiceUrina >= 6 ? NivelRisco.alerta : NivelRisco.atencao,
        mensagem: 'Urina escura no estado basal — atleta pode ter iniciado a sessão desidratado.',
        orientacao: 'Avaliar estratégia de hidratação pré-treino.',
      ));
    }

    // sintomas pós-sessão
    if (dadosPos.sintomaFadiga && variacaoPercent <= -2.0) {
      alertas.add(const AlertaRisco(
        nivel: NivelRisco.atencao,
        mensagem: 'Fadiga associada a deficit hídrico.',
        orientacao: 'Monitorar recuperação e hidratação nas próximas horas.',
      ));
    }

    return alertas;
  }
}

// DTO interno
class _RecomendacaoHidrica {
  final double ingestaoAlvoMlH;
  final int intervaloMin;
  final double volumePorDoseMl;

  const _RecomendacaoHidrica({
    required this.ingestaoAlvoMlH,
    required this.intervaloMin,
    required this.volumePorDoseMl,
  });
}