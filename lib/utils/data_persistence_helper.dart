import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../providers/ca_provider.dart';

class DataPersistenceHelper {
  static Future<void> ensureDataLoaded(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final companyId = auth.companyId ?? auth.selectedCompany?.id;
    
    if (companyId != null) {
      // Load all necessary data for the current company
      await Future.wait([
        Provider.of<ExpenseProvider>(context, listen: false)
            .loadExpensesForCompany(companyId),
        Provider.of<IncomeProvider>(context, listen: false)
            .loadIncomesForCompany(companyId),
        Provider.of<CategoryProvider>(context, listen: false)
            .loadCategoriesForCompany(companyId),
        Provider.of<CAProvider>(context, listen: false)
            .loadCAsForCompany(companyId),
      ]);
    }
  }

  static Future<void> reloadCurrentCompanyData(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final companyId = auth.companyId ?? auth.selectedCompany?.id;
    
    if (companyId != null) {
      // Reload all data for the current company
      await Future.wait([
        Provider.of<ExpenseProvider>(context, listen: false)
            .reloadCurrentCompanyData(),
        Provider.of<IncomeProvider>(context, listen: false)
            .reloadCurrentCompanyData(),
        Provider.of<CategoryProvider>(context, listen: false)
            .loadCategoriesForCompany(companyId),
        Provider.of<CAProvider>(context, listen: false)
            .loadCAsForCompany(companyId),
      ]);
    }
  }

  static void clearAllData(BuildContext context) {
    Provider.of<ExpenseProvider>(context, listen: false).clearExpenses();
    Provider.of<IncomeProvider>(context, listen: false).clearIncomes();
    Provider.of<CategoryProvider>(context, listen: false).clearCategories();
    Provider.of<CAProvider>(context, listen: false).clearCAs();
  }
}
