import 'package:flutter/material.dart';

import '../models/smart_money_signal.dart';
import '../services/binance_api.dart';

class SmartMoneyListScreen extends StatefulWidget {
  const SmartMoneyListScreen({super.key});

  @override
  State<SmartMoneyListScreen> createState() => _SmartMoneyListScreenState();
}

class _SmartMoneyListScreenState extends State<SmartMoneyListScreen> {
  final BinanceApi _api = BinanceApi();

  // 原始数据 & 筛选后数据
  List<SmartMoneySignal> _allSignals = [];
  List<SmartMoneySignal> _filteredSignals = [];

  // 状态
  bool _isLoading = true;
  String? _errorMessage;

  // timeRange 选项（由接口支持的枚举）
  final List<String> _timeRanges = ['30m', '1h', '24h', '7D', 'ALL'];
  String _selectedTimeRange = 'ALL';

  // symbol 模糊搜索
  final TextEditingController _searchController = TextEditingController();

  // 排序方式
  final List<String> _sortOptions = [
    '默认',
    '持仓数量',
    '多空名义比率',
    '交易者数量',
  ];
  String _selectedSort = '默认';

  String _selectedSortDirection = '降序';

  final List<String> _amountRangeOptions = [
    'ALL',
    '0-10k', // 0 到 1万
    '10k-10m', // 1万到 100万
    '10m-1b', // 100万到 10亿
    '>1b', // 10亿以上
  ];
  String _selectedAmountRange = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await _api.getSmartMoneySignals(timeRange: _selectedTimeRange);
      _allSignals = data;
      _applyFilter(); // 根据当前搜索关键字做一次本地筛选
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 根据当前搜索关键字对 _allSignals 做本地过滤，并应用排序
  void _applyFilter() {
    final keyword = _searchController.text.trim().toLowerCase();

    List<SmartMoneySignal> list;
    if (keyword.isEmpty) {
      list = List<SmartMoneySignal>.from(_allSignals);
    } else {
      list = _allSignals.where((s) {
        // symbol 模糊匹配，忽略大小写
        return s.symbol.toLowerCase().contains(keyword);
      }).toList();
    }



    _applySort(list);
    list = _applyAmountRangeFilter(list);

    setState(() {
      _filteredSignals = list;
    });
  }

  /// 根据当前排序方式对列表排序
  void _applySort(List<SmartMoneySignal> list) {
    int compareTo (num a, num b) {
      return _selectedSortDirection == '降序' ? a.compareTo(b) : b.compareTo(a);
    }
    switch (_selectedSort) {
      case '持仓数量':
        // 使用优势持仓大小排序（降序）
        list.sort(
          (a, b) => 
              compareTo(_getDominantPosition(b), _getDominantPosition(a)),
        );
      case '多空名义比率':
        list.sort(
          (a, b) => compareTo(_getLongShortRatio(b), _getLongShortRatio(a)),
        );
      case '交易者数量':
        list.sort(
          (a, b) =>
              compareTo((b.longTraders + b.shortTraders).toDouble(), (a.longTraders + a.shortTraders).toDouble()),
        );
      case '默认':
      default:
        // 不做任何排序，保持接口返回顺序
        break;
    }
  }

    /// 根据当前排序方式对列表排序
  List<SmartMoneySignal> _applyAmountRangeFilter(List<SmartMoneySignal> list) {
    switch (_selectedAmountRange) {
      case '0-10k':
        list = list.where((s) => _getDominantPosition(s) <= 10000).toList();
      case '10k-10m':
        list = list.where((s) => _getDominantPosition(s) > 10000 && _getDominantPosition(s) <= 10_000_000).toList();
      case '10m-1b':
        list = list.where((s) => _getDominantPosition(s) > 10_000_000 && _getDominantPosition(s) <= 1_000_000_000).toList();
      case '>1b':
        list = list.where((s) => _getDominantPosition(s) > 1_000_000_000).toList();
      case 'ALL':
      default:
        // 不做任何排序，保持接口返回顺序
        break;
    }
    return list;
  }

