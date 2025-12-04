class SmartMoneySignal {
  final String timeRange;
  final String symbol;
  final String side;
  final double netNotional;
  final double longNotional;
  final double shortNotional;
  final int longTraders;
  final int longWhales;
  final int shortTraders;
  final int shortWhales;
  final double longQty;
  final double shortQty;
  final double longAvgEntryPrice;
  final double shortAvgEntryPrice;

  SmartMoneySignal({
    required this.timeRange,
    required this.symbol,
    required this.side,
    required this.netNotional,
    required this.longNotional,
    required this.shortNotional,
    required this.longTraders,
    required this.longWhales,
    required this.shortTraders,
    required this.shortWhales,
    required this.longQty,
    required this.shortQty,
    required this.longAvgEntryPrice,
    required this.shortAvgEntryPrice,
  });

  factory SmartMoneySignal.fromJson(Map<String, dynamic> json) {
    return SmartMoneySignal(
      timeRange: json['timeRange'] as String,
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      netNotional: (json['netNotional'] as num).toDouble(),
      longNotional: (json['longNotional'] as num).toDouble(),
      shortNotional: (json['shortNotional'] as num).toDouble(),
      longTraders: json['longTraders'] as int,
      longWhales: json['longWhales'] as int,
      shortTraders: json['shortTraders'] as int,
      shortWhales: json['shortWhales'] as int,
      longQty: (json['longQty'] as num).toDouble(),
      shortQty: (json['shortQty'] as num).toDouble(),
      longAvgEntryPrice: (json['longAvgEntryPrice'] as num).toDouble(),
      shortAvgEntryPrice: (json['shortAvgEntryPrice'] as num).toDouble(),
    );
  }
}

class SmartMoneyResponse {
  final String code;
  final String? message;
  final String? messageDetail;
  final List<SmartMoneySignal> data;

  SmartMoneyResponse({
    required this.code,
    this.message,
    this.messageDetail,
    required this.data,
  });

  factory SmartMoneyResponse.fromJson(Map<String, dynamic> json) {
    return SmartMoneyResponse(
      code: json['code'] as String,
      message: json['message'] as String?,
      messageDetail: json['messageDetail'] as String?,
      data: (json['data'] as List<dynamic>)
          .map((item) => SmartMoneySignal.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
