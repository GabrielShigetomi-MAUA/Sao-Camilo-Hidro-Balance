import 'package:flutter/material.dart';
import '../../models/sessao.dart';

class TelaRecomendacoes extends StatelessWidget {
  final ResultadoSessao resultado;

  const TelaRecomendacoes({
    super.key,
    required this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC41230),
        foregroundColor: Colors.white,
        title: const Text('Recomendações',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardAlvoIngestao(),
                  const SizedBox(height: 16),
                  _buildCardFracionamento(),
                  const SizedBox(height: 16),
                  _buildCardOrientacoesPraticas(),
                  if (resultado.encaminhamentoRecomendado) ...[
                    const SizedBox(height: 16),
                    _buildCardEncaminhamento(),
                  ],
                  if (resultado.alertas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCardAlertas(),
                  ],
                  const SizedBox(height: 16),
                  _buildCardProximaSessao(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBotaoVoltar(context),
        ],
      ),
    );
  }

  // header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFC41230),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resultado.ingestaoAlvoMlH.toStringAsFixed(0)} mL/h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'meta de ingestão para a próxima sessão',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // card alvo ingestão
  Widget _buildCardAlvoIngestao() {
    final taxaLh = resultado.taxaSudoreseLh;
    final alvoMlH = resultado.ingestaoAlvoMlH;

    return _buildCard(
      icone: Icons.local_drink_outlined,
      titulo: 'Alvo de ingestão',
      children: [
        _buildLinhaMetrica(
          label: 'Taxa de sudorese estimada',
          valor: '${taxaLh.toStringAsFixed(2)} L/h',
          cor: const Color(0xFFC41230),
        ),
        const SizedBox(height: 10),
        _buildLinhaMetrica(
          label: 'Ingestão alvo (80% da perda)',
          valor: '${alvoMlH.toStringAsFixed(0)} mL/h',
          cor: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF1565C0), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A meta de reposição é 80% da taxa de sudorese — '
                  'repor 100% aumenta o risco de hiperidratação '
                  'durante exercícios prolongados.',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // card fracionamento
  Widget _buildCardFracionamento() {
    return _buildCard(
      icone: Icons.schedule_outlined,
      titulo: 'Como distribuir a ingestão',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildItemFracionamento(
                icone: Icons.timer_outlined,
                valor:
                    '${resultado.intervaloIngestaoMin} min',
                label: 'intervalo',
                cor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildItemFracionamento(
                icone: Icons.local_drink_outlined,
                valor:
                    '${resultado.volumePorDoseMl.toStringAsFixed(0)} mL',
                label: 'por dose',
                cor: const Color(0xFFC41230),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildItemFracionamento(
                icone: Icons.repeat_outlined,
                valor: _frequenciaPorHora(),
                label: 'doses/hora',
                cor: const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildExemploFracionamento(),
      ],
    );
  }

  Widget _buildItemFracionamento({
    required IconData icone,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildExemploFracionamento() {
    final intervalo = resultado.intervaloIngestaoMin;
    final dose = resultado.volumePorDoseMl.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exemplo prático',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 14, color: Colors.black38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'A cada $intervalo minutos, ingira $dose mL '
                  '(aproximadamente ${_descricaoVolume(double.parse(dose))})',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // card orientações
  Widget _buildCardOrientacoesPraticas() {
    final orientacoes = _gerarOrientacoesPraticas();

    return _buildCard(
      icone: Icons.tips_and_updates_outlined,
      titulo: 'Orientações práticas',
      children: orientacoes.asMap().entries.map((entry) {
        final ultimo = entry.key == orientacoes.length - 1;
        return Column(
          children: [
            _buildItemOrientacao(entry.value),
            if (!ultimo) const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildItemOrientacao(_OrientacaoPratica orientacao) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: orientacao.cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(orientacao.icone, color: orientacao.cor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orientacao.titulo,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                orientacao.descricao,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // card encaminhamento
  Widget _buildCardEncaminhamento() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFD32F2F).withOpacity(0.3),
            width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined,
                  color: Color(0xFFD32F2F), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Encaminhamento recomendado',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Com base nos alertas identificados nesta sessão, '
            'recomenda-se avaliação por nutricionista esportivo '
            'ou médico do esporte antes de retomar atividades de '
            'alta intensidade.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text(
            'Profissionais indicados:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black45),
          ),
          const SizedBox(height: 6),
          ...[
            'Nutricionista esportivo',
            'Médico do esporte',
            'Fisiologista do exercício',
          ].map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 5, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 8),
                    Text(p,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // card alertas
  Widget _buildCardAlertas() {
    final alertasCriticos = resultado.alertas
        .where((a) =>
            a.nivel == NivelRisco.alerta ||
            a.nivel == NivelRisco.critico)
        .toList();

    if (alertasCriticos.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      icone: Icons.warning_amber_rounded,
      titulo: 'Alertas desta sessão',
      children: alertasCriticos.map((alerta) {
        final cor = alerta.nivel == NivelRisco.critico
            ? const Color(0xFFD32F2F)
            : const Color(0xFFE65100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: cor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alerta.mensagem,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // card proxima sessão
  Widget _buildCardProximaSessao() {
    return _buildCard(
      icone: Icons.event_outlined,
      titulo: 'Para a próxima sessão',
      children: [
        _buildItemOrientacao(_OrientacaoPratica(
          icone: Icons.wb_sunny_outlined,
          cor: const Color(0xFFF57F17),
          titulo: 'Hidratação pré-treino',
          descricao:
              'Ingira 400–600 mL de água nas 2–3 horas anteriores ao exercício.',
        )),
        const SizedBox(height: 10),
        _buildItemOrientacao(_OrientacaoPratica(
          icone: Icons.monitor_weight_outlined,
          cor: const Color(0xFF1565C0),
          titulo: 'Verifique o estado de hidratação',
          descricao:
              'Esvazie a bexiga e pese-se antes de iniciar. '
              'Urina amarelo pálido indica boa hidratação basal.',
        )),
        const SizedBox(height: 10),
        _buildItemOrientacao(_OrientacaoPratica(
          icone: Icons.local_drink_outlined,
          cor: const Color(0xFF2E7D32),
          titulo: 'Prepare os fluidos',
          descricao:
              'Tenha disponível ${(resultado.ingestaoAlvoMlH * 2).toStringAsFixed(0)} mL '
              'para uma sessão de 2 horas com o mesmo perfil de esforço.',
        )),
      ],
    );
  }

  // botão voltar
  Widget _buildBotaoVoltar(BuildContext context) {
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Voltar ao início',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC41230),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  // widgets reutilizáveis
  Widget _buildCard({
    required IconData icone,
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFC41230).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone,
                    color: const Color(0xFFC41230), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLinhaMetrica({
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.black54)),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cor,
          ),
        ),
      ],
    );
  }

  // helpers
  String _frequenciaPorHora() {
    final freq = 60 / resultado.intervaloIngestaoMin;
    return freq == freq.roundToDouble()
        ? '${freq.toInt()}x'
        : '${freq.toStringAsFixed(1)}x';
  }

  String _descricaoVolume(double ml) {
    if (ml <= 150) return 'um copo pequeno';
    if (ml <= 250) return 'um squeeze';
    if (ml <= 350) return 'um copo grande';
    if (ml <= 500) return 'uma garrafa pequena';
    return 'uma garrafa média';
  }

  List<_OrientacaoPratica> _gerarOrientacoesPraticas() {
    final taxa = resultado.taxaSudoreseLh;
    final variacao = resultado.variacaoMassaPercent;
    final orientacoes = <_OrientacaoPratica>[];

    // orientação bebida isotônica
    if (taxa >= 1.5) {
      orientacoes.add(_OrientacaoPratica(
        icone: Icons.science_outlined,
        cor: const Color(0xFF00838F),
        titulo: 'Considere bebida isotônica',
        descricao:
            'Com taxa de sudorese acima de 1,5 L/h, a reposição de '
            'eletrólitos (sódio, potássio) pode ser indicada — '
            'especialmente em sessões acima de 60 minutos.',
      ));
    }

    // orientação reidratação
    if (variacao < -1.0) {
      final reposicaoMl =
          (variacao.abs() / 100 * 70 * 1000 * 1.5).toStringAsFixed(0);
      orientacoes.add(_OrientacaoPratica(
        icone: Icons.restore_outlined,
        cor: const Color(0xFF1565C0),
        titulo: 'Reidratação pós-sessão',
        descricao:
            'Para repor o déficit desta sessão, ingira '
            'aproximadamente $reposicaoMl mL nas próximas 4–6 horas.',
      ));
    }

    // orientação temperatura
    orientacoes.add(_OrientacaoPratica(
      icone: Icons.thermostat_outlined,
      cor: const Color(0xFFE65100),
      titulo: 'Temperatura dos fluidos',
      descricao:
          'Fluidos frescos (15–22°C) são absorvidos mais rapidamente '
          'e ajudam a regular a temperatura corporal durante o exercício.',
    ));

    // orientação geral de monitoramento
    orientacoes.add(_OrientacaoPratica(
      icone: Icons.monitor_heart_outlined,
      cor: const Color(0xFF2E7D32),
      titulo: 'Monitore sinais de alerta',
      descricao:
          'Interrompa o exercício se sentir tontura, confusão mental, '
          'náusea intensa ou parar de suar em ambiente quente.',
    ));

    return orientacoes;
  }
}

class _OrientacaoPratica {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;

  const _OrientacaoPratica({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
  });
}