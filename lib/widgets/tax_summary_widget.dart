// widgets/tax_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

// Data classes for tax calculation
class TaxSlab {
  final double minIncome;
  final double maxIncome;
  final double rate;
  final String description;

  const TaxSlab({
    required this.minIncome,
    required this.maxIncome,
    required this.rate,
    required this.description,
  });
}

class TaxSlabCalculation {
  final TaxSlab slab;
  final double taxableAmount;
  final double taxAmount;

  const TaxSlabCalculation({
    required this.slab,
    required this.taxableAmount,
    required this.taxAmount,
  });
}

class TaxCalculationResult {
  final double totalTaxBeforeCess;
  final double cess;
  final double totalTaxWithCess;
  final List<TaxSlabCalculation> slabCalculations;

  const TaxCalculationResult({
    required this.totalTaxBeforeCess,
    required this.cess,
    required this.totalTaxWithCess,
    required this.slabCalculations,
  });
}

class TaxSummaryWidget extends StatefulWidget {
  const TaxSummaryWidget({super.key});

  @override
  State<TaxSummaryWidget> createState() => _TaxSummaryWidgetState();
}

class _TaxSummaryWidgetState extends State<TaxSummaryWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _bankFilter = 'All';

  bool _inRange(DateTime d) {
    if (_startDate != null && d.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) return false;
    if (_endDate != null && d.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);

    final filteredExpenses = expenseProvider.expenses
        .where((e) => _inRange(e.date))
        .where((e) => _bankFilter == 'All' || e.paymentMethod.name == _bankFilter)
        .toList();
    final filteredIncomes = incomeProvider.incomes.where((i) => _inRange(i.date)).toList();

    final bankAccounts = <String>{'All', ...expenseProvider.expenses.map((e) => e.paymentMethod.name)}.toList()..sort();

    final totalIncome = filteredIncomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpenseBase = filteredExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalExpenseGst = filteredExpenses.fold(0.0, (s, e) => s + e.gstAmount);
    final profitOrLoss = totalIncome - totalExpenseBase;
    final taxableBase = profitOrLoss > 0 ? profitOrLoss : 0.0;
    final taxCalculation = _calculateIncomeTaxDetailed(taxableBase);
    final totalIncomeTax = taxCalculation.totalTaxWithCess;
    final taxCategory = _getTaxCategory(totalIncome);

    // No output GST on income. Treat slab-based income tax as payable base
    // and subtract expense GST (input credit) from it.
    final inputGstOnExpenses = totalExpenseGst;
    final double payableTax =
        (totalIncomeTax - inputGstOnExpenses).clamp(0.0, double.infinity).toDouble();

    final incomeSeries = _toSeries(filteredIncomes.map((i) => MapEntry(i.date, i.amount)).toList());
    final expenseSeries = _toSeries(filteredExpenses.map((e) => MapEntry(e.date, e.amount + e.gstAmount)).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_startDate == null ? 'Start date' : 'Start: ${_fmt(_startDate!)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_endDate == null ? 'End date' : 'End: ${_fmt(_endDate!)}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              onPressed: () => setState(() { _startDate = null; _endDate = null; _bankFilter = 'All'; }),
            ),
            DropdownButton<String>(
              value: _bankFilter,
              items: bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text('Bank: $b'))).toList(),
              onChanged: (v) => setState(() => _bankFilter = v ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _statCards(context,
          totalIncome: totalIncome,
          totalExpense: totalExpenseBase,
          profitOrLoss: profitOrLoss,
          inputGst: inputGstOnExpenses,
          payableTax: payableTax,
          incomeTax: totalIncomeTax,
        ),
        const SizedBox(height: 12),
        _Sparkline(incomeSeries: incomeSeries, expenseSeries: expenseSeries),
        const SizedBox(height: 12),
        _pieCategoryShare(filteredExpenses),
        const SizedBox(height: 12),
        _gstVsIncomeExpenseBar(
          totalIncome: totalIncome,
          totalExpenseBase: totalExpenseBase,
          totalExpenseGst: totalExpenseGst,
          incomeTax: totalIncomeTax,
        ),
        const SizedBox(height: 12),
        _TaxBreakdownWidget(taxCalculation: taxCalculation, taxCategory: taxCategory),
      ],
    );
  }

  Widget _statCards(
    BuildContext context, {
    required double totalIncome,
    required double totalExpense,
    required double profitOrLoss,
    required double inputGst,
    required double payableTax,
    required double incomeTax,
  }) {
    Widget card(String title, String value, Color color, IconData icon) => Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            card('Total Income', '₹${totalIncome.toStringAsFixed(2)}', Colors.green[700]!, Icons.trending_up_rounded),
            const SizedBox(width: 8),
            card('Total Expense', '₹${totalExpense.toStringAsFixed(2)}', Colors.red[700]!, Icons.trending_down_rounded),
            const SizedBox(width: 8),
            card(profitOrLoss >= 0 ? 'Profit' : 'Loss', '₹${(profitOrLoss >= 0 ? profitOrLoss : -profitOrLoss).toStringAsFixed(2)}', profitOrLoss >= 0 ? Colors.green[700]! : Colors.red[700]!, profitOrLoss >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            card('Income Tax (slab)', '₹${incomeTax.toStringAsFixed(2)}', Colors.indigo[700]!, Icons.receipt_long_rounded),
            const SizedBox(width: 8),
            card('Expense GST (credit)', '₹${inputGst.toStringAsFixed(2)}', Colors.orange[700]!, Icons.credit_score_rounded),
            const SizedBox(width: 8),
            card('Payable Tax', '₹${payableTax.toStringAsFixed(2)}', Colors.purple[700]!, Icons.account_balance_wallet_rounded),
          ],
        ),
      ],
    );
  }

  Widget _pieCategoryShare(List expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final Map<String, Map<String, double>> byCat = {};
    for (final e in expenses) {
      byCat.putIfAbsent(e.categoryName, () => {'base': 0, 'gst': 0});
      byCat[e.categoryName]!['base'] = byCat[e.categoryName]!['base']! + e.amount;
      byCat[e.categoryName]!['gst'] = byCat[e.categoryName]!['gst']! + e.gstAmount;
    }
    final top = byCat.entries.toList()
      ..sort((a, b) => (b.value['base']! + b.value['gst']!).compareTo(a.value['base']! + a.value['gst']!));
    final show = top.take(5).toList();
    final total = byCat.values.fold<double>(0, (s, m) => s + (m['base']! + m['gst']!));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.pie_chart_rounded, color: Colors.indigo[700]),
              const SizedBox(width: 8),
              Text('Category Spend Share', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[700])),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                  sections: [
                    for (int i = 0; i < show.length; i++)
                      PieChartSectionData(
                        value: (show[i].value['base']! + show[i].value['gst']!) / (total == 0 ? 1 : total) * 100,
                        color: Colors.primaries[i % Colors.primaries.length].withValues(alpha: 0.85),
                        title: '${((show[i].value['base']! + show[i].value['gst']!) / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%',
                        radius: 50 + (i * 6),
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (int i = 0; i < show.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, color: Colors.primaries[i % Colors.primaries.length]),
                      const SizedBox(width: 6),
                      Text('${show[i].key} (₹${(show[i].value['base']! + show[i].value['gst']!).toStringAsFixed(0)})', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gstVsIncomeExpenseBar({
    required double totalIncome,
    required double totalExpenseBase,
    required double totalExpenseGst,
    required double incomeTax,
  }) {
    final groups = [
      _barAt(0, totalIncome, Colors.green[600]!),
      _barAt(1, totalExpenseBase, Colors.red[600]!),
      _barAt(2, totalExpenseGst, Colors.orange[700]!),
      _barAt(3, incomeTax, Colors.indigo[700]!),
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.stacked_bar_chart_rounded, color: Colors.indigo[700]),
              const SizedBox(width: 8),
              Text('Income vs Expense vs Taxes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[700])),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          final label = (idx >= 0 && idx < _barLabels.length) ? _barLabels[idx] : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _barLabels = ['Income', 'Expense', 'GST', 'IT'];

  BarChartGroupData _barAt(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: value, color: color, width: 20, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  List<double> _toSeries(List<MapEntry<DateTime, double>> points) {
    points.sort((a, b) => a.key.compareTo(b.key));
    return points.map((e) => e.value).toList();
  }

  // Indian Income Tax Slabs for FY 2025-26 (Assessment Year 2026-27)
  static const List<TaxSlab> _taxSlabs = [
    TaxSlab(minIncome: 0, maxIncome: 400000, rate: 0.0, description: 'Up to ₹4,00,000'),
    TaxSlab(minIncome: 400001, maxIncome: 800000, rate: 0.05, description: '₹4,00,001 to ₹8,00,000'),
    TaxSlab(minIncome: 800001, maxIncome: 1200000, rate: 0.10, description: '₹8,00,001 to ₹12,00,000'),
    TaxSlab(minIncome: 1200001, maxIncome: 1600000, rate: 0.15, description: '₹12,00,001 to ₹16,00,000'),
    TaxSlab(minIncome: 1600001, maxIncome: 2000000, rate: 0.20, description: '₹16,00,001 to ₹20,00,000'),
    TaxSlab(minIncome: 2000001, maxIncome: 2400000, rate: 0.25, description: '₹20,00,001 to ₹24,00,000'),
    TaxSlab(minIncome: 2400001, maxIncome: double.infinity, rate: 0.30, description: 'Above ₹24,00,000'),
  ];

  TaxCalculationResult _calculateIncomeTaxDetailed(double income) {
    double totalTax = 0.0;
    List<TaxSlabCalculation> slabCalculations = [];
    
    for (final slab in _taxSlabs) {
      if (income <= slab.minIncome) break;
      
      final taxableAmount = (income > slab.maxIncome ? slab.maxIncome : income) - slab.minIncome;
      final taxOnThisSlab = taxableAmount * slab.rate;
      
      if (taxableAmount > 0) {
        totalTax += taxOnThisSlab;
        slabCalculations.add(TaxSlabCalculation(
          slab: slab,
          taxableAmount: taxableAmount,
          taxAmount: taxOnThisSlab,
        ));
      }
    }
    
    // Add Health and Education Cess (4%)
    final cess = totalTax * 0.04;
    final totalTaxWithCess = totalTax + cess;
    
    return TaxCalculationResult(
      totalTaxBeforeCess: totalTax,
      cess: cess,
      totalTaxWithCess: totalTaxWithCess,
      slabCalculations: slabCalculations,
    );
  }


  String _getTaxCategory(double income) {
    for (final slab in _taxSlabs) {
      if (income >= slab.minIncome && income <= slab.maxIncome) {
        return '${(slab.rate * 100).toInt()}% (${slab.description})';
      }
    }
    return '30% (Above ₹24,00,000)';
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _TaxBreakdownWidget extends StatelessWidget {
  final TaxCalculationResult taxCalculation;
  final String taxCategory;

  const _TaxBreakdownWidget({
    required this.taxCalculation,
    required this.taxCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Income Tax Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tax Category: $taxCategory',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Tax slabs breakdown
            ...taxCalculation.slabCalculations.map((calc) => _buildSlabRow(calc)),
            const Divider(),
            // Total tax before cess
            _buildSummaryRow(
              'Tax Before Cess',
              '₹${taxCalculation.totalTaxBeforeCess.toStringAsFixed(2)}',
              Colors.blue[700]!,
            ),
            // Cess
            _buildSummaryRow(
              'Health & Education Cess (4%)',
              '₹${taxCalculation.cess.toStringAsFixed(2)}',
              Colors.orange[700]!,
            ),
            const Divider(thickness: 2),
            // Total tax with cess
            _buildSummaryRow(
              'Total Income Tax',
              '₹${taxCalculation.totalTaxWithCess.toStringAsFixed(2)}',
              Colors.red[700]!,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlabRow(TaxSlabCalculation calc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              calc.slab.description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${calc.taxableAmount.toStringAsFixed(0)} × ${(calc.slab.rate * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${calc.taxAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? color : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> incomeSeries;
  final List<double> expenseSeries;
  const _Sparkline({required this.incomeSeries, required this.expenseSeries});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 120,
        child: CustomPaint(
          painter: _SparklinePainter(incomeSeries: incomeSeries, expenseSeries: expenseSeries),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> incomeSeries;
  final List<double> expenseSeries;
  _SparklinePainter({required this.incomeSeries, required this.expenseSeries});

  @override
  void paint(Canvas canvas, Size size) {
    void draw(List<double> series, Color color) {
      if (series.isEmpty) return;
      final maxVal = series.reduce((a, b) => a > b ? a : b);
      final minVal = series.reduce((a, b) => a < b ? a : b);
      final range = (maxVal - minVal).abs() < 1e-6 ? 1.0 : (maxVal - minVal);
      final dx = size.width / (series.length - 1).clamp(1, double.infinity);
      final path = Path();
      for (int i = 0; i < series.length; i++) {
        final x = i * dx;
        final norm = (series[i] - minVal) / range;
        final y = size.height - (norm * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }

    draw(incomeSeries, Colors.green[600]!);
    draw(expenseSeries, Colors.red[600]!);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.incomeSeries != incomeSeries || oldDelegate.expenseSeries != expenseSeries;
  }
}
