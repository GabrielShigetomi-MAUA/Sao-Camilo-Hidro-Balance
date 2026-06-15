import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sessao.dart';
import '../../services/sessao_service.dart';
import 'tela_resultado_sessao.dart';

class TelaPosSessao extends StatefulWidget {
  final String atletaUid;
  final String sessaoId;

  const TelaPosSessao({
    super.key,
    required this.atletaUid,
    required this.sessaoId,
  });

  @override
  State<TelaPosSessao> createState() => _TelaPosSessaoState();
}

class _TelaPosSessaoState extends State<TelaPosSessao> {
  final _formKey = GlobalKey<FormState>();
  final _sessaoService = SessaoService();

  // controladores
  final _massaPosController = TextEditingController();
  final _volumeUrinarioController = TextEditingController();

  // vestimenta
  bool _roupaEncarcada = false;
  bool _trocouVestimenta = false;

  // sintomas
  bool _sintomaGI = false;
  bool _sintomaFadiga = false;

  // tolerância ao plano hídrico
  int _tolerancia = 3;

  bool _salvando = false;

  @override
  void dispose() {
    _massaPosController.dispose();
    _volumeUrinarioController.dispose();
    super.dispose();
  }

  // submissão
  Future<void> _finalizar() async {
    if (!_formKey.currentState!.validate()) return;

    // alerta roupa encharcada (impacto na medida)
    if (_roupaEncarcada) {
      final continuar = await _mostrarAlertaRoupaEncarcada();
      if (continuar != true) return;
    }

    setState(() => _salvando = true);

    try {
      final dadosPos = DadosPosSessao(
        massaCorporalKg: double.parse(
          _massaPosController.text.replaceAll(',', '.'),
        ),
        roupaEncarcada: _roupaEncarcada,
        trocouVestimenta: _trocouVestimenta,
        volumeUrinarioMl: _volumeUrinarioController.text.isEmpty
            ? 0.0
            : double.parse(_volumeUrinarioController.text.replaceAll(',', '.')),
        sintomaGastrointestinal: _sintomaGI,
        sintomaFadiga: _sintomaFadiga,
        toleranciaPlanoHidrico: _tolerancia,
      );

      final sessaoFinalizada = await _sessaoService.finalizarSessao(
        widget.atletaUid,
        widget.sessaoId,
        dadosPos,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TelaResultadoSessao(
            atletaUid: widget.atletaUid,
            sessaoId: widget.sessaoId,
            resultado: sessaoFinalizada.resultado!,
            sessao: sessaoFinalizada,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar sessão: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<bool?> _mostrarAlertaRoupaEncarcada() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text('Atenção à medida'),
          ],
        ),
        content: const Text(
          'Roupa muito encharcada pode adicionar até 0,5–1 kg à pesagem, '
          'subestimando a taxa de sudorese real. O resultado será calculado '
          'com um alerta sobre esse impacto.\n\nDeseja continuar mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar pesagem'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC41230),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // build principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC41230),
        foregroundColor: Colors.white,
        title: const Text(
          'Dados pós-sessão',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardPesagem(),
                    const SizedBox(height: 16),
                    _buildCardVestimenta(),
                    const SizedBox(height: 16),
                    _buildCardSintomas(),
                    const SizedBox(height: 16),
                    _buildCardTolerancia(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildBotaoFinalizar(),
          ],
        ),
      ),
    );
  }

  // header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFC41230),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sessão encerrada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Preencha os dados finais para calcular o resultado',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // card de pesagem
  Widget _buildCardPesagem() {
    return _buildCard(
      icone: Icons.monitor_weight_outlined,
      titulo: 'Pesagem pós-treino',
      subtitulo: 'Nas mesmas condições da pesagem inicial',
      children: [
        _buildCampoNumerico(
          controller: _massaPosController,
          label: 'Massa corporal pós-treino (kg)',
          icone: Icons.scale_outlined,
          casasDecimais: true,
          validar: (v) {
            if (v == null || v.isEmpty) return 'Campo obrigatório';
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null) return 'Valor inválido';
            if (val < 30 || val > 200) {
              return 'Valor fora do intervalo esperado (30–200 kg)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildCampoNumerico(
          controller: _volumeUrinarioController,
          label: 'Volume urinário durante a sessão (mL)',
          icone: Icons.water_outlined,
          casasDecimais: false,
          opcional: true,
          validar: (v) {
            if (v == null || v.isEmpty) return null;
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null) return 'Valor inválido';
            if (val < 0 || val > 2000) {
              return 'Valor fora do intervalo esperado';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        _buildDicaInfo(
          'Se não houve micção durante a sessão, deixe o campo em branco.',
        ),
      ],
    );
  }

  // card vestimenta
  Widget _buildCardVestimenta() {
    return _buildCard(
      icone: Icons.checkroom_outlined,
      titulo: 'Vestimenta',
      children: [
        _buildSwitchItem(
          label: 'Roupa muito encharcada',
          subtitulo: 'Pode impactar a precisão da pesagem final',
          valor: _roupaEncarcada,
          icone: Icons.water_drop_outlined,
          corIcone: Colors.blue[600]!,
          onChanged: (v) => setState(() => _roupaEncarcada = v),
        ),
        const Divider(height: 20),
        _buildSwitchItem(
          label: 'Trocou de vestimenta durante a sessão',
          subtitulo: 'Pode introduzir variação na medida de massa',
          valor: _trocouVestimenta,
          icone: Icons.swap_horiz_outlined,
          corIcone: Colors.orange[600]!,
          onChanged: (v) => setState(() => _trocouVestimenta = v),
        ),
        if (_roupaEncarcada || _trocouVestimenta) ...[
          const SizedBox(height: 12),
          _buildAlertaAviso(
            'O resultado será calculado com um alerta sobre o impacto na precisão da medida.',
          ),
        ],
      ],
    );
  }

  // card sintomas
  Widget _buildCardSintomas() {
    return _buildCard(
      icone: Icons.health_and_safety_outlined,
      titulo: 'Sintomas pós-sessão',
      subtitulo: 'Marque os sintomas apresentados após o exercício',
      children: [
        _buildSwitchItem(
          label: 'Sintoma gastrointestinal',
          subtitulo: 'Náusea, vômito, dor abdominal ou diarreia',
          valor: _sintomaGI,
          icone: Icons.sick_outlined,
          corIcone: Colors.red[400]!,
          onChanged: (v) => setState(() => _sintomaGI = v),
        ),
        const Divider(height: 20),
        _buildSwitchItem(
          label: 'Fadiga acentuada',
          subtitulo: 'Cansaço desproporcional ao esforço realizado',
          valor: _sintomaFadiga,
          icone: Icons.battery_alert_outlined,
          corIcone: Colors.orange[700]!,
          onChanged: (v) => setState(() => _sintomaFadiga = v),
        ),
      ],
    );
  }

  // card tolerância
  Widget _buildCardTolerancia() {
    const labels = [
      'Não seguiu',
      'Seguiu pouco',
      'Seguiu parcialmente',
      'Seguiu bem',
      'Seguiu totalmente',
    ];

    const cores = [
      Color(0xFFD32F2F),
      Color(0xFFFF7043),
      Color(0xFFFFA726),
      Color(0xFF66BB6A),
      Color(0xFF2E7D32),
    ];

    return _buildCard(
      icone: Icons.tune_outlined,
      titulo: 'Tolerância ao plano hídrico',
      subtitulo: 'Como o atleta seguiu as orientações de ingestão',
      children: [
        Row(
          children: List.generate(5, (i) {
            final nivel = i + 1;
            final ativo = _tolerancia == nivel;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tolerancia = nivel),
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: ativo ? cores[i] : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: ativo
                          ? Border.all(color: cores[i], width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$nivel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ativo ? Colors.white : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            labels[_tolerancia - 1],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: [
                const Color(0xFFD32F2F),
                const Color(0xFFFF7043),
                const Color(0xFFFFA726),
                const Color(0xFF66BB6A),
                const Color(0xFF2E7D32),
              ][_tolerancia - 1],
            ),
          ),
        ),
      ],
    );
  }

  // botao finalizar
  Widget _buildBotaoFinalizar() {
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
          onPressed: _salvando ? null : _finalizar,
          icon: _salvando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calculate_outlined),
          label: Text(
            _salvando ? 'Calculando...' : 'Calcular resultado',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  // widgets reutilizaveis
  Widget _buildCard({
    required IconData icone,
    required String titulo,
    String? subtitulo,
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
                child: Icon(icone, color: const Color(0xFFC41230), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    required bool casasDecimais,
    required String? Function(String?) validar,
    bool opcional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: opcional ? '$label (opcional)' : label,
        prefixIcon: Icon(icone, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC41230), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 14),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: casasDecimais),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(casasDecimais ? r'[\d,.]' : r'\d'),
        ),
      ],
      validator: validar,
    );
  }

  Widget _buildSwitchItem({
    required String label,
    required String subtitulo,
    required bool valor,
    required IconData icone,
    required Color corIcone,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: corIcone.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icone, color: corIcone, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeColor: const Color(0xFFC41230),
        ),
      ],
    );
  }

  Widget _buildDicaInfo(String mensagem) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            mensagem,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertaAviso(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(fontSize: 11, color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }
}
