import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sessao.dart';
import '../../../models/vinculo.dart';
import '../../../services/sessao_service.dart';
import '../../../theme/tema_app.dart';
import '../../sessao/tela_resultado_sessao.dart';

class TelaHistoricoAtleta extends StatelessWidget {
  final Vinculo vinculo;

  const TelaHistoricoAtleta({super.key, required this.vinculo});

  @override
  Widget build(BuildContext context) {
    final sessaoService = SessaoService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vinculo.nomeAtleta,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              vinculo.codigoAtleta,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<Sessao>>(
        stream: sessaoService.streamSessoesConcluidas(
          vinculo.atletaUid,
          limite: 20,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('TelaHistoricoAtleta erro: ${snapshot.error}');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Erro ao carregar sessões.',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final sessoes = snapshot.data ?? [];

          if (sessoes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma sessão registrada ainda',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CardSessaoProfissional(
              sessao: sessoes[index],
              atletaUid: vinculo.atletaUid,
            ),
          );
        },
      ),
    );
  }
}

class _CardSessaoProfissional extends StatelessWidget {
  final Sessao sessao;
  final String atletaUid;

  const _CardSessaoProfissional({
    required this.sessao,
    required this.atletaUid,
  });

  @override
  Widget build(BuildContext context) {
    final resultado = sessao.resultado;
    final data = DateFormat('dd/MM/yyyy · HH:mm').format(sessao.dataHoraInicio);
    final temAlerta = resultado != null &&
        resultado.alertas.any((a) =>
            a.nivel == NivelRisco.alerta || a.nivel == NivelRisco.critico);

    return GestureDetector(
      onTap: resultado == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaResultadoSessao(
                    atletaUid: atletaUid,
                    sessaoId: sessao.id!,
                    resultado: resultado,
                    sessao: sessao,
                  ),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: temAlerta
                ? const Color(0xFFD32F2F).withOpacity(0.35)
                : Colors.grey.shade200,
            width: temAlerta ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: temAlerta
                    ? const Color(0xFFD32F2F).withOpacity(0.08)
                    : AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                temAlerta
                    ? Icons.warning_amber_rounded
                    : Icons.water_drop_outlined,
                color: temAlerta
                    ? const Color(0xFFD32F2F)
                    : AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelModalidade(sessao.modalidade),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (resultado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${resultado.taxaSudoreseLh.toStringAsFixed(2)} L/h',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: temAlerta
                          ? const Color(0xFFD32F2F)
                          : AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${resultado.variacaoMassaPercent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  String _labelModalidade(ModalidadeEsportiva m) => switch (m) {
        ModalidadeEsportiva.corrida => 'Corrida',
        ModalidadeEsportiva.ciclismo => 'Ciclismo',
        ModalidadeEsportiva.natacao => 'Natação',
        ModalidadeEsportiva.futebol => 'Futebol',
        ModalidadeEsportiva.basquete => 'Basquete',
        ModalidadeEsportiva.volei => 'Vôlei',
        ModalidadeEsportiva.tenis => 'Tênis',
        ModalidadeEsportiva.musculacao => 'Musculação',
        ModalidadeEsportiva.crossfit => 'CrossFit',
        ModalidadeEsportiva.outro => 'Outro',
      };
}