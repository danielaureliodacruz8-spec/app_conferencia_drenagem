import 'package:flutter/material.dart';

import '../models/conferencia_model.dart';

class ConferenciaScreen extends StatefulWidget {
  const ConferenciaScreen({super.key});

  @override
  State<ConferenciaScreen> createState() => _ConferenciaScreenState();
}

class _ConferenciaScreenState extends State<ConferenciaScreen> {
  final _obraController = TextEditingController();
  final _rodoviaController = TextEditingController();
  final _trechoController = TextEditingController();
  final _estacaController = TextEditingController();
  final _offsetController = TextEditingController();
  final _observacaoController = TextEditingController();

  String _lado = 'DIREITO';

  @override
  void dispose() {
    _obraController.dispose();
    _rodoviaController.dispose();
    _trechoController.dispose();
    _estacaController.dispose();
    _offsetController.dispose();
    _observacaoController.dispose();
    super.dispose();
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
    if (_estacaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe pelo menos a estaca.'),
        ),
      );
      return;
    }

    final conferencia = Conferencia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      obra: _obraController.text.trim(),
      rodovia: _rodoviaController.text.trim(),
      trecho: _trechoController.text.trim(),
      estaca: _estacaController.text.trim(),
      offset: _offsetController.text.trim(),
      lado: _lado,
      observacao: _observacaoController.text.trim(),
      dataCriacao: _dataAgora(),
      medicoes: [],
      fotos: [],
    );

    Navigator.pop(context, conferencia);
  }

  Widget _campo({
    required TextEditingController controller,
    required String titulo,
    TextInputType tipoTeclado = TextInputType.text,
    int linhas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: tipoTeclado,
        maxLines: linhas,
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova conferência'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _campo(
            controller: _obraController,
            titulo: 'Obra',
          ),
          _campo(
            controller: _rodoviaController,
            titulo: 'Rodovia',
          ),
          _campo(
            controller: _trechoController,
            titulo: 'Trecho',
          ),
          _campo(
            controller: _estacaController,
            titulo: 'Estaca *',
          ),
          _campo(
            controller: _offsetController,
            titulo: 'Offset (m)',
            tipoTeclado: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const Text(
            'Lado da rodovia',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _lado,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'DIREITO',
                child: Text('DIREITO'),
              ),
              DropdownMenuItem(
                value: 'ESQUERDO',
                child: Text('ESQUERDO'),
              ),
              DropdownMenuItem(
                value: 'EIXO',
                child: Text('EIXO'),
              ),
            ],
            onChanged: (valor) {
              if (valor == null) return;

              setState(() {
                _lado = valor;
              });
            },
          ),
          const SizedBox(height: 14),
          _campo(
            controller: _observacaoController,
            titulo: 'Observação geral',
            linhas: 4,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Salvar conferência'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}