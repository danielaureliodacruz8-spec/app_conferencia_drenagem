import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/conferencia_model.dart';

class ConferenciaScreen extends StatefulWidget {
  const ConferenciaScreen({super.key});

  @override
  State<ConferenciaScreen> createState() => _ConferenciaScreenState();
}

class _ConferenciaScreenState extends State<ConferenciaScreen> {
  final _observacaoController = TextEditingController();

  bool _carregando = true;
  String _mensagem = 'Carregando eixos das obras...';

  String _obra = '';
  String _rodovia = '';
  String _trecho = '';
  String _estaca = '';
  String _offset = '';
  String _lado = '';

  double? _latitude;
  double? _longitude;
  double? _precisao;
  double? _distanciaEixo;

  List<_EixoRodovia> _eixos = [];

  @override
  void initState() {
    super.initState();
    _localizarAutomaticamente();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _localizarAutomaticamente() async {
    setState(() {
      _carregando = true;
      _mensagem = 'Carregando eixos das obras...';
      _obra = '';
      _rodovia = '';
      _trecho = '';
      _estaca = '';
      _offset = '';
      _lado = '';
      _latitude = null;
      _longitude = null;
      _precisao = null;
      _distanciaEixo = null;
    });

    try {
      _eixos = await _carregarEixos();

      if (_eixos.isEmpty) {
        throw Exception('Nenhum eixo foi encontrado nos arquivos XML.');
      }

      if (!mounted) return;

      setState(() {
        _mensagem = 'Obtendo localização automática do dispositivo...';
      });

      final posicao = await _obterLocalizacao();

      final utm = _converterWgs84ParaUtm23S(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );

      _ResultadoEixo? melhorResultado;

      for (final eixo in _eixos) {
        final resultado = eixo.localizar(
          pontoX: utm.x,
          pontoY: utm.y,
        );

        if (resultado == null) continue;

        if (melhorResultado == null ||
            resultado.distancia < melhorResultado.distancia) {
          melhorResultado = resultado;
        }
      }

      if (melhorResultado == null) {
        throw Exception('Não foi possível localizar o dispositivo em um eixo.');
      }

      if (melhorResultado.distancia > 300) {
        throw Exception(
          'O dispositivo está a '
          '${melhorResultado.distancia.toStringAsFixed(1)} m '
          'do eixo mais próximo.',
        );
      }

      final lado = melhorResultado.offsetAssinado.abs() < 0.30
          ? 'EIXO'
          : melhorResultado.offsetAssinado < 0
              ? 'DIREITO'
              : 'ESQUERDO';

      if (!mounted) return;

      setState(() {
        _obra = melhorResultado.eixo.obra;
        _rodovia = melhorResultado.eixo.rodovia;
        _trecho = melhorResultado.eixo.trecho;

        _estaca = _calcularEstaca(
          estacaInicial: melhorResultado.eixo.estacaInicial,
          distanciaNoEixo: melhorResultado.progresso,
        );

        _offset = melhorResultado.offsetAssinado.abs().toStringAsFixed(3);
        _lado = lado;
        _latitude = posicao.latitude;
        _longitude = posicao.longitude;
        _precisao = posicao.accuracy;
        _distanciaEixo = melhorResultado.distancia;
        _mensagem = 'Localização automática concluída.';
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _mensagem = erro.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<Position> _obterLocalizacao() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw Exception(
        'Ative a localização do celular para localizar o dispositivo.',
      );
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      throw Exception('A permissão de localização foi negada.');
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização está bloqueada. '
        'Libere a localização nas configurações do celular.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    );
  }

  Future<List<_EixoRodovia>> _carregarEixos() async {
    final eixos = <_EixoRodovia>[];

    const arquivos = [
      _ArquivoEixo(
        caminho: 'assets/eixos/20261027_EIXO_GO236_R.xml',
        rodoviaPadrao: 'GO-236',
        trechoPadrao: 'Trecho GO-236',
      ),
      _ArquivoEixo(
        caminho:
            'assets/eixos/Alinhamento_Horizontal_GO110_Est1500_a_2249.xml',
        rodoviaPadrao: 'GO-110',
        trechoPadrao: 'Estiva / São Domingos',
      ),
    ];

    for (final arquivo in arquivos) {
      try {
        final xml = await rootBundle.loadString(arquivo.caminho);

        final eixo = _lerEixoXml(
          xml: xml,
          rodoviaPadrao: arquivo.rodoviaPadrao,
          trechoPadrao: arquivo.trechoPadrao,
        );

        if (eixo != null) {
          eixos.add(eixo);
        }
      } catch (_) {}
    }

    return eixos;
  }

  _EixoRodovia? _lerEixoXml({
    required String xml,
    required String rodoviaPadrao,
    required String trechoPadrao,
  }) {
    final projetoMatch = RegExp(
      r'<Project[^>]*name="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(xml);

    final alignmentMatch = RegExp(
      r'<Alignment[^>]*staStart="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(xml);

    final estacaInicial = alignmentMatch == null
        ? 0.0
        : double.tryParse(alignmentMatch.group(1) ?? '0') ?? 0.0;

    final segmentos = <_PontoEixo>[];

    final elementos = RegExp(
      r'<(?:Line|Curve|Spiral)\b(?=[^>]*\blength="([^"]+)")[^>]*>'
      r'([\s\S]*?)'
      r'</(?:Line|Curve|Spiral)>',
      caseSensitive: false,
    ).allMatches(xml);

    double progresso = 0;

    for (final elemento in elementos) {
      final comprimento = double.tryParse(
            elemento.group(1)?.replaceAll(',', '.') ?? '0',
          ) ??
          0;

      final conteudo = elemento.group(2) ?? '';

      final inicioMatch = RegExp(
        r'<Start>\s*([-\d.]+)\s+([-\d.]+)\s*</Start>',
        caseSensitive: false,
      ).firstMatch(conteudo);

      final fimMatch = RegExp(
        r'<End>\s*([-\d.]+)\s+([-\d.]+)\s*</End>',
        caseSensitive: false,
      ).firstMatch(conteudo);

      if (inicioMatch == null || fimMatch == null || comprimento <= 0) {
        continue;
      }

      final xInicio = double.tryParse(inicioMatch.group(1) ?? '');
      final yInicio = double.tryParse(inicioMatch.group(2) ?? '');
      final xFim = double.tryParse(fimMatch.group(1) ?? '');
      final yFim = double.tryParse(fimMatch.group(2) ?? '');

      if (xInicio == null || yInicio == null || xFim == null || yFim == null) {
        continue;
      }

      segmentos.add(
        _PontoEixo(
          xInicio: xInicio,
          yInicio: yInicio,
          xFim: xFim,
          yFim: yFim,
          progressoInicial: progresso,
          comprimento: comprimento,
        ),
      );

      progresso += comprimento;
    }

    if (segmentos.isEmpty) {
      return null;
    }

    final nomeProjeto = projetoMatch?.group(1)?.trim() ?? '';

    return _EixoRodovia(
      obra: nomeProjeto.isEmpty ? rodoviaPadrao : nomeProjeto,
      rodovia: rodoviaPadrao,
      trecho: trechoPadrao,
      estacaInicial: estacaInicial,
      segmentos: segmentos,
    );
  }

  _CoordenadaUtm _converterWgs84ParaUtm23S({
    required double latitude,
    required double longitude,
  }) {
    const double semiEixoMaior = 6378137.0;
    const double excentricidade = 0.00669438;
    const double fatorEscala = 0.9996;
    const int zona = 23;

    final latitudeRad = latitude * math.pi / 180;
    final longitudeRad = longitude * math.pi / 180;

    final meridianoCentral =
        ((zona - 1) * 6 - 180 + 3) * math.pi / 180;

    final eLinha = excentricidade / (1 - excentricidade);
    final senoLatitude = math.sin(latitudeRad);
    final cossenoLatitude = math.cos(latitudeRad);
    final tangenteLatitude = math.tan(latitudeRad);

    final senoQuadrado = senoLatitude * senoLatitude;
    final tangenteQuadrada = tangenteLatitude * tangenteLatitude;
    final cossenoQuadrado = cossenoLatitude * cossenoLatitude;

    final n = semiEixoMaior / math.sqrt(1 - excentricidade * senoQuadrado);
    final t = tangenteQuadrada;
    final c = eLinha * cossenoQuadrado;
    final aLongitude = cossenoLatitude * (longitudeRad - meridianoCentral);

    final a2 = aLongitude * aLongitude;
    final a3 = a2 * aLongitude;
    final a4 = a2 * a2;
    final a5 = a4 * aLongitude;
    final a6 = a3 * a3;

    final e2 = excentricidade * excentricidade;
    final e3 = e2 * excentricidade;

    final m = semiEixoMaior *
        ((1 - excentricidade / 4 - 3 * e2 / 64 - 5 * e3 / 256) *
                latitudeRad -
            (3 * excentricidade / 8 + 3 * e2 / 32 + 45 * e3 / 1024) *
                math.sin(2 * latitudeRad) +
            (15 * e2 / 256 + 45 * e3 / 1024) *
                math.sin(4 * latitudeRad) -
            (35 * e3 / 3072) * math.sin(6 * latitudeRad));

    final x = fatorEscala *
            n *
            (aLongitude +
                (1 - t + c) * a3 / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * eLinha) * a5 / 120) +
        500000;

    var y = fatorEscala *
        (m +
            n *
                tangenteLatitude *
                (a2 / 2 +
                    (5 - t + 9 * c + 4 * c * c) * a4 / 24 +
                    (61 - 58 * t + t * t + 600 * c - 330 * eLinha) *
                        a6 /
                        720));

    if (latitude < 0) {
      y += 10000000;
    }

    return _CoordenadaUtm(x: x, y: y);
  }

  String _calcularEstaca({
    required double estacaInicial,
    required double distanciaNoEixo,
  }) {
    const double metrosPorEstaca = 20.0;

    final quantidadeDeEstacas = distanciaNoEixo / metrosPorEstaca;

    final estacaCalculada = estacaInicial + quantidadeDeEstacas;

    final numeroEstaca = estacaCalculada.floor();

    final metrosDaEstaca =
        (estacaCalculada - numeroEstaca) * metrosPorEstaca;

    return '${numeroEstaca.toString().padLeft(4, '0')}+'
        '${metrosDaEstaca.toStringAsFixed(3).padLeft(6, '0')}';
  }

  String _dataAgora() {
    final agora = DateTime.now();

    String doisDigitos(int numero) {
      return numero.toString().padLeft(2, '0');
    }

    return '${doisDigitos(agora.day)}/${doisDigitos(agora.month)}/'
        '${agora.year} '
        '${doisDigitos(agora.hour)}:${doisDigitos(agora.minute)}';
  }

  void _salvar() {
    if (_estaca.isEmpty || _rodovia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aguarde a localização automática antes de salvar.',
          ),
        ),
      );
      return;
    }

    final conferencia = Conferencia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      obra: _obra,
      rodovia: _rodovia,
      trecho: _trecho,
      estaca: _estaca,
      offset: _offset,
      lado: _lado,
      observacao: _observacaoController.text.trim(),
      dataCriacao: _dataAgora(),
      medicoes: [],
      fotos: [],
    );

    Navigator.pop(context, conferencia);
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF003A70);
    final localizada = _estaca.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova conferência'),
        backgroundColor: azul,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar localização',
            onPressed: _carregando ? null : _localizarAutomaticamente,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: localizada
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF3E0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _carregando
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Icon(
                          localizada
                              ? Icons.location_on
                              : Icons.location_searching,
                          color: localizada ? Colors.green : Colors.orange,
                          size: 30,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _mensagem,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dados automáticos do dispositivo',
            style: TextStyle(
              color: azul,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _cardDados([
            _linha('Obra', _obra),
            _linha('Rodovia', _rodovia),
            _linha('Trecho', _trecho),
            _linha('Estaca', _estaca),
            _linha(
              'Offset',
              _offset.isEmpty ? '' : '$_offset m',
            ),
            _linha('Lado', _lado, ultimo: true),
          ]),
          const SizedBox(height: 20),
          const Text(
            'Posição do dispositivo',
            style: TextStyle(
              color: azul,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _cardDados([
            _linha(
              'Latitude',
              _latitude == null ? '' : _latitude!.toStringAsFixed(7),
            ),
            _linha(
              'Longitude',
              _longitude == null ? '' : _longitude!.toStringAsFixed(7),
            ),
            _linha(
              'Precisão GPS',
              _precisao == null ? '' : '${_precisao!.toStringAsFixed(1)} m',
            ),
            _linha(
              'Distância ao eixo',
              _distanciaEixo == null
                  ? ''
                  : '${_distanciaEixo!.toStringAsFixed(2)} m',
              ultimo: true,
            ),
          ]),
          const SizedBox(height: 20),
          const Text(
            'Observação geral',
            style: TextStyle(
              color: azul,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _observacaoController,
            minLines: 4,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Digite somente observações da conferência...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: localizada && !_carregando ? _salvar : null,
            style: FilledButton.styleFrom(
              backgroundColor: azul,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Salvar conferência'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _cardDados(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: children),
      ),
    );
  }

  Widget _linha(
    String titulo,
    String valor, {
    bool ultimo = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  valor.isEmpty ? '-' : valor,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF003A70),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!ultimo) const Divider(height: 1),
      ],
    );
  }
}

class _ArquivoEixo {
  final String caminho;
  final String rodoviaPadrao;
  final String trechoPadrao;

  const _ArquivoEixo({
    required this.caminho,
    required this.rodoviaPadrao,
    required this.trechoPadrao,
  });
}

class _CoordenadaUtm {
  final double x;
  final double y;

  const _CoordenadaUtm({
    required this.x,
    required this.y,
  });
}

class _PontoEixo {
  final double xInicio;
  final double yInicio;
  final double xFim;
  final double yFim;
  final double progressoInicial;
  final double comprimento;

  const _PontoEixo({
    required this.xInicio,
    required this.yInicio,
    required this.xFim,
    required this.yFim,
    required this.progressoInicial,
    required this.comprimento,
  });
}

class _ResultadoEixo {
  final _EixoRodovia eixo;
  final double distancia;
  final double offsetAssinado;
  final double progresso;

  const _ResultadoEixo({
    required this.eixo,
    required this.distancia,
    required this.offsetAssinado,
    required this.progresso,
  });
}

class _EixoRodovia {
  final String obra;
  final String rodovia;
  final String trecho;
  final double estacaInicial;
  final List<_PontoEixo> segmentos;

  const _EixoRodovia({
    required this.obra,
    required this.rodovia,
    required this.trecho,
    required this.estacaInicial,
    required this.segmentos,
  });

  _ResultadoEixo? localizar({
    required double pontoX,
    required double pontoY,
  }) {
    _ResultadoEixo? melhor;

    for (final segmento in segmentos) {
      final dx = segmento.xFim - segmento.xInicio;
      final dy = segmento.yFim - segmento.yInicio;

      final comprimentoQuadrado = dx * dx + dy * dy;

      if (comprimentoQuadrado == 0) continue;

      final produtoEscalar = ((pontoX - segmento.xInicio) * dx) +
          ((pontoY - segmento.yInicio) * dy);

      final fator =
          (produtoEscalar / comprimentoQuadrado).clamp(0.0, 1.0).toDouble();

      final xProjetado = segmento.xInicio + fator * dx;
      final yProjetado = segmento.yInicio + fator * dy;

      final distancia = math.sqrt(
        (pontoX - xProjetado) * (pontoX - xProjetado) +
            (pontoY - yProjetado) * (pontoY - yProjetado),
      );

      final comprimentoVetorial = math.sqrt(comprimentoQuadrado);

      final produtoVetorial =
          dx * (pontoY - segmento.yInicio) - dy * (pontoX - segmento.xInicio);

      final offsetAssinado = produtoVetorial / comprimentoVetorial;

      final resultado = _ResultadoEixo(
        eixo: this,
        distancia: distancia,
        offsetAssinado: offsetAssinado,
        progresso: segmento.progressoInicial + fator * segmento.comprimento,
      );

      if (melhor == null || resultado.distancia < melhor.distancia) {
        melhor = resultado;
      }
    }

    return melhor;
  }
}
