import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sessao.dart';
import '../../../models/usuario.dart';
import '../../../services/sessao_service.dart';
import '../../../theme/tema_app.dart';
import '../../sessao/tela_pre_sessao.dart';

class HomeAtleta extends StatefulWidget {
  final Usuario usuario;
  const HomeAtleta({super.key, required this.usuario});

  @override
  State<HomeAtleta> createState() => _HomeAtletaState();
}

class _HomeAtletaState extends State<HomeAtleta> {
  final _sessaoService = SessaoService();
  late Future<EstatisticasResumidas> _estatisticasFuture;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  void _carregarEstatisticas() {
    _estatisticasFuture = _sessaoService.calcularEstatisticasResumidas(
      widget.usuario.uid,
    );
  }

  Future<void> _iniciarNovasSessao() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaPreSessao(
          atletaUid: widget.usuario.uid,
          codigoAtleta: widget.usuario.codigoAtleta,
        ),
      ),
    );
    if (mounted) {
      setState(() => _carregarEstatisticas());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardSaudacao(usuario: widget.usuario),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _iniciarNovasSessao,
            icon: const Icon(Icons.add),
            label: const Text('Iniciar nova sessão'),
          ),
          const SizedBox(height: 24),

          // cards de métricas
          FutureBuilder<EstatisticasResumidas>(
            future: _estatisticasFuture,
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('calcularEstatisticasResumidas erro: ${snap.error}');
              }
              final stats =
                  snap.data ??
                  const EstatisticasResumidas(
                    totalSessoes: 0,
                    mediaSudoreseLh: 0.0,
                    mediaVariacaoMassaPercent: 0.0,
                  );
              return _SessaoResumo(estatisticas: stats);
            },
          ), // FutureBuilder
          const SizedBox(height: 24),

          Text(
            'Últimas sessões',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // stream em tempo real das sessões concluídas
          StreamBuilder<List<Sessao>>(
            stream: _sessaoService.streamSessoesConcluidas(
              widget.usuario.uid,
              limite: 5,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('streamSessoesConcluidas erro: ${snap.error}');
                return _PlaceholderSessoes();
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final sessoes = snap.data ?? [];
              if (sessoes.isEmpty) return _PlaceholderSessoes();

              return Column(
                children: sessoes.map((s) => _CardSessao(sessao: s)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// card saudação
class _CardSaudacao extends StatelessWidget {
  final Usuario usuario;
  const _CardSaudacao({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final hora = DateTime.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
        ? 'Boa tarde'
        : 'Boa noite';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF961029)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$saudacao, ${usuario.nome.split(' ').first}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Código: ${usuario.codigoAtleta}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// cards métricas
class _SessaoResumo extends StatelessWidget {
  final EstatisticasResumidas estatisticas;
  const _SessaoResumo({required this.estatisticas});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CardMetrica(
          label: 'Sessões',
          valor: '${estatisticas.totalSessoes}',
          icone: Icons.fitness_center,
        ),
        const SizedBox(width: 12),
        _CardMetrica(
          label: 'Sudorese média',
          valor: '${estatisticas.mediaSudoreseLh.toStringAsFixed(2)} L/h',
          icone: Icons.water_drop_outlined,
        ),
        const SizedBox(width: 12),
        _CardMetrica(
          label: 'Variação média',
          valor:
              '${estatisticas.mediaVariacaoMassaPercent.toStringAsFixed(1)}%',
          icone: Icons.monitor_weight_outlined,
        ),
      ],
    );
  }
}

class _CardMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icone;
  const _CardMetrica({
    required this.label,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// lista de sessões
class _PlaceholderSessoes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Nenhuma sessão registrada ainda',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Inicie sua primeira sessão acima',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CardSessao extends StatelessWidget {
  final Sessao sessao;
  const _CardSessao({required this.sessao});

  @override
  Widget build(BuildContext context) {
    final resultado = sessao.resultado;
    final data = DateFormat('dd/MM/yyyy · HH:mm').format(sessao.dataHoraInicio);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: AppTheme.primaryColor,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '${resultado.variacaoMassaPercent.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
        ],
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
