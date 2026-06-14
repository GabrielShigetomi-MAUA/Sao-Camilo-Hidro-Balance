import 'package:flutter/material.dart';
import '../../models/sessao.dart';
import 'tela_recomendacoes.dart';

class TelaResultadoSessao extends StatelessWidget {
  final String atletaUid;
  final String sessaoId;
  final ResultadoSessao resultado;

  const TelaResultadoSessao({
    super.key,
    required this.atletaUid,
    required this.sessaoId,
    required this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC41230),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Resultado da sessão',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeaderResultado(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardsMetricas(),
                  const SizedBox(height: 16),
                  _buildCardBalanco(),
                  if (resultado.alertas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCardAlertas(),
                  ],
                  const SizedBox(height: 16),
                  _buildCardResumoRecomendacao(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBotoesAcao(context),
        ],
      ),
    );
  }

  // header
  Widget _buildHeaderResultado(BuildContext context) {
    final nivelGeral = _nivelGeralRisco();
    final corHeader = _corNivel(nivelGeral);

    return Container(
      width: double.infinity,
      color: const Color(0xFFC41230),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: corHeader.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: corHeader.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconeNivel(nivelGeral), color: corHeader, size: 16),
                const SizedBox(width: 6),
                Text(
                  _labelNivelGeral(nivelGeral),
                  style: TextStyle(
                    color: corHeader,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${resultado.taxaSudoreseLh.toStringAsFixed(2)} L/h',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w200,
              letterSpacing: 1,
            ),
          ),
          const Text(
            'Taxa de sudorese estimada',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // cards das métricas
  Widget _buildCardsMetricas() {
    final variacao = resultado.variacaoMassaPercent;
    final corVariacao = variacao <= -3.0
        ? const Color(0xFFD32F2F)
        : variacao <= -2.0
            ? const Color(0xFFFF7043)
            : variacao >= 2.0
                ? const Color(0xFF1565C0)
                : const Color(0xFF2E7D32);

    return Row(
      children: [
        Expanded(
          child: _buildCardMetrica(
            icone: Icons.monitor_weight_outlined,
            label: 'Perda ajustada',
            valor:
                '${resultado.perdaMassaAjustadaKg.toStringAsFixed(2)} kg',
            cor: const Color(0xFFC41230),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardMetrica(
            icone: Icons.trending_down,
            label: 'Variação de massa',
            valor:
                '${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(1)}%',
            cor: corVariacao,
          ),
        ),
      ],
    );
  }

  Widget _buildCardMetrica({
    required IconData icone,
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // card balanço hídrico
  Widget _buildCardBalanco() {
    final balanco = resultado.balanceHidricoMl;
    final positivo = balanco >= 0;
    final cor =
        positivo ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final icone =
        positivo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balanço hídrico da sessão',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  positivo
                      ? 'Ingestão superou a perda estimada'
                      : 'Déficit hídrico na sessão',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '${positivo ? '+' : ''}${balanco.toStringAsFixed(0)} mL',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  // card alertas
  Widget _buildCardAlertas() {
    // ordena por nível de severidade
    final alertasOrdenados = [...resultado.alertas]
      ..sort((a, b) => b.nivel.index.compareTo(a.nivel.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas clínicos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...alertasOrdenados.map((alerta) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildItemAlerta(alerta),
            )),
        if (resultado.encaminhamentoRecomendado)
          _buildBannerEncaminhamento(),
      ],
    );
  }

  Widget _buildItemAlerta(AlertaRisco alerta) {
    final cor = _corNivel(alerta.nivel);
    final icone = _iconeNivel(alerta.nivel);
    final labelNivel = _labelNivel(alerta.nivel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labelNivel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alerta.mensagem,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          if (alerta.orientacao != null) ...[
            const SizedBox(height: 6),
            Text(
              alerta.orientacao!,
              style:
                  const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerEncaminhamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFD32F2F).withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital_outlined,
              color: Color(0xFFD32F2F), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Encaminhamento para avaliação profissional recomendado com base nos alertas acima.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD32F2F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // card resumo de recomendação
  Widget _buildCardResumoRecomendacao(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaRecomendacoes(resultado: resultado),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC41230),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC41230).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recomendação de hidratação',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${resultado.ingestaoAlvoMlH.toStringAsFixed(0)} mL/h · '
                    'a cada ${resultado.intervaloIngestaoMin} min · '
                    '${resultado.volumePorDoseMl.toStringAsFixed(0)} mL/dose',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // botões de ação
  Widget _buildBotoesAcao(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Início'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFC41230)),
                foregroundColor: const Color(0xFFC41230),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TelaRecomendacoes(resultado: resultado),
                ),
              ),
              icon: const Icon(Icons.recommend_outlined),
              label: const Text('Ver recomendações',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC41230),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // helpers nível de risco
  NivelRisco _nivelGeralRisco() {
    if (resultado.alertas.isEmpty) return NivelRisco.normal;
    return resultado.alertas
        .map((a) => a.nivel)
        .reduce((a, b) => a.index > b.index ? a : b);
  }

  Color _corNivel(NivelRisco nivel) => switch (nivel) {
        NivelRisco.normal => const Color(0xFF2E7D32),
        NivelRisco.atencao => const Color(0xFFF9A825),
        NivelRisco.alerta => const Color(0xFFE65100),
        NivelRisco.critico => const Color(0xFFD32F2F),
      };

  IconData _iconeNivel(NivelRisco nivel) => switch (nivel) {
        NivelRisco.normal => Icons.check_circle_outline,
        NivelRisco.atencao => Icons.info_outline,
        NivelRisco.alerta => Icons.warning_amber_rounded,
        NivelRisco.critico => Icons.error_outline,
      };

  String _labelNivel(NivelRisco nivel) => switch (nivel) {
        NivelRisco.normal => 'Normal',
        NivelRisco.atencao => 'Atenção',
        NivelRisco.alerta => 'Alerta',
        NivelRisco.critico => 'Crítico',
      };

  String _labelNivelGeral(NivelRisco nivel) => switch (nivel) {
        NivelRisco.normal => 'Sessão dentro dos parâmetros normais',
        NivelRisco.atencao => 'Pontos de atenção identificados',
        NivelRisco.alerta => 'Alertas clínicos — avaliação recomendada',
        NivelRisco.critico => 'Situação crítica — atendimento imediato',
      };
}