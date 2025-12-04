
class Ticker24hr {
  final String symbol;
  final double priceChangePercent;
  final double priceChange;
  final double weightedAvgPrice;
  final double lastPrice;
  final double lastQty;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;
  final int openTime;
  final int closeTime;
  final int firstId;
  final int lastId;
  final int count;

  Ticker24hr({
    required this.symbol,
    required this.priceChangePercent,
    required this.priceChange,
    required this.weightedAvgPrice,
    required this.lastPrice,
    required this.lastQty,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
    required this.openTime,
    required this.closeTime,
    required this.firstId,
    required this.lastId,
    required this.count,
  });

  factory Ticker24hr.fromJson(Map<String, dynamic> json) { 

    return Ticker24hr(
      symbol: json['symbol'] as String,
      priceChangePercent: num.parse(json['priceChangePercent']).toDouble(),
      priceChange: num.parse(json['priceChange']).toDouble(),
      weightedAvgPrice: num.parse(json['weightedAvgPrice']).toDouble(),
      lastPrice: num.parse(json['lastPrice']).toDouble(),
      lastQty: num.parse(json['lastQty']).toDouble(),
      openPrice: num.parse(json['openPrice']).toDouble(),
      highPrice: num.parse(json['highPrice']).toDouble(),
      lowPrice: num.parse(json['lowPrice']).toDouble(),
      volume: num.parse(json['volume']).toDouble(),
      quoteVolume: num.parse(json['quoteVolume']).toDouble(),
      openTime: (json['openTime'] as int),
      closeTime: (json['closeTime'] as int),
      firstId: (json['firstId'] as int),
      lastId: (json['lastId'] as int),
      count: (json['count'] as int),
    );
  }
}

class Ticker24hrResponse {
  final List<Ticker24hr> data;

  Ticker24hrResponse({
    required this.data,
  });

  factory Ticker24hrResponse.fromJson(Map<String, dynamic> json) {
    return Ticker24hrResponse(
      data: (json['data'] as List<dynamic>).map((item) => Ticker24hr.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}