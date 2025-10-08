class HistoriAktivitas {
  final String id;
  final String action;
  final String? details;
  final DateTime createdAt;

  HistoriAktivitas({
    required this.id,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory HistoriAktivitas.fromJson(Map<String, dynamic> json) {
    return HistoriAktivitas(
      id: json['_id'],
      action: json['action'],
      details: json['details'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
