import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/sessao.dart';
import '../../services/sessao_service.dart';
import 'tela_pos_sessao.dart';

class TelaDuranteSessao extends StatefulWidget {
  final String atletaUid;
  final String sessaoId;

  const TelaDuranteSessao({
    super.key,
    required this.atletaUid,
    required this.sessaoId,
  });

  @override
  State<TelaDuranteSessao> createState() => _TelaDuranteSessaoState();
}

class _TelaDuranteSessaoState extends State<TelaDuranteSessao> {
  final _sessaoService = SessaoService();

  // cronômetro
  late final DateTime _inicio;
  late final Timer _timer;
  Duration _decorrido = Duration.zero;

  // volume customizado
  final _volumeCustomController = TextEditingController();

  // atalhos de volume em mL
  static const _atalhos = [150, 250, 350, 500, 750];

  bool _encerrando = false;

  @override
  void initState() {
    super.initState();
      print('TelaDuranteSessao — atletaUid: ${widget.atletaUid}, sessaoId: ${widget.sessaoId}'); // <- adiciona aqui
    _inicio = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _decorrido = DateTime.now().difference(_inicio));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _volumeCustomController.dispose();
    super.dispose();
  }

  // formatação cronômetro
  String get _cronometroFormatado {
    final h = _decorrido.inHours.toString().padLeft(2, '0');
    final m = (_decorrido.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_decorrido.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // registro de ingestão
  Future<void> _registrarIngestao(double volumeMl, {String? descricao}) async {
    final ingestao = RegistroIngestao(
      horario: DateTime.now(),
      volumeMl: volumeMl,
      descricao: descricao,
    );

    await _sessaoService.adicionarIngestao(
      widget.atletaUid,
      widget.sessaoId,
      ingestao,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${volumeMl.toInt()} mL registrado às ${_horaFormatada(ingestao.horario)}',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _registrarIngestaoCustomizada() async {
    final texto = _volumeCustomController.text.trim();
    final volume = double.tryParse(texto.replaceAll(',', '.'));

    if (volume == null || volume <= 0 || volume > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um volume válido entre 1 e 2000 mL'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _volumeCustomController.clear();
    FocusScope.of(context).unfocus();
    await _registrarIngestao(volume, descricao: 'personalizado');
  }

  Future<void> _removerIngestao(
    Sessao sessao,
    RegistroIngestao ingestao,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover volume ingerido?'),
        content: Text(
          'Remover ${ingestao.volumeMl.toInt()} mL registrado às ${_horaFormatada(ingestao.horario)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC41230),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _sessaoService.removerIngestao(
        widget.atletaUid,
        widget.sessaoId,
        ingestao,
      );
    }
  }

  // encerramento
  Future<void> _encerrarSessao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar sessão?'),
        content: const Text(
          'Você será direcionado para o registro dos dados pós-treino.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar sessão'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC41230),
            ),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _encerrando = true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TelaPosSessao(
          atletaUid: widget.atletaUid,
          sessaoId: widget.sessaoId,
        ),
      ),
    );
  }

  Future<void> _cancelarSessao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar sessão?'),
        content: const Text(
          'Os dados coletados serão descartados. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: const Text('Cancelar sessão'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _sessaoService.cancelarSessao(widget.atletaUid, widget.sessaoId);

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // build principal
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelarSessao();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC41230),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text(
            'Sessão em andamento',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton.icon(
              onPressed: _cancelarSessao,
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              label: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        body: StreamBuilder<Sessao?>(
          stream: _sessaoService.streamSessao(
            widget.atletaUid,
            widget.sessaoId,
          ),
          builder: (context, snapshot) {
            final sessao = snapshot.data;
            return Column(
              children: [
                _buildCronometro(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumoIngestao(sessao),
                        const SizedBox(height: 16),
                        _buildAtalhosVolume(),
                        const SizedBox(height: 16),
                        _buildVolumeCustomizado(),
                        const SizedBox(height: 16),
                        if (sessao != null &&
                            sessao.registrosIngestao.isNotEmpty) ...[
                          _buildListaIngestoes(sessao),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBotaoEncerrar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // cronômetro
  Widget _buildCronometro() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFC41230),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          Text(
            _cronometroFormatado,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w200,
              letterSpacing: 4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'hh : mm : ss',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // resumo de ingestão
  Widget _buildResumoIngestao(Sessao? sessao) {
    final total = sessao?.totalIngeridoMl ?? 0.0;
    final quantidade = sessao?.registrosIngestao.length ?? 0;

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
          Expanded(
            child: _buildMetricaResumo(
              icone: Icons.water_drop,
              cor: const Color(0xFFC41230),
              valor: '${total.toInt()} mL',
              label: 'Total ingerido',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildMetricaResumo(
              icone: Icons.local_drink_outlined,
              cor: Colors.blue[600]!,
              valor: '$quantidade',
              label: quantidade == 1 ? 'Registro' : 'Registros',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildMetricaResumo(
              icone: Icons.timer_outlined,
              cor: Colors.green[600]!,
              valor: '${_decorrido.inMinutes} min',
              label: 'Decorrido',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaResumo({
    required IconData icone,
    required Color cor,
    required String valor,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 20),
        const SizedBox(height: 6),
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
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    );
  }

  // atalhos volume ingerido
  Widget _buildAtalhosVolume() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registrar ingestão',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: _atalhos.map((ml) {
            final label = ml >= 1000
                ? '${(ml / 1000).toStringAsFixed(1)} L'
                : '$ml mL';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: ml == _atalhos.last ? 0 : 8),
                child: _BotaoIngestao(
                  label: label,
                  sublabel: _descricaoAtalho(ml),
                  onTap: () => _registrarIngestao(
                    ml.toDouble(),
                    descricao: _descricaoAtalho(ml),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _descricaoAtalho(int ml) => switch (ml) {
    150 => 'Copo P',
    250 => 'Copo M',
    350 => 'Squeeze',
    500 => 'Garrafa P',
    750 => 'Garrafa M',
    _ => '',
  };

  // volume customizado
  Widget _buildVolumeCustomizado() {
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
          Expanded(
            child: TextField(
              controller: _volumeCustomController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Volume personalizado (mL)',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFC41230),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                labelStyle: const TextStyle(fontSize: 13),
              ),
              onSubmitted: (_) => _registrarIngestaoCustomizada(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _registrarIngestaoCustomizada,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC41230),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // lista de ingestões
  Widget _buildListaIngestoes(Sessao sessao) {
    final ingestoes = sessao.registrosIngestao.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingestões registradas',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ingestoes.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (_, i) {
              final ingestao = ingestoes[i];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC41230).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Color(0xFFC41230),
                    size: 18,
                  ),
                ),
                title: Text(
                  '${ingestao.volumeMl.toInt()} mL',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${ingestao.descricao ?? 'fluido'} · ${_horaFormatada(ingestao.horario)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => _removerIngestao(sessao, ingestao),
                  tooltip: 'Remover registro',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // botão encerrar
  Widget _buildBotaoEncerrar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
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
          onPressed: _encerrando ? null : _encerrarSessao,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text(
            'Encerrar sessão',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC41230),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  String _horaFormatada(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// widget auxiliar botão atalho de volume
class _BotaoIngestao extends StatefulWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _BotaoIngestao({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  State<_BotaoIngestao> createState() => _BotaoIngestaState();
}

class _BotaoIngestaState extends State<_BotaoIngestao>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _escala = Tween(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC41230).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.water_drop, color: const Color(0xFFC41230), size: 20),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC41230),
                ),
              ),
              Text(
                widget.sublabel,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
