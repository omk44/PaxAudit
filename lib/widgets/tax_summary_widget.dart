// widgets/tax_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

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
    final isLoss = totalExpenseBase > totalIncome;
    final profitOrLoss = totalIncome - totalExpenseBase;
    final taxableBase = profitOrLoss > 0 ? profitOrLoss : 0.0;
    final totalIncomeTax = _calculateIncomeTax(taxableBase);
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
        _topCategories(filteredExpenses),
        const SizedBox(height: 8),
        Text('Income Tax Slab: $taxCategory', style: TextStyle(color: Colors.grey[700])),
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
    final isProfit = profitOrLoss >= 0;
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
            card(isProfit ? 'Profit' : 'Loss', '₹${(isProfit ? profitOrLoss : -profitOrLoss).toStringAsFixed(2)}', isProfit ? Colors.green[700]! : Colors.red[700]!, isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
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

  Widget _topCategories(List expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final Map<String, Map<String, double>> byCat = {};
    for (final e in expenses) {
      byCat.putIfAbsent(e.categoryName, () => {'base': 0, 'gst': 0});
      byCat[e.categoryName]!['base'] = byCat[e.categoryName]!['base']! + e.amount;
      byCat[e.categoryName]!['gst'] = byCat[e.categoryName]!['gst']! + e.gstAmount;
    }
    final top = byCat.entries.toList()
      ..sort((a, b) => (b.value['base']! + b.value['gst']!).compareTo(a.value['base']! + a.value['gst']!));
    final show = top.take(3).toList();

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
              Text('Top Expense Categories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[700])),
            ]),
            const SizedBox(height: 8),
            ...show.map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_rounded),
              title: Text(e.key),
              subtitle: Text('GST: ₹${e.value['gst']!.toStringAsFixed(2)}'),
              trailing: Text('₹${(e.value['base']! + e.value['gst']!).toStringAsFixed(2)}'),
            )),
          ],
        ),
      ),
    );
  }

  List<double> _toSeries(List<MapEntry<DateTime, double>> points) {
    points.sort((a, b) => a.key.compareTo(b.key));
    return points.map((e) => e.value).toList();
  }

  double _calculateIncomeTax(double income) {
    if (income <= 400000) return 0;
    if (income <= 800000) return (income - 400000) * 0.05;
    if (income <= 1200000) return 20000 + (income - 800000) * 0.10;
    if (income <= 1800000) return 60000 + (income - 1200000) * 0.15;
    return 150000 + (income - 1800000) * 0.30;
  }

  String _getTaxCategory(double income) {
    if (income <= 400000) return '0% (Up to ₹4,00,000)';
    if (income <= 800000) return '5% (₹4,00,001 – ₹8,00,000)';
    if (income <= 1200000) return '10% (₹8,00,001 – ₹12,00,000)';
    if (income <= 1800000) return '15% (₹12,00,001 – ₹18,00,000)';
    return '30% (Above ₹18,00,000)';
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
