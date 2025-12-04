import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/smart_money_signal.dart';
import '../models/ticker_24hr.dart';

class BinanceApi {
  static const String baseUrl = 'https://www.binance.com/bapi/futures/v1/public/future/smart-money/signal/list';
  static const String fbaseUrl = 'https://fapi.binance.com/fapi/v1';


  Future<List<SmartMoneySignal>> getSmartMoneySignals({String timeRange = 'ALL'}) async {
    try {
      final uri = Uri.parse('$baseUrl?timeRange=$timeRange');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final smartMoneyResponse = SmartMoneyResponse.fromJson(jsonData);
        
        if (smartMoneyResponse.code == '000000') {
          return smartMoneyResponse.data;
        } else {
          throw Exception('API返回错误: ${smartMoneyResponse.message}');
        }
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取数据失败: $e');
    } 
  }

  Future<List<Ticker24hr>> getTicker24hr() async {
    try {
      final uri = Uri.parse('$fbaseUrl/ticker/24hr');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        return jsonData.map((item) => Ticker24hr.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取数据失败: $e');
    }
  }


}

