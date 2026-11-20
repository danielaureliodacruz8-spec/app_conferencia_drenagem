import 'dart:io';

import 'package:flutter/material.dart';

import '../models/conferencia_model.dart';

class ConferenciaDetailScreen extends StatefulWidget {
  final Conferencia conferencia;
  final Future<void> Function() aoSalvar;

  const ConferenciaDetailScreen({
    super.key,
    required this.conferencia,
    required this.aoSalvar,
  });

  @override
  State<ConferenciaDetailScreen> createState() =>
      _ConferenciaDetailScreenState();
}

class _ConferenciaDetailScreenState extends State<ConferenciaDetailScreen> {
  late final TextEditingController _observacaoController;

  @override
  void initState() {
    super.initState();

    _observacaoController = TextEditingController(
      text: widget.conferencia.observacao,
    );
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    widget.conferencia.observacao = _observacaoController.text.trim();

    await widget.aoSalvar();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conferência atualizada com sucesso.'),
      ),
    );
  }

  Future<void> _excluirMedicao(int index) async {
    final confirmar = await _confirmarExclusao(
      titulo: 'Excluir medição?',
      mensagem: 'Esta medição será removida da conferência.',
    );

    if (!confirmar) return;

    setState(() {
      widget.conferencia.medicoes.removeAt(index);
    });

    await widget.aoSalvar();
  }

  Future<void> _excluirFoto(int index) async {
    final confirmar = await _confirmarExclusao(
      titulo: 'Excluir foto?',
      mensagem: 'Esta foto será removida da conferência.',
    );

    if (!confirmar) return;

    setState(() {
      widget.conferencia.fotos.removeAt(index);
    });

    await widget.aoSalvar();
  }

  Future<bool> _confirmarExclusao({
    required String titulo,
    required String mensagem,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  String _valor(String valor) {
    return valor.trim().isEmpty ? '-' : valor;
  }

  String _formatarChave(String chave) {
    if (chave.isEmpty) return chave;

    final texto = chave.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return texto[0].toUpperCase() + texto.substring(1);
  }

  String _textoMedicao(Map<String, dynamic> dados) {
    final linhas = <String>[];

    dados.forEach((chave, valor) {
      if (valor == null || valor.toString().trim().isEmpty) {
        return;
      }

      if (chave == 'id') return;

      linhas.add('${_formatarChave(chave)}: $valor');
    });

    return linhas.isEmpty ? 'Medição sem dados.' : linhas.join('\n');
  }

  String _caminhoFoto(Map<String, dynamic> dados) {
    const chavesPossiveis = [
      'caminhoImagem',
      'caminho',
      'path',
      'arquivo',
      'imagem',
      'foto',
      'url',
    ];

    for (final chave in chavesPossiveis) {
      final valor = dados[chave];

      if (valor != null && valor.toString().trim().isNotEmpty) {
        return valor.toString();
      }
    }

    return '';
  }

  void _abrirFoto(String caminho) {
    if (caminho.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        final arquivoExiste =
            !caminho.startsWith('http') && File(caminho).existsSync();

        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 500,
                child: InteractiveViewer(
                  child: Center(
                    child: caminho.startsWith('http')
                        ? Image.network(
                            caminho,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _fotoIndisponivel(),
                          )
                        : arquivoExiste
                            ? Image.file(
                                File(caminho),
                                fit: BoxFit.contain,
                              )
                            : _fotoIndisponivel(),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF003A70);
    final conferencia = widget.conferencia;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detalhes da conferência'),
        backgroundColor: azul,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Salvar alterações',
            onPressed: _salvar,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: azul.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: azul,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _valor(conferencia.rodovia),
                          style: const TextStyle(
                            color: azul,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _valor(conferencia.trecho),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _tituloSecao(
            icone: Icons.location_on_outlined,
            titulo: 'Localização automática',
          ),
          const SizedBox(height: 10),
          _card(
            children: [
              _linha(
                icone: Icons.business_outlined,
                titulo: 'Obra',
                valor: _valor(conferencia.obra),
              ),
              _linha(
                icone: Icons.route_outlined,
                titulo: 'Rodovia',
                valor: _valor(conferencia.rodovia),
              ),
              _linha(
                icone: Icons.alt_route_outlined,
                titulo: 'Trecho',
                valor: _valor(conferencia.trecho),
              ),
              _linha(
                icone: Icons.straighten_outlined,
                titulo: 'Estaca',
                valor: _valor(conferencia.estaca),
              ),
              _linha(
                icone: Icons.swap_horiz_outlined,
                titulo: 'Offset',
                valor: conferencia.offset.trim().isEmpty
                    ? '-'
                    : '${conferencia.offset} m',
              ),
              _linha(
                icone: Icons.compare_arrows_outlined,
                titulo: 'Lado',
                valor: _valor(conferencia.lado),
                divisor: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _tituloSecao(
            icone: Icons.straighten_outlined,
            titulo: 'Medições',
          ),
          const SizedBox(height: 10),
          _card(
            children: [
              if (conferencia.medicoes.isEmpty)
                _mensagemVazia(
                  icone: Icons.rule_outlined,
                  mensagem: 'Nenhuma medição registrada.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conferencia.medicoes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final medicao = conferencia.medicoes[index];
                    final dados = medicao.toJson();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: azul.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: azul,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _textoMedicao(dados),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Excluir medição',
                            onPressed: () => _excluirMedicao(index),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          _tituloSecao(
            icone: Icons.photo_library_outlined,
            titulo: 'Registro fotográfico',
          ),
          const SizedBox(height: 10),
          if (conferencia.fotos.isEmpty)
            _card(
              children: [
                _mensagemVazia(
                  icone: Icons.no_photography_outlined,
                  mensagem: 'Nenhuma foto registrada.',
                ),
              ],
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: conferencia.fotos.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final foto = conferencia.fotos[index];
                final caminho = _caminhoFoto(foto.toJson());

                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _abrirFoto(caminho),
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.expand(
                          child: _imagemFoto(caminho),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: InkWell(
                        onTap: () => _excluirFoto(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 20),
          _tituloSecao(
            icone: Icons.note_alt_outlined,
            titulo: 'Observações',
          ),
          const SizedBox(height: 10),
          _card(
            children: [
              TextField(
                controller: _observacaoController,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Digite as observações da conferência...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _tituloSecao(
            icone: Icons.info_outline,
            titulo: 'Informações do registro',
          ),
          const SizedBox(height: 10),
          _card(
            children: [
              _linha(
                icone: Icons.tag_outlined,
                titulo: 'Código',
                valor: _valor(conferencia.id),
              ),
              _linha(
                icone: Icons.calendar_today_outlined,
                titulo: 'Data de criação',
                valor: _valor(conferencia.dataCriacao),
                divisor: false,
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _salvar,
            style: FilledButton.styleFrom(
              backgroundColor: azul,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar alterações'),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _imagemFoto(String caminho) {
    if (caminho.startsWith('http')) {
      return Image.network(
        caminho,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fotoIndisponivel(),
      );
    }

    if (caminho.isNotEmpty && File(caminho).existsSync()) {
      return Image.file(
        File(caminho),
        fit: BoxFit.cover,
      );
    }

    return _fotoIndisponivel();
  }

  Widget _fotoIndisponivel() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _tituloSecao({
    required IconData icone,
    required String titulo,
  }) {
    return Row(
      children: [
        Icon(icone, color: const Color(0xFF003A70)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF003A70),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _card({
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _mensagemVazia({
    required IconData icone,
    required String mensagem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icone,
              color: Colors.grey,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha({
    required IconData icone,
    required String titulo,
    required String valor,
    bool divisor = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icone,
                color: const Color(0xFF003A70),
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  valor,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF003A70),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (divisor) const Divider(height: 1),
      ],
    );
  }
}
