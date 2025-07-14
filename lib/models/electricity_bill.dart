class ElectricityBill {
  final String id;
  final String userId;
  final String imagePath;
  final String extractedText;
  final String summary;
  final DateTime billDate;
  final double totalAmount;
  final double consumptionKwh;
  final double ratePerKwh;
  final DateTime createdAt;
  final List<String> tags;
  final Map<String, dynamic> additionalData;

  ElectricityBill({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.extractedText,
    required this.summary,
    required this.billDate,
    required this.totalAmount,
    required this.consumptionKwh,
    required this.ratePerKwh,
    required this.createdAt,
    this.tags = const [],
    this.additionalData = const {},
  });

  factory ElectricityBill.fromJson(Map<String, dynamic> json) {
    return ElectricityBill(
      id: json['id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      extractedText: json['extractedText'],
      summary: json['summary'],
      billDate: DateTime.parse(json['billDate']),
      totalAmount: json['totalAmount'].toDouble(),
      consumptionKwh: json['consumptionKwh'].toDouble(),
      ratePerKwh: json['ratePerKwh'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      tags: List<String>.from(json['tags'] ?? []),
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'summary': summary,
      'billDate': billDate.toIso8601String(),
      'totalAmount': totalAmount,
      'consumptionKwh': consumptionKwh,
      'ratePerKwh': ratePerKwh,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'additionalData': additionalData,
    };
  }

  ElectricityBill copyWith({
    String? id,
    String? userId,
    String? imagePath,
    String? extractedText,
    String? summary,
    DateTime? billDate,
    double? totalAmount,
    double? consumptionKwh,
    double? ratePerKwh,
    DateTime? createdAt,
    List<String>? tags,
    Map<String, dynamic>? additionalData,
  }) {
    return ElectricityBill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      billDate: billDate ?? this.billDate,
      totalAmount: totalAmount ?? this.totalAmount,
      consumptionKwh: consumptionKwh ?? this.consumptionKwh,
      ratePerKwh: ratePerKwh ?? this.ratePerKwh,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
