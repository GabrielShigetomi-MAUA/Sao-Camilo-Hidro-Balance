import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sessao.dart';
import '../../services/sessao_service.dart';
import 'tela_durante_sessao.dart';

class TelaPreSessao extends StatefulWidget {
  final String atletaUid;
  final String codigoAtleta;

  const TelaPreSessao({
    super.key,
    required this.atletaUid,
    required this.codigoAtleta,
  });

  @override
  State<TelaPreSessao> createState() => _TelaPreSessaoState();
}

class _TelaPreSessaoState extends State<TelaPreSessao> {
  final _formKey = GlobalKey<FormState>();
  final _sessaoService = SessaoService();

  // etapa atual
  int _etapaAtual = 0;
  bool _salvando = false;

  // controladores de texto
  final _massaController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _umidadeController = TextEditingController();
  final _ventoController = TextEditingController();
  final _duracaoController = TextEditingController();
  final _hidratacaoRecenteController = TextEditingController();

  // estado dos campos de seleção
  ModalidadeEsportiva _modalidade = ModalidadeEsportiva.corrida;
  IntensidadeTreino _intensidade = IntensidadeTreino.moderada;
  TipoVestimenta _vestimenta = TipoVestimenta.minima;
  ExposicaoSolar _exposicaoSolar = ExposicaoSolar.solParcial;
  CorUrina _corUrina = CorUrina.amareloClaro2;
  int _nivelSede = 2;
  bool _sintomaPrevio = false;
  final _sintomDescController = TextEditingController();

  // checklist obrigatória
  bool _checkBexiga = false;
  bool _checkMesmaBalanca = false;
  bool _checkVestimentaPadrao = false;

  bool get _checklistCompleto =>
      _checkBexiga && _checkMesmaBalanca && _checkVestimentaPadrao;

  // etapas do formulário
  static const _etapas = ['Pesagem', 'Ambiente', 'Sessão', 'Estado basal'];

  @override
  void dispose() {
    _massaController.dispose();
    _temperaturaController.dispose();
    _umidadeController.dispose();
    _ventoController.dispose();
    _duracaoController.dispose();
    _hidratacaoRecenteController.dispose();
    _sintomDescController.dispose();
    super.dispose();
  }

  // navegação entre etapas
  void _avancar() {
    if (_etapaAtual < _etapas.length - 1) {
      setState(() => _etapaAtual++);
    } else {
      _iniciarSessao();
    }
  }

  void _voltar() {
    if (_etapaAtual > 0) setState(() => _etapaAtual--);
  }

