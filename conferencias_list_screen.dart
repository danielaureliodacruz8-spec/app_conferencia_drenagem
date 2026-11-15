import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/conferencia_model.dart';
import 'conferencia_detail_screen.dart';
import 'conferencia_screen.dart';

class ConferenciasListScreen extends StatefulWidget {
  const ConferenciasListScreen({super.key});

  @override
  State<ConferenciasListScreen> createState() =>
      _ConferenciasListScreenState();
}

class _ConferenciasListScreenState extends State<ConferenciasListScreen> {
  List<Conferencia> conferencias = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarConferencias();
  }

  Future<void> carregarConferencias() async {
    final lista = await DatabaseHelper.carregarConferencias();

    if (!mounted) return;

    setState(() {
      conferencias = lista;
      carregando = false;
    });
  }

  Future<void> abrirNovaConferencia() async {
    final resultado = await Navigator.push<Conferencia>(
      context,
      MaterialPageRoute(
        builder: (context) => const ConferenciaScreen(),
      ),
    );

    if (resultado == null) return;

    setState(() {
      conferencias.add(resultado);
    });

    await DatabaseHelper.salvarConferencias(conferencias);
  }

  Future<void> abrirDetalhe(Conferencia conferencia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConferenciaDetailScreen(
          conferencia: conferencia,
          aoSalvar: () async {
            await DatabaseHelper.salvarConferencias(conferencias);

            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );

    await carregarConferencias();
  }

  Future<void> excluirConferencia(Conferencia conferencia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conferência?'),
          content: Text(
            'A conferência da estaca "${conferencia.estaca}" '
            'será excluída.',
          ),
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

    if (confirmar != true) return;

    setState(() {
      conferencias.removeWhere(
        (item) => item.id == conferencia.id,
      );
    });

    await DatabaseHelper.salvarConferencias(conferencias);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strata Conferência'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirNovaConferencia,
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : conferencias.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'Nenhuma conferência cadastrada.\n\n'
                      'Toque no botão “Nova” para criar uma conferência.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: carregarConferencias,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: conferencias.length,
                    itemBuilder: (context, index) {
                      final conferencia = conferencias[index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.assignment),
                          ),
                          title: Text(
                            conferencia.rodovia.isEmpty
                                ? 'Conferência'
                                : conferencia.rodovia,
                          ),
                          subtitle: Text(
                            'Estaca: ${conferencia.estaca}\n'
                            'Lado: ${conferencia.lado} • '
                            '${conferencia.dataCriacao}',
                          ),
                          isThreeLine: true,
                          onTap: () => abrirDetalhe(conferencia),
                          trailing: IconButton(
                            tooltip: 'Excluir',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              excluirConferencia(conferencia);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}