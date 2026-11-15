class Medicao {
  final String id;
  String item;
  String valor;
  String situacao;
  String observacao;
  String data;

  Medicao({
    required this.id,
    required this.item,
    required this.valor,
    required this.situacao,
    required this.observacao,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item,
      'valor': valor,
      'situacao': situacao,
      'observacao': observacao,
      'data': data,
    };
  }

  factory Medicao.fromJson(Map<String, dynamic> json) {
    return Medicao(
      id: json['id']?.toString() ?? '',
      item: json['item']?.toString() ?? '',
      valor: json['valor']?.toString() ?? '',
      situacao: json['situacao']?.toString() ?? 'PENDENTE',
      observacao: json['observacao']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
    );
  }
}
