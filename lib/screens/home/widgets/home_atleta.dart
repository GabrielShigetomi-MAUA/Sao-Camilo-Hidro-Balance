import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sessao.dart';
import '../../../models/usuario.dart';
import '../../../services/sessao_service.dart';
import '../../../theme/tema_app.dart';
import '../../sessao/tela_pre_sessao.dart';
import '../../sessao/tela_resultado_sessao.dart';

class HomeAtleta extends StatefulWidget {
  final Usuario usuario;
  const HomeAtleta({super.key, required this.usuario});

  @override
  State<HomeAtleta> createState() => _HomeAtletaState();
}

class _HomeAtletaState extends State<HomeAtleta> {
  final _sessaoService = SessaoService();

  // 0 = lista, 1 = por contexto
  int _abaAtiva = 0;

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
          StreamBuilder<EstatisticasResumidas>(
            stream: _sessaoService.streamEstatisticasResumidas(
              widget.usuario.uid,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('streamEstatisticas erro: ${snap.error}');
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
          ),
          const SizedBox(height: 24),

          // cabeçalho com toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _abaAtiva == 0 ? 'Últimas sessões' : 'Por contexto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              _ToggleVista(
                abaAtiva: _abaAtiva,
                onChanged: (v) => setState(() => _abaAtiva = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // conteúdo da aba
          if (_abaAtiva == 0)
            _ListaSessoes(
              sessaoService: _sessaoService,
              atletaUid: widget.usuario.uid,
            )
          else
            _ListaAgrupada(
              sessaoService: _sessaoService,
              atletaUid: widget.usuario.uid,
            ),
        ],
      ),
    );
  }
}

// toggle lista/contexto
class _ToggleVista extends StatelessWidget {
  final int abaAtiva;
  final ValueChanged<int> onChanged;
  const _ToggleVista({required this.abaAtiva, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotaoAba(
            label: 'Lista',
            icone: Icons.list_rounded,
            ativo: abaAtiva == 0,
            onTap: () => onChanged(0),
          ),
          _BotaoAba(
            label: 'Contexto',
            icone: Icons.category_outlined,
            ativo: abaAtiva == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _BotaoAba extends StatelessWidget {
  final String label;
  final IconData icone;
  final bool ativo;
  final VoidCallback onTap;
  const _BotaoAba({
    required this.label,
    required this.icone,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              size: 14,
              color: ativo ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
                color: ativo ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// aba lista
class _ListaSessoes extends StatelessWidget {
  final SessaoService sessaoService;
  final String atletaUid;
  const _ListaSessoes({required this.sessaoService, required this.atletaUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sessao>>(
      stream: sessaoService.streamSessoesConcluidas(atletaUid, limite: 5),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('streamSessoesConcluidas erro: ${snap.error}');
          return _PlaceholderSessoes();
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final sessoes = snap.data ?? [];
        if (sessoes.isEmpty) return _PlaceholderSessoes();
        return Column(
          children: sessoes.map((s) => _CardSessao(sessao: s)).toList(),
        );
      },
    );
  }
}

// aba por contexto
class _ListaAgrupada extends StatelessWidget {
  final SessaoService sessaoService;
  final String atletaUid;
  const _ListaAgrupada({required this.sessaoService, required this.atletaUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GrupoContexto>>(
      stream: sessaoService.streamGruposContexto(atletaUid),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('streamGruposContexto erro: ${snap.error}');
          return _PlaceholderSessoes();
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final grupos = snap.data ?? [];
        if (grupos.isEmpty) return _PlaceholderSessoes();
        return Column(
          children: grupos.map((g) => _CardGrupo(grupo: g)).toList(),
        );
      },
    );
  }
}

class _CardGrupo extends StatelessWidget {
  final GrupoContexto grupo;
  const _CardGrupo({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(grupo.ultimaSessao);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _labelModalidade(grupo.modalidade),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${grupo.totalSessoes} ${grupo.totalSessoes == 1 ? 'sessão' : 'sessões'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    icone: Icons.thermostat_outlined,
                    label: grupo.faixaTemperatura.label,
                  ),
                  _Chip(
                    icone: Icons.speed_outlined,
                    label: _labelIntensidade(grupo.intensidade),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 10),

              Row(
                children: [
                  _MiniMetrica(
                    label: 'Sudorese média',
                    valor: '${grupo.mediaSudoreseLh.toStringAsFixed(2)} L/h',
                  ),
                  const SizedBox(width: 16),
                  _MiniMetrica(
                    label: 'Variação média',
                    valor:
                        '${grupo.mediaVariacaoMassaPercent.toStringAsFixed(1)}%',
                  ),
                  const Spacer(),
                  Text(
                    'Última: $dataFormatada',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[400],
          ),
          children: [
            const Divider(height: 1, thickness: 0.5),
            ...grupo.sessoes.map((s) => _CardSessaoGrupo(sessao: s)),
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

  String _labelIntensidade(IntensidadeTreino i) => switch (i) {
    IntensidadeTreino.leve => 'Leve',
    IntensidadeTreino.moderada => 'Moderada',
    IntensidadeTreino.intensa => 'Intensa',
    IntensidadeTreino.muitoIntensa => 'Muito intensa',
  };
}

// item de sessão dentro do grupo expandido
class _CardSessaoGrupo extends StatelessWidget {
  final Sessao sessao;
  const _CardSessaoGrupo({required this.sessao});

  @override
  Widget build(BuildContext context) {
    final resultado = sessao.resultado;
    final data = DateFormat('dd/MM/yyyy · HH:mm').format(sessao.dataHoraInicio);

    return InkWell(
      onTap: resultado == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaResultadoSessao(
                  atletaUid: sessao.atletaUid,
                  sessaoId: sessao.id!,
                  resultado: resultado,
                  sessao: sessao,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            if (resultado != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${resultado.taxaSudoreseLh.toStringAsFixed(2)} L/h',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${resultado.variacaoMassaPercent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icone;
  final String label;
  const _Chip({required this.icone, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _MiniMetrica extends StatelessWidget {
  final String label;
  final String valor;
  const _MiniMetrica({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}

// widgets utilitários
class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
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

    return GestureDetector(
      onTap: resultado == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaResultadoSessao(
                  atletaUid: sessao.atletaUid,
                  sessaoId: sessao.id!,
                  resultado: resultado,
                  sessao: sessao,
                ),
              ),
            ),
      child: Container(
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
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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