  void _onTimeRangeChanged(String? value) {
    if (value == null || value == _selectedTimeRange) return;
    setState(() {
      _selectedTimeRange = value;
    });
    _loadData(); // 更换时间周期，重新从接口获取
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }

  Color _getSideColor(String side) {
    return side == 'BUY' ? Colors.green : Colors.red;
  }

  /// 优势持仓：占主导一方（side）对应的名义价值
  double _getDominantPosition(SmartMoneySignal s) {
    return s.side == 'BUY' ? s.longNotional : s.shortNotional;
  }

  /// 名义多空比率：多头名义价值 / 空头名义价值 * 100%
  double _getLongShortRatio(SmartMoneySignal s) {
    if (s.shortNotional == 0) return 0;
    return (s.longNotional / s.shortNotional) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('币安聪明钱信号'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilter(),
            decoration: InputDecoration(
              hintText: '按交易对筛选，例如：BTC、ETH',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilter();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '时间范围：',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTimeRange,
                      isExpanded: true,
                      items: _timeRanges
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v),
                            ),
                          )
                          .toList(),
                      onChanged: _onTimeRangeChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '排序：',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      items: _sortOptions
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null || v == _selectedSort) return;
                        setState(() {
                          _selectedSort = v;
                        });
                        // 对当前过滤结果重新排序
                        _applyFilter();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSortDirection = _selectedSortDirection == '降序' ? '升序' : '降序';
                    });
                    _applyFilter();
                  },
                  child: Text(_selectedSortDirection),
              ),
              
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '持仓金额：',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedAmountRange,
                      isExpanded: true,
                      items: _amountRangeOptions
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null || v == _selectedAmountRange) return;
                        setState(() {
                          _selectedAmountRange = v;
                        });
                        // 对当前过滤结果重新排序
                        _applyFilter();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredSignals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _allSignals.isEmpty ? '暂无数据' : '未找到匹配的交易对',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _filteredSignals.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final s = _filteredSignals[index];
          final sideColor = _getSideColor(s.side);
          final dominant = _getDominantPosition(s);
          final ratio = _getLongShortRatio(s);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ExpansionTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: sideColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    s.symbol.replaceAll('USDT', ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: sideColor,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sideColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.side == 'BUY' ? '买入' : '卖出',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '优势持仓：',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatNumber(dominant),
                          style: TextStyle(
                            color: sideColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '名义多空比率：',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${ratio.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: sideColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '多头交易者：${s.longTraders} | ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '空头交易者：${s.shortTraders}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('时间范围', s.timeRange),
                      const Divider(),
                      _buildDetailRow(
                        '优势持仓',
                        _formatNumber(dominant),
                      ),
                      _buildDetailRow(
                        '名义多空比率',
                        '${ratio.toStringAsFixed(2)}%',
                      ),
                      _buildDetailRow(
                        '多头名义价值',
                        _formatNumber(s.longNotional),
                      ),
                      _buildDetailRow(
                        '空头名义价值',
                        _formatNumber(s.shortNotional),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        '多头交易者',
                        '${s.longTraders}',
                      ),
                      _buildDetailRow(
                        '多头鲸鱼',
                        '${s.longWhales}',
                      ),
                      _buildDetailRow(
                        '空头交易者',
                        '${s.shortTraders}',
                      ),
                      _buildDetailRow(
                        '空头鲸鱼',
                        '${s.shortWhales}',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        '多头数量',
                        s.longQty.toStringAsFixed(2),
                      ),
                      _buildDetailRow(
                        '空头数量',
                        s.shortQty.toStringAsFixed(2),
                      ),
                      _buildDetailRow(
                        '多头平均入场价',
                        s.longAvgEntryPrice.toStringAsFixed(2),
                      ),
                      _buildDetailRow(
                        '空头平均入场价',
                        s.shortAvgEntryPrice.toStringAsFixed(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}


