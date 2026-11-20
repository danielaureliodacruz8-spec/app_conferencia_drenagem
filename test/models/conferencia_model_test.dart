import 'package:flutter_test/flutter_test.dart';
import 'package:strata_conferencia/models/conferencia_model.dart';

void main() {
  test('Conferencia preserva dados ao converter para JSON e voltar', () {
    final original = Conferencia(
      id: '1',
      obra: 'GO-236',
      rodovia: 'GO-236',
      trecho: 'Trecho de teste',
      estaca: '0100+10.000',
      offset: '2.500',
      lado: 'DIREITO',
      observacao: 'Conferência de teste',
      dataCriacao: '19/11/2026 10:00',
      medicoes: [],
      fotos: [],
    );

    final recuperada = Conferencia.fromJson(original.toJson());

    expect(recuperada.id, original.id);
    expect(recuperada.rodovia, original.rodovia);
    expect(recuperada.estaca, original.estaca);
    expect(recuperada.offset, original.offset);
    expect(recuperada.lado, original.lado);
    expect(recuperada.observacao, original.observacao);
    expect(recuperada.medicoes, isEmpty);
    expect(recuperada.fotos, isEmpty);
  });
}
