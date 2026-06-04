import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../theme/tema_app.dart';
import '../../sessao/tela_pre_sessao.dart';

class HomeAtleta extends StatelessWidget {
  final Usuario usuario;
  const HomeAtleta({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // saudação
          _CardSaudacao(usuario: usuario),
          const SizedBox(height: 20),

          // botão nova sessão
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaPreSessao(
                    atletaUid: usuario.uid,
                    codigoAtleta: usuario.codigoAtleta,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Iniciar nova sessão'),
          ),
          const SizedBox(height: 24),

          // resumo de métricas
          _SessaoResumo(usuario: usuario),
          const SizedBox(height: 24),

          // últimas sessões (placeholder por enquanto)
          Text(
            'Últimas sessões',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _PlaceholderSessoes(),
        ],
      ),
    );
  }
}

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

class _SessaoResumo extends StatelessWidget {
  final Usuario usuario;
  const _SessaoResumo({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final resumo = usuario.resumo;
    final totalSessoes = resumo['totalSessoes'] ?? 0;
    final taxaMedia = (resumo['taxaSudorMediaL_h'] ?? 0.0) as double;
    final variacaoMedia = (resumo['mediaVariacaoMassaPct'] ?? 0.0) as double;

    return Row(
      children: [
        _CardMetrica(
          label: 'Sessões',
          valor: '$totalSessoes',
          icone: Icons.fitness_center,
        ),
        const SizedBox(width: 12),
        _CardMetrica(
          label: 'Sudorese média',
          valor: '${taxaMedia.toStringAsFixed(2)} L/h',
          icone: Icons.water_drop_outlined,
        ),
        const SizedBox(width: 12),
        _CardMetrica(
          label: 'Variação média',
          valor: '${variacaoMedia.toStringAsFixed(1)}%',
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
