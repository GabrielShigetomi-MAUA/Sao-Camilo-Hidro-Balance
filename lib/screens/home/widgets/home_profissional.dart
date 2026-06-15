import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/vinculo.dart';
import '../../../services/vinculo_service.dart';
import '../../../theme/tema_app.dart';

class HomeProfissional extends StatefulWidget {
  final Usuario usuario;
  const HomeProfissional({super.key, required this.usuario});

  @override
  State<HomeProfissional> createState() => _HomeProfissionalState();
}

class _HomeProfissionalState extends State<HomeProfissional> {
  final _vinculoService = VinculoService();

  // vínculo por código
  Future<void> _mostrarDialogoVincular() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool salvando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Vincular atleta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite o código do atleta para criar o vínculo. '
                  'O atleta pode encontrar seu código na tela inicial do app.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código do atleta',
                    hintText: 'Ex: ATL-BQG9SM',
                    prefixIcon: const Icon(Icons.qr_code_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o código do atleta';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateDialog(() => salvando = true);
                      try {
                        await _vinculoService.vincularPorCodigo(
                          codigoAtleta: controller.text,
                          profissional: widget.usuario,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _mostrarSucesso('Atleta vinculado com sucesso!');
                        }
                      } on ArgumentError catch (e) {
                        setStateDialog(() => salvando = false);
                        _mostrarErro(e.message);
                      } catch (_) {
                        setStateDialog(() => salvando = false);
                        _mostrarErro(
                          'Erro ao vincular atleta. Tente novamente.',
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: salvando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Vincular'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // build principal
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardSaudacao(),
          const SizedBox(height: 20),
          _buildBotaoVincular(),
          const SizedBox(height: 24),
          _buildPainelAtletas(),
        ],
      ),
    );
  }

  // card saudação
  Widget _buildCardSaudacao() {
    final hora = DateTime.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
        ? 'Boa tarde'
        : 'Boa noite';
    final labelPerfil = _labelPerfil(widget.usuario.perfil);

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
            '$saudacao, ${widget.usuario.nome.split(' ').first}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                labelPerfil,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // botão vincular
  Widget _buildBotaoVincular() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _mostrarDialogoVincular,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Vincular novo atleta'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // painel de atletas
  Widget _buildPainelAtletas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atletas vinculados',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Vinculo>>(
          stream: _vinculoService.streamAtletasVinculados(widget.usuario.uid),
          builder: (context, snapshot) {
            debugPrint('=== STREAM VINCULOS ===');
            debugPrint('connectionState: ${snapshot.connectionState}');
            debugPrint('hasError: ${snapshot.hasError}');
            debugPrint('error: ${snapshot.error}');
            debugPrint('data: ${snapshot.data}');
            debugPrint('data length: ${snapshot.data?.length}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            }

            final vinculos = snapshot.data ?? [];

            if (vinculos.isEmpty) {
              return _buildPlaceholderVazio();
            }

            return _ListaAtletasVinculados(
              vinculos: vinculos,
              profissionalUid: widget.usuario.uid,
              onEncerrar: (vinculo) => _confirmarEncerramento(vinculo),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlaceholderVazio() {
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
          Icon(Icons.group_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Nenhum atleta vinculado ainda',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Use o botão acima para vincular um atleta pelo código',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEncerramento(Vinculo vinculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar vínculo?'),
        content: Text(
          'Deseja encerrar o vínculo com ${vinculo.nomeAtleta}? '
          'Você não terá mais acesso às sessões deste atleta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _vinculoService.encerrarVinculo(vinculo.id!);
      _mostrarSucesso('Vínculo encerrado.');
    }
  }

  String _labelPerfil(String perfil) => switch (perfil) {
    'nutricionista' => 'Nutricionista',
    'treinador' => 'Treinador',
    'medico' => 'Médico',
    _ => perfil,
  };
}

// lista de atletas e carregamento das ultimas sessões
class _ListaAtletasVinculados extends StatefulWidget {
  final List<Vinculo> vinculos;
  final String profissionalUid;
  final ValueChanged<Vinculo> onEncerrar;

  const _ListaAtletasVinculados({
    required this.vinculos,
    required this.profissionalUid,
    required this.onEncerrar,
  });

  @override
  State<_ListaAtletasVinculados> createState() =>
      _ListaAtletasVinculadosState();
}

class _ListaAtletasVinculadosState extends State<_ListaAtletasVinculados> {
  List<ResumoAtletaVinculado>? _resumos;

  @override
  void initState() {
    super.initState();
    _carregarResumos();
  }

  @override
  void didUpdateWidget(_ListaAtletasVinculados old) {
    super.didUpdateWidget(old);
    if (old.vinculos != widget.vinculos) _carregarResumos();
  }

  Future<void> _carregarResumos() async {
    final resumos = await Future.wait(
      widget.vinculos.map(
        (v) => ResumoAtletaVinculado.carregar(v, FirebaseFirestore.instance),
      ),
    );
    if (mounted) setState(() => _resumos = resumos);
  }

  @override
  Widget build(BuildContext context) {
    final resumos = _resumos;

    if (resumos == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    // Alertas primeiro
    final ordenados = [...resumos]
      ..sort((a, b) => (b.temAlerta ? 1 : 0) - (a.temAlerta ? 1 : 0));

    return Column(
      children: ordenados
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CardAtleta(
                resumo: r,
                onEncerrar: () => widget.onEncerrar(r.vinculo),
              ),
            ),
          )
          .toList(),
    );
  }
}

// card atleta vinculado
class _CardAtleta extends StatelessWidget {
  final ResumoAtletaVinculado resumo;
  final VoidCallback onEncerrar;

  const _CardAtleta({required this.resumo, required this.onEncerrar});

  @override
  Widget build(BuildContext context) {
    final vinculo = resumo.vinculo;
    final sessao = resumo.ultimaSessao;
    final temAlerta = resumo.temAlerta;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: temAlerta
              ? const Color(0xFFD32F2F).withOpacity(0.4)
              : Colors.grey.shade200,
          width: temAlerta ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: temAlerta
                      ? const Color(0xFFD32F2F).withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  temAlerta
                      ? Icons.warning_amber_rounded
                      : Icons.person_outlined,
                  color: temAlerta
                      ? const Color(0xFFD32F2F)
                      : AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vinculo.nomeAtleta,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      vinculo.codigoAtleta,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                onSelected: (v) {
                  if (v == 'encerrar') onEncerrar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'encerrar',
                    child: Row(
                      children: [
                        Icon(Icons.link_off, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Encerrar vínculo',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (temAlerta) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFD32F2F),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alerta na última sessão — avaliação recomendada',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (sessao != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricaMini(
                  icone: Icons.water_drop_outlined,
                  valor:
                      '${sessao.resultado?.taxaSudoreseLh.toStringAsFixed(2) ?? '--'} L/h',
                  label: 'sudorese',
                ),
                const SizedBox(width: 16),
                _buildMetricaMini(
                  icone: Icons.monitor_weight_outlined,
                  valor:
                      '${sessao.resultado?.variacaoMassaPercent.toStringAsFixed(1) ?? '--'}%',
                  label: 'variação',
                ),
                const SizedBox(width: 16),
                _buildMetricaMini(
                  icone: Icons.calendar_today_outlined,
                  valor: _dataFormatada(sessao.dataHoraInicio),
                  label: 'última sessão',
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Nenhuma sessão registrada ainda',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricaMini({
    required IconData icone,
    required String valor,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icone, size: 13, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ],
        ),
      ],
    );
  }

  String _dataFormatada(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}';
  }
}
