class FotoConferencia {
  final String id;
  String caminhoImagem;
  String observacao;
  String data;

  FotoConferencia({
    required this.id,
    required this.caminhoImagem,
    required this.observacao,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caminhoImagem': caminhoImagem,
      'observacao': observacao,
      'data': data,
    };
  }

  factory FotoConferencia.fromJson(Map<String, dynamic> json) {
    return FotoConferencia(
      id: json['id']?.toString() ?? '',
      caminhoImagem: json['caminhoImagem']?.toString() ?? '',
      observacao: json['observacao']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
    );
  }
}
