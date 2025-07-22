class RateInfo {
  final String label;
  final String days;
  final String timeRange;
  final double rate;

  RateInfo({
    required this.label,
    required this.days,
    required this.timeRange,
    required this.rate,
  });

  factory RateInfo.fromJson(Map<String, dynamic> json) {
    return RateInfo(
      label: json['label'] ?? 'N/A',
      days: json['days'] ?? 'N/A',
      timeRange: json['timeRange'] ?? 'N/A',
      rate: (json['rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'days': days,
        'timeRange': timeRange,
        'rate': rate,
      };
}

class Season {
  final String seasonName;
  final String startDate;
  final String endDate;
  final double fixedChargePerMonth;
  final List<RateInfo> buyRates;
  final List<RateInfo> sellRates;

  Season({
    required this.seasonName,
    required this.startDate,
    required this.endDate,
    required this.fixedChargePerMonth,
    required this.buyRates,
    required this.sellRates,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonName: json['seasonName'] ?? 'N/A',
      startDate: json['startDate'] ?? 'N/A',
      endDate: json['endDate'] ?? 'N/A',
      fixedChargePerMonth: (json['fixedChargePerMonth'] ?? 0.0).toDouble(),
      buyRates: (json['buyRates'] as List<dynamic>? ?? [])
          .map((e) => RateInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      sellRates: (json['sellRates'] as List<dynamic>? ?? [])
          .map((e) => RateInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonName': seasonName,
        'startDate': startDate,
        'endDate': endDate,
        'fixedChargePerMonth': fixedChargePerMonth,
        'buyRates': buyRates.map((e) => e.toJson()).toList(),
        'sellRates': sellRates.map((e) => e.toJson()).toList(),
      };
}

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
  final List<String> insights;
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
    required this.insights,
    required this.createdAt,
    required this.tags,
    required this.additionalData,
  });

  factory ElectricityBill.fromJson(Map<String, dynamic> json) {
    return ElectricityBill(
      id: json['id'] as String,
      userId: json['userId'] as String,
      imagePath: json['imagePath'] as String,
      extractedText: json['extractedText'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      billDate: DateTime.tryParse(json['billDate'] as String? ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      consumptionKwh: (json['consumptionKwh'] as num?)?.toDouble() ?? 0.0,
      ratePerKwh: (json['ratePerKwh'] as num?)?.toDouble() ?? 0.0,
      insights: (json['insights'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      additionalData: json['additionalData'] as Map<String, dynamic>? ?? {},
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
      'insights': insights,
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
    List<String>? insights,
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
      insights: insights ?? this.insights,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
