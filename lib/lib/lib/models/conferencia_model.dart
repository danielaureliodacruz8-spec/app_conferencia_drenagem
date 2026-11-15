
import 'foto_model.dart';
import 'medicao_model.dart';

class Conferencia {
  final String id;
  String obra;
  String rodovia;
  String trecho;
  String estaca;
  String offset;
  String lado;
  String observacao;
  String dataCriacao;

  List<Medicao> medicoes;
  List<FotoConferencia> fotos;

  Conferencia({
    required this.id,
    required this.obra,
    required this.rodovia,
    required this.trecho,
    required this.estaca,
    required this.offset,
    required this.lado,
    required this.observacao,
    required this.dataCriacao,
    required this.medicoes,
    required this.fotos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'obra': obra,
      'rodovia': rodovia,
      'trecho': trecho,
      'estaca': estaca,
      'offset': offset,
      'lado': lado,
      'observacao': observacao,
      'dataCriacao': dataCriacao,
      'medicoes': medicoes.map((medicao) => medicao.toJson()).toList(),
      'fotos': fotos.map((foto) => foto.toJson()).toList(),
    };
  }

  factory Conferencia.fromJson(Map<String, dynamic> json) {
    final medicoesJson = json['medicoes'] as List<dynamic>? ?? [];
    final fotosJson = json['fotos'] as List<dynamic>? ?? [];

    return Conferencia(
      id: json['id']?.toString() ?? '',
      obra: json['obra']?.toString() ?? '',
      rodovia: json['rodovia']?.toString() ?? '',
      trecho: json['trecho']?.toString() ?? '',
      estaca: json['estaca']?.toString() ?? '',
      offset: json['offset']?.toString() ?? '',
      lado: json['lado']?.toString() ?? 'DIREITO',
      observacao: json['observacao']?.toString() ?? '',
      dataCriacao: json['dataCriacao']?.toString() ?? '',
      medicoes: medicoesJson
          .map(
            (item) => Medicao.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      fotos: fotosJson
          .map(
            (item) => FotoConferencia.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
	◦	
