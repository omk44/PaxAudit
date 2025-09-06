// widgets/tax_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

class TaxSummaryWidget extends StatelessWidget {
  const TaxSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final totalIncome = incomeProvider.totalIncome;
    final totalExpense = expenseProvider.totalExpense;
    final totalGstPaid = expenseProvider.totalGst;

    final isLoss = totalExpense > totalIncome;
    final profitOrLoss = totalIncome - totalExpense; // negative => loss

    final totalIncomeTax = _calculateIncomeTax(totalIncome);
    final payableTaxValue = (totalIncomeTax - totalGstPaid);
    final payableTaxClamped = payableTaxValue.clamp(0, double.infinity);
    final taxCategory = _getTaxCategory(totalIncome);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tax Summary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Total Income: ₹${totalIncome.toStringAsFixed(2)}'),
          Text('Total Expense: ₹${totalExpense.toStringAsFixed(2)}'),
          Text(
            profitOrLoss >= 0
                ? 'Profit: ₹${profitOrLoss.toStringAsFixed(2)}'
                : 'Loss: ₹${(-profitOrLoss).toStringAsFixed(2)}',
          ),
          Text(
            'Total Income Tax (slab): ₹${totalIncomeTax.toStringAsFixed(2)}',
          ),
          Text(
            isLoss
                ? 'Total Expense GST Paid: -₹${totalGstPaid.toStringAsFixed(2)}'
                : 'Total Expense GST Paid: ₹${totalGstPaid.toStringAsFixed(2)}',
          ),
          if (isLoss)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Expense greater than Income',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your expenses are more than your income till now. Try to increase your income otherwise your company will be at a loss. It is not possible to calculate GST on negative income. Payable tax is not applicable while in loss; GST paid will be treated as credit for future adjustment.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            isLoss
                ? 'Payable Tax: N/A (in loss)'
                : 'Payable Tax: ₹${payableTaxClamped.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Income Tax Slab: $taxCategory'),
        ],
      ),
    );
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
}
