import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../models/sessao.dart';

class RelatorioService {
  // PDF:
  /// abre diálogo de impressão/compartilhamento do PDF
  static Future<void> exportarPdf(Sessao sessao) async {
    final pdf = await _gerarPdf(sessao);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: _nomeArquivo(sessao, 'pdf'),
    );
  }

  static Future<pw.Document> _gerarPdf(Sessao sessao) async {
    final pdf = pw.Document();
    final resultado = sessao.resultado!;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final corPrincipal = PdfColor.fromHex('#C41230');
    final cinzaClaro = PdfColor.fromHex('#F5F5F5');
    final cinzaTexto = PdfColor.fromHex('#555555');

    // fonte padrão
    final estilo = pw.TextStyle(fontSize: 10, color: cinzaTexto);
    final estiloNegrito =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final estiloTitulo = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: corPrincipal,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => _buildCabecalhoPdf(sessao, corPrincipal, fmt),
        footer: (ctx) => _buildRodapePdf(ctx, cinzaTexto),
        build: (context) => [
          pw.SizedBox(height: 16),

          // métricas principais
          _tituloSecao('Métricas da sessão', estiloTitulo),
          pw.SizedBox(height: 8),
          _tabelaDoisColunas([
            ['Taxa de sudorese', '${resultado.taxaSudoreseLh.toStringAsFixed(2)} L/h'],
            ['Perda de massa ajustada', '${resultado.perdaMassaAjustadaKg.toStringAsFixed(2)} kg'],
            ['Variação de massa', '${resultado.variacaoMassaPercent.toStringAsFixed(1)}%'],
            ['Balanço hídrico', '${resultado.balanceHidricoMl.toStringAsFixed(0)} mL'],
          ], estiloNegrito, estilo, cinzaClaro),

          pw.SizedBox(height: 16),

          // dados pré-sessão
          _tituloSecao('Dados pré-sessão', estiloTitulo),
          pw.SizedBox(height: 8),
          _tabelaDoisColunas([
            ['Massa pré', '${sessao.massaPreKg.toStringAsFixed(1)} kg'],
            ['Modalidade', _labelModalidade(sessao.modalidade)],
            ['Intensidade', _labelIntensidade(sessao.intensidade)],
            ['Duração prevista', '${sessao.duracaoPrevistaMin} min'],
            ['Vestimenta', _labelVestimenta(sessao.vestimenta)],
          ], estiloNegrito, estilo, cinzaClaro),

          pw.SizedBox(height: 16),

          // condições ambientais
          _tituloSecao('Condições ambientais', estiloTitulo),
          pw.SizedBox(height: 8),
          _tabelaDoisColunas([
            ['Temperatura', '${sessao.condicoesAmbientais.temperaturaC.toStringAsFixed(1)} °C'],
            ['Umidade relativa', '${sessao.condicoesAmbientais.umidadeRelativa.toStringAsFixed(0)}%'],
            ['Vento', '${sessao.condicoesAmbientais.velocidadeVentoKmh.toStringAsFixed(0)} km/h'],
            ['Exposição solar', _labelExposicao(sessao.condicoesAmbientais.exposicaoSolar)],
          ], estiloNegrito, estilo, cinzaClaro),

          pw.SizedBox(height: 16),

          // dados pós-sessão
          if (sessao.dadosPosSessao != null) ...[
            _tituloSecao('Dados pós-sessão', estiloTitulo),
            pw.SizedBox(height: 8),
            _tabelaDoisColunas([
              ['Massa pós', '${sessao.dadosPosSessao!.massaCorporalKg.toStringAsFixed(1)} kg'],
              ['Volume urinário', '${sessao.dadosPosSessao!.volumeUrinarioMl.toStringAsFixed(0)} mL'],
              ['Sintoma GI', sessao.dadosPosSessao!.sintomaGastrointestinal ? 'Sim' : 'Não'],
              ['Fadiga', sessao.dadosPosSessao!.sintomaFadiga ? 'Sim' : 'Não'],
              ['Tolerância ao plano', '${sessao.dadosPosSessao!.toleranciaPlanoHidrico}/5'],
            ], estiloNegrito, estilo, cinzaClaro),
            pw.SizedBox(height: 16),
          ],

          // recomendações
          _tituloSecao('Recomendações de hidratação', estiloTitulo),
          pw.SizedBox(height: 8),
          _tabelaDoisColunas([
            ['Alvo de ingestão', '${resultado.ingestaoAlvoMlH.toStringAsFixed(0)} mL/h'],
            ['Intervalo', 'a cada ${resultado.intervaloIngestaoMin} min'],
            ['Volume por dose', '${resultado.volumePorDoseMl.toStringAsFixed(0)} mL'],
          ], estiloNegrito, estilo, cinzaClaro),

          // alertas
          if (resultado.alertas.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _tituloSecao('Alertas clínicos', estiloTitulo),
            pw.SizedBox(height: 8),
            ...resultado.alertas.map((a) => _itemAlertaPdf(a, estilo, corPrincipal)),
          ],

          if (resultado.encaminhamentoRecomendado) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: corPrincipal),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                '⚠ Encaminhamento para avaliação profissional recomendado.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: corPrincipal,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  // widgets auxiliares
  static pw.Widget _buildCabecalhoPdf(
      Sessao sessao, PdfColor cor, DateFormat fmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'HidroBalance',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: cor,
              ),
            ),
            pw.Text(
              'Relatório de Sessão',
              style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#888888')),
            ),
          ],
        ),
        pw.Divider(color: cor, thickness: 1.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Atleta: ${sessao.codigoAtleta}',
                style: pw.TextStyle(fontSize: 9)),
            pw.Text('Início: ${fmt.format(sessao.dataHoraInicio)}',
                style: pw.TextStyle(fontSize: 9)),
            if (sessao.dataHoraFim != null)
              pw.Text('Fim: ${fmt.format(sessao.dataHoraFim!)}',
                  style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildRodapePdf(pw.Context ctx, PdfColor cor) {
    return pw.Column(
      children: [
        pw.Divider(color: cor),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Centro Universitário São Camilo · HidroBalance',
                style: pw.TextStyle(fontSize: 8, color: cor)),
            pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: cor)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tituloSecao(String titulo, pw.TextStyle estilo) {
    return pw.Text(titulo, style: estilo);
  }

  static pw.Widget _tabelaDoisColunas(
    List<List<String>> linhas,
    pw.TextStyle estiloChave,
    pw.TextStyle estiloValor,
    PdfColor fundoAlternado,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(2.4),
      },
      children: linhas.asMap().entries.map((entry) {
        final i = entry.key;
        final linha = entry.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? fundoAlternado : PdfColors.white,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(linha[0], style: estiloChave),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(linha[1], style: estiloValor),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _itemAlertaPdf(
      AlertaRisco alerta, pw.TextStyle estilo, PdfColor cor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FFF8F8'),
          border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '[${_labelNivelPdf(alerta.nivel)}] ${alerta.mensagem}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            if (alerta.orientacao != null)
              pw.Text(alerta.orientacao!, style: estilo),
          ],
        ),
      ),
    );
  }

  // CSV
  static Future<void> exportarCsv(Sessao sessao, {BuildContext? context}) async {
    final origin = _shareOrigin(context);

    final resultado = sessao.resultado!;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    final linhas = [
      // cabeçalho
      ['Campo', 'Valor'],
      // identificação
      ['Atleta', sessao.codigoAtleta],
      ['Início', fmt.format(sessao.dataHoraInicio)],
      if (sessao.dataHoraFim != null) ['Fim', fmt.format(sessao.dataHoraFim!)],
      ['Modalidade', _labelModalidade(sessao.modalidade)],
      ['Intensidade', _labelIntensidade(sessao.intensidade)],
      ['Duração prevista (min)', sessao.duracaoPrevistaMin.toString()],
      // pré
      ['Massa pré (kg)', sessao.massaPreKg.toStringAsFixed(2)],
      ['Temperatura (°C)', sessao.condicoesAmbientais.temperaturaC.toStringAsFixed(1)],
      ['Umidade (%)', sessao.condicoesAmbientais.umidadeRelativa.toStringAsFixed(0)],
      ['Vento (km/h)', sessao.condicoesAmbientais.velocidadeVentoKmh.toStringAsFixed(0)],
      ['Exposição solar', _labelExposicao(sessao.condicoesAmbientais.exposicaoSolar)],
      // resultados
      ['Taxa de sudorese (L/h)', resultado.taxaSudoreseLh.toStringAsFixed(3)],
      ['Perda ajustada (kg)', resultado.perdaMassaAjustadaKg.toStringAsFixed(3)],
      ['Variação de massa (%)', resultado.variacaoMassaPercent.toStringAsFixed(2)],
      ['Balanço hídrico (mL)', resultado.balanceHidricoMl.toStringAsFixed(0)],
      // recomendações
      ['Alvo ingestão (mL/h)', resultado.ingestaoAlvoMlH.toStringAsFixed(0)],
      ['Intervalo (min)', resultado.intervaloIngestaoMin.toString()],
      ['Volume por dose (mL)', resultado.volumePorDoseMl.toStringAsFixed(0)],
      // pós
      if (sessao.dadosPosSessao != null) ...[
        ['Massa pós (kg)', sessao.dadosPosSessao!.massaCorporalKg.toStringAsFixed(2)],
        ['Volume urinário (mL)', sessao.dadosPosSessao!.volumeUrinarioMl.toStringAsFixed(0)],
        ['Sintoma GI', sessao.dadosPosSessao!.sintomaGastrointestinal ? 'Sim' : 'Não'],
        ['Fadiga', sessao.dadosPosSessao!.sintomaFadiga ? 'Sim' : 'Não'],
        ['Tolerância ao plano (1-5)', sessao.dadosPosSessao!.toleranciaPlanoHidrico.toString()],
      ],
    ];

    final conteudo = linhas.map((l) => l.map(_escaparCsv).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final arquivo = File('${dir.path}/${_nomeArquivo(sessao, 'csv')}');
    await arquivo.writeAsString(conteudo);

    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: 'text/csv')],
      subject: 'Relatório HidroBalance — ${sessao.codigoAtleta}',
      sharePositionOrigin: origin,
    );
  }

  static Rect? _shareOrigin(BuildContext? context) {
  if (context == null) return null;
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

  // helpers
  static String _nomeArquivo(Sessao sessao, String ext) {
    final data = DateFormat('yyyyMMdd_HHmm').format(sessao.dataHoraInicio);
    return 'hidrobalance_${sessao.codigoAtleta}_$data.$ext';
  }

  static String _escaparCsv(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }

  static String _labelModalidade(ModalidadeEsportiva m) => switch (m) {
        ModalidadeEsportiva.corrida => 'Corrida',
        ModalidadeEsportiva.ciclismo => 'Ciclismo',
        ModalidadeEsportiva.natacao => 'Natação',
        ModalidadeEsportiva.futebol => 'Futebol',
        ModalidadeEsportiva.basquete => 'Basquete',
        ModalidadeEsportiva.volei => 'Vôlei',
        ModalidadeEsportiva.tenis => 'Tênis',
        ModalidadeEsportiva.musculacao => 'Musculação',
        ModalidadeEsportiva.crossfit => 'Crossfit',
        ModalidadeEsportiva.outro => 'Outro',
      };

  static String _labelIntensidade(IntensidadeTreino i) => switch (i) {
        IntensidadeTreino.leve => 'Leve',
        IntensidadeTreino.moderada => 'Moderada',
        IntensidadeTreino.intensa => 'Intensa',
        IntensidadeTreino.muitoIntensa => 'Muito intensa',
      };

  static String _labelVestimenta(TipoVestimenta v) => switch (v) {
        TipoVestimenta.minima => 'Mínima',
        TipoVestimenta.media => 'Média',
        TipoVestimenta.pesada => 'Pesada',
        TipoVestimenta.uniforme => 'Uniforme esportivo',
      };

  static String _labelExposicao(ExposicaoSolar e) => switch (e) {
        ExposicaoSolar.sombra => 'Sombra',
        ExposicaoSolar.solParcial => 'Sol parcial',
        ExposicaoSolar.solPleno => 'Sol pleno',
      };

  static String _labelNivelPdf(NivelRisco n) => switch (n) {
        NivelRisco.normal => 'Normal',
        NivelRisco.atencao => 'Atenção',
        NivelRisco.alerta => 'Alerta',
        NivelRisco.critico => 'Crítico',
      };
}