  // submissão
  Future<void> _iniciarSessao() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_checklistCompleto) {
      _mostrarErroChecklist();
      return;
    }

    setState(() => _salvando = true);

    try {
      final sessao = Sessao(
        atletaUid: widget.atletaUid,
        codigoAtleta: widget.codigoAtleta,
        dataHoraInicio: DateTime.now(),
        status: StatusSessao.emAndamento,
        massaPreKg: double.parse(_massaController.text.replaceAll(',', '.')),
        modalidade: _modalidade,
        intensidade: _intensidade,
        duracaoPrevistaMin: int.parse(_duracaoController.text),
        vestimenta: _vestimenta,
        condicoesAmbientais: CondicoesAmbientais(
          temperaturaC:
              double.parse(_temperaturaController.text.replaceAll(',', '.')),
          umidadeRelativa:
              double.parse(_umidadeController.text.replaceAll(',', '.')),
          velocidadeVentoKmh:
              double.parse(_ventoController.text.replaceAll(',', '.')),
          exposicaoSolar: _exposicaoSolar,
        ),
        estadoBasal: EstadoBasalAtleta(
          corUrina: _corUrina,
          nivelSede: _nivelSede,
          sintomaPrevio: _sintomaPrevio,
          descricaoSintoma:
              _sintomaPrevio ? _sintomDescController.text : null,
          hidratacaoUltimasHoras: double.parse(
              _hidratacaoRecenteController.text.replaceAll(',', '.')),
        ),
      );

      final sessaoId =
          await _sessaoService.iniciarSessao(sessao);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TelaDuranteSessao(
            atletaUid: widget.atletaUid,
            sessaoId: sessaoId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar sessão: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarErroChecklist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Confirme todos os itens do checklist de padronização antes de iniciar.'),
        backgroundColor: Color(0xFFC41230),
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
        title: const Text('Nova sessão',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildIndicadorEtapas(),
          Expanded(
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildEtapaAtual(),
              ),
            ),
          ),
          _buildBotoesNavegacao(),
        ],
      ),
    );
  }

  // indicador de etapas
  Widget _buildIndicadorEtapas() {
    return Container(
      color: const Color(0xFFC41230),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(_etapas.length, (i) {
          final ativa = i == _etapaAtual;
          final concluida = i < _etapaAtual;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        decoration: BoxDecoration(
                          color: concluida || ativa
                              ? Colors.white
                              : Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _etapas[i],
                        style: TextStyle(
                          color: ativa ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: ativa
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _etapas.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // roteador de etapas
  Widget _buildEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return _buildEtapaPesagem();
      case 1:
        return _buildEtapaAmbiente();
      case 2:
        return _buildEtapaSessao();
      case 3:
        return _buildEtapaEstadoBasal();
      default:
        return const SizedBox.shrink();
    }
  }

  // etapa 1 (pesagem)
  Widget _buildEtapaPesagem() {
    return _buildScrollablePage(
      key: const ValueKey('pesagem'),
      children: [
        _buildSecaoTitulo(
          icone: Icons.monitor_weight_outlined,
          titulo: 'Pesagem inicial',
          subtitulo: 'Registre a massa corporal antes da sessão',
        ),
        const SizedBox(height: 24),
        _buildCard(
          children: [
            _buildCampoNumerico(
              controller: _massaController,
              label: 'Massa corporal (kg)',
              hint: 'Ex: 72,5',
              icone: Icons.scale_outlined,
              casasDecimais: true,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null) return 'Valor inválido';
                if (val < 30 || val > 200) return 'Valor fora do intervalo esperado (30–200 kg)';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildCard(
          titulo: 'Checklist de padronização',
          children: [
            _buildCheckItem(
              label: 'Bexiga esvaziada antes da pesagem',
              valor: _checkBexiga,
              onChanged: (v) => setState(() => _checkBexiga = v ?? false),
            ),
            _buildCheckItem(
              label: 'Mesma balança e superfície nivelada',
              valor: _checkMesmaBalanca,
              onChanged: (v) =>
                  setState(() => _checkMesmaBalanca = v ?? false),
            ),
            _buildCheckItem(
              label: 'Vestimenta mínima e consistente',
              valor: _checkVestimentaPadrao,
              onChanged: (v) =>
                  setState(() => _checkVestimentaPadrao = v ?? false),
            ),
          ],
        ),
        if (!_checklistCompleto && _etapaAtual == 0) ...[
          const SizedBox(height: 12),
          _buildAlertaInfo(
            'Confirme todos os itens para garantir a precisão da medida.',
          ),
        ],
      ],
    );
  }

  // etapa 2 (ondições ambientais)
  Widget _buildEtapaAmbiente() {
    return _buildScrollablePage(
      key: const ValueKey('ambiente'),
      children: [
        _buildSecaoTitulo(
          icone: Icons.wb_sunny_outlined,
          titulo: 'Condições ambientais',
          subtitulo: 'Registre o ambiente do local de treino',
        ),
        const SizedBox(height: 24),
        _buildCard(
          children: [
            _buildCampoNumerico(
              controller: _temperaturaController,
              label: 'Temperatura (°C)',
              hint: 'Ex: 28',
              icone: Icons.thermostat_outlined,
              casasDecimais: true,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null) return 'Valor inválido';
                if (val < -10 || val > 55) return 'Temperatura fora do intervalo esperado';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCampoNumerico(
              controller: _umidadeController,
              label: 'Umidade relativa (%)',
              hint: 'Ex: 65',
              icone: Icons.water_drop_outlined,
              casasDecimais: false,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null) return 'Valor inválido';
                if (val < 0 || val > 100) return 'Umidade deve ser entre 0 e 100%';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCampoNumerico(
              controller: _ventoController,
              label: 'Velocidade do vento (km/h)',
              hint: 'Ex: 15',
              icone: Icons.air_outlined,
              casasDecimais: false,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null) return 'Valor inválido';
                if (val < 0 || val > 200) return 'Valor inválido';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Exposição solar',
          children: [
            _buildSeletorEnum<ExposicaoSolar>(
              opcoes: ExposicaoSolar.values,
              selecionado: _exposicaoSolar,
              label: _labelExposicaoSolar,
              icone: _iconeExposicaoSolar,
              onChanged: (v) => setState(() => _exposicaoSolar = v),
            ),
          ],
        ),
      ],
    );
  }

  // etapa 3 (dados da sessão)
  Widget _buildEtapaSessao() {
    return _buildScrollablePage(
      key: const ValueKey('sessao'),
      children: [
        _buildSecaoTitulo(
          icone: Icons.sports_outlined,
          titulo: 'Dados da sessão',
          subtitulo: 'Modalidade, duração prevista e intensidade',
        ),
        const SizedBox(height: 24),
        _buildCard(
          titulo: 'Modalidade',
          children: [
            _buildDropdownEnum<ModalidadeEsportiva>(
              valor: _modalidade,
              opcoes: ModalidadeEsportiva.values,
              label: _labelModalidade,
              onChanged: (v) => setState(() => _modalidade = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          children: [
            _buildCampoNumerico(
              controller: _duracaoController,
              label: 'Duração prevista (min)',
              hint: 'Ex: 90',
              icone: Icons.timer_outlined,
              casasDecimais: false,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = int.tryParse(v);
                if (val == null) return 'Valor inválido';
                if (val < 5 || val > 480) return 'Duração fora do intervalo esperado (5–480 min)';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Intensidade',
          children: [
            _buildSeletorEnum<IntensidadeTreino>(
              opcoes: IntensidadeTreino.values,
              selecionado: _intensidade,
              label: _labelIntensidade,
              icone: _iconeIntensidade,
              onChanged: (v) => setState(() => _intensidade = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Vestimenta',
          children: [
            _buildSeletorEnum<TipoVestimenta>(
              opcoes: TipoVestimenta.values,
              selecionado: _vestimenta,
              label: _labelVestimenta,
              icone: (_) => Icons.checkroom_outlined,
              onChanged: (v) => setState(() => _vestimenta = v),
            ),
          ],
        ),
      ],
    );
  }

  // etapa 4 (estado basal)
  Widget _buildEtapaEstadoBasal() {
    return _buildScrollablePage(
      key: const ValueKey('basal'),
      children: [
        _buildSecaoTitulo(
          icone: Icons.health_and_safety_outlined,
          titulo: 'Estado basal (repouso)',
          subtitulo: 'Como o atleta está antes de iniciar',
        ),
        const SizedBox(height: 24),
        _buildCard(
          titulo: 'Cor da urina',
          subtitulo: 'Escala de Armstrong (1 = bem hidratado, 8 = desidratado)',
          children: [
            _buildSeletorCorUrina(),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Nível de sede',
          children: [
            _buildSeletorSede(),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Hidratação recente',
          children: [
            _buildCampoNumerico(
              controller: _hidratacaoRecenteController,
              label: 'Fluidos ingeridos nas últimas 2h (mL)',
              hint: 'Ex: 500',
              icone: Icons.local_drink_outlined,
              casasDecimais: false,
              validar: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null) return 'Valor inválido';
                if (val < 0 || val > 3000) return 'Valor fora do intervalo esperado';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          titulo: 'Sintomas pré-sessão',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apresenta sintoma',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Dor de cabeça, tontura, náusea ou outro',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              value: _sintomaPrevio,
              activeColor: const Color(0xFFC41230),
              onChanged: (v) => setState(() => _sintomaPrevio = v),
            ),
            if (_sintomaPrevio) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _sintomDescController,
                decoration: _inputDecoration('Descreva o sintoma', null),
                maxLines: 2,
                validator: (v) => _sintomaPrevio && (v == null || v.isEmpty)
                    ? 'Descreva o sintoma'
                    : null,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // botões de navegação
  Widget _buildBotoesNavegacao() {
    final isUltimaEtapa = _etapaAtual == _etapas.length - 1;
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
          if (_etapaAtual > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _voltar,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFC41230)),
                  foregroundColor: const Color(0xFFC41230),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Voltar'),
              ),
            ),
          if (_etapaAtual > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _salvando ? null : _avancar,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC41230),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isUltimaEtapa ? 'Iniciar sessão' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  // widgets reutilizáveis
  Widget _buildScrollablePage(
      {required List<Widget> children, required ValueKey key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSecaoTitulo({
    required IconData icone,
    required String titulo,
    required String subtitulo,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFC41230).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: const Color(0xFFC41230), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(subtitulo,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    String? titulo,
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
          if (titulo != null) ...[
            Text(titulo,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(subtitulo,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45)),
            ],
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icone,
    required bool casasDecimais,
    required String? Function(String?) validar,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icone),
      keyboardType:
          TextInputType.numberWithOptions(decimal: casasDecimais),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(casasDecimais ? r'[\d,.]' : r'\d')),
      ],
      validator: validar,
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool valor,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: valor,
      activeColor: const Color(0xFFC41230),
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildAlertaInfo(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensagem,
                style:
                    TextStyle(fontSize: 12, color: Colors.amber[900])),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorEnum<T>({
    required List<T> opcoes,
    required T selecionado,
    required String Function(T) label,
    required IconData Function(T) icone,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opcoes.map((op) {
        final ativo = op == selecionado;
        return GestureDetector(
          onTap: () => onChanged(op),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ativo
                  ? const Color(0xFFC41230)
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone(op),
                    size: 16,
                    color: ativo ? Colors.white : Colors.black54),
                const SizedBox(width: 6),
                Text(label(op),
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            ativo ? Colors.white : Colors.black87,
                        fontWeight: ativo
                            ? FontWeight.w600
                            : FontWeight.normal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownEnum<T>({
    required T valor,
    required List<T> opcoes,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: valor,
      decoration: _inputDecoration('Modalidade', Icons.sports_outlined),
      items: opcoes
          .map((op) => DropdownMenuItem(
                value: op,
                child: Text(label(op)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildSeletorCorUrina() {
    const cores = [
      Color(0xFFFFF9C4), // 1 — amarelo pálido
      Color(0xFFFFF176), // 2 — amarelo claro
      Color(0xFFFFEE58), // 3 — amarelo médio
      Color(0xFFFFCA28), // 4 — amarelo escuro
      Color(0xFFFFA726), // 5 — amarelo alaranjado
      Color(0xFFFF7043), // 6 — alaranjado
      Color(0xFF8D6E63), // 7 — marrom claro
      Color(0xFF4E342E), // 8 — marrom escuro
    ];

    return Column(
      children: [
        Row(
          children: List.generate(8, (i) {
            final selecionado = _corUrina.index == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(
                    () => _corUrina = CorUrina.values[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  margin: EdgeInsets.only(right: i < 7 ? 3 : 0),
                  decoration: BoxDecoration(
                    color: cores[i],
                    borderRadius: BorderRadius.circular(6),
                    border: selecionado
                        ? Border.all(
                            color: const Color(0xFFC41230), width: 2.5)
                        : null,
                    boxShadow: selecionado
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC41230)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: selecionado
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.black54)
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Hidratado', style: TextStyle(fontSize: 10, color: Colors.black45)),
            Text('Desidratado', style: TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Selecionado: ${_labelCorUrina(_corUrina)}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSeletorSede() {
    const icones = [
      Icons.sentiment_very_satisfied,
      Icons.sentiment_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
    ];
    const labels = ['Sem sede', 'Pouca', 'Moderada', 'Muita', 'Extrema'];

    return Row(
      children: List.generate(5, (i) {
        final nivel = i + 1;
        final ativo = _nivelSede == nivel;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _nivelSede = nivel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
              decoration: BoxDecoration(
                color: ativo
                    ? const Color(0xFFC41230)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(icones[i],
                      size: 20,
                      color: ativo ? Colors.white : Colors.black45),
                  const SizedBox(height: 4),
                  Text(labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: ativo
                              ? Colors.white
                              : Colors.black54)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icone != null ? Icon(icone, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFC41230), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(fontSize: 14),
    );
  }

  // labels e ícones dos enums
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

  IconData _iconeIntensidade(IntensidadeTreino i) => switch (i) {
        IntensidadeTreino.leve => Icons.directions_walk,
        IntensidadeTreino.moderada => Icons.directions_run,
        IntensidadeTreino.intensa => Icons.flash_on,
        IntensidadeTreino.muitoIntensa => Icons.whatshot,
      };

  String _labelVestimenta(TipoVestimenta v) => switch (v) {
        TipoVestimenta.minima => 'Mínima',
        TipoVestimenta.media => 'Média',
        TipoVestimenta.pesada => 'Pesada',
        TipoVestimenta.uniforme => 'Uniforme',
      };

  String _labelExposicaoSolar(ExposicaoSolar e) => switch (e) {
        ExposicaoSolar.sombra => 'Sombra',
        ExposicaoSolar.solParcial => 'Sol parcial',
        ExposicaoSolar.solPleno => 'Sol pleno',
      };

  IconData _iconeExposicaoSolar(ExposicaoSolar e) => switch (e) {
        ExposicaoSolar.sombra => Icons.nights_stay_outlined,
        ExposicaoSolar.solParcial => Icons.wb_cloudy_outlined,
        ExposicaoSolar.solPleno => Icons.wb_sunny_outlined,
      };

  String _labelCorUrina(CorUrina c) => switch (c) {
        CorUrina.amareloPalido1 => '1 — Amarelo pálido (bem hidratado)',
        CorUrina.amareloClaro2 => '2 — Amarelo claro',
        CorUrina.amareloMedio3 => '3 — Amarelo médio',
        CorUrina.amareloEscuro4 => '4 — Amarelo escuro',
        CorUrina.amareloAlaranjado5 => '5 — Amarelo alaranjado',
        CorUrina.alaranjado6 => '6 — Alaranjado',
        CorUrina.marromClaro7 => '7 — Marrom claro',
        CorUrina.marromEscuro8 => '8 — Marrom escuro (desidratado)',
      };
}