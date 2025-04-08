import 'package:flutter/material.dart';
import 'expense_database.dart';
import 'expense_model.dart';

class DatabaseDebugPage extends StatefulWidget {
  const DatabaseDebugPage({Key? key}) : super(key: key);

  @override
  _DatabaseDebugPageState createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final expenses = await ExpenseDatabase.instance.getAllExpenses();
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Contents'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Refresh database contents',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Payment Method')),
            ],
            rows: _expenses.map((expense) {
              return DataRow(
                cells: [
                  DataCell(Text(expense.id?.toString() ?? 'null')),
                  DataCell(Text(expense.name)),
                  DataCell(Text('\$${expense.amount.toStringAsFixed(2)}')),
                  DataCell(Text(expense.date)),
                  DataCell(Text(expense.category)),
                  DataCell(Text(expense.paymentMethod)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}