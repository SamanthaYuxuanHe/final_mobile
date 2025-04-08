import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'expense_model.dart';
import 'expense_database.dart';
import 'database_debug_page.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({Key? key}) : super(key: key);

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  List<Expense> _expenses = [];
  Expense? _selectedExpense;
  final _encryptedPrefs = EncryptedSharedPreferences();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await ExpenseDatabase.instance.getAllExpenses();
    setState(() {
      _expenses = expenses;
    });
  }

  Future<void> _showStartDialog() async {
    final lastExpenseJson = await _encryptedPrefs.getString('lastExpense');
    final hasPreviousExpense = lastExpenseJson.isNotEmpty;

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.copyPreviousExpense),
          content: Text(AppLocalizations.of(context)!.copyPreviousExpenseMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showExpenseForm(null, false);
              },
              child: Text(AppLocalizations.of(context)!.startBlank),
            ),
            TextButton(
              onPressed: hasPreviousExpense
                  ? () {
                Navigator.pop(context);
                _showExpenseForm(null, true);
              }
                  : null,
              child: Text(
                AppLocalizations.of(context)!.copyPrevious,
                style: TextStyle(
                  color: hasPreviousExpense ? null : Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // show
  void _showExpenseForm(Expense? expense, bool copyPrevious) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    if (isWideScreen && expense != null) {
      setState(() {
        _selectedExpense = expense;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExpenseFormDialog(
          expense: expense,
          copyPrevious: copyPrevious,
          onSave: (Expense newExpense) async {
            if (expense == null) {
              await ExpenseDatabase.instance.create(newExpense);
            } else {
              await ExpenseDatabase.instance.update(newExpense);
            }
            await _loadExpenses();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    expense == null
                        ? AppLocalizations.of(context)!.expenseAddedSuccessfully
                        : AppLocalizations.of(context)!.expenseUpdatedSuccessfully,
                  ),
                ),
              );
            }
          },
          onDelete: expense == null
              ? null
              : () async {
            await ExpenseDatabase.instance.delete(expense.id!);
            await _loadExpenses();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.expenseDeletedSuccessfully,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.expenseTracker),
        actions: [
          IconButton(
            icon: Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DatabaseDebugPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.howToUseTitle),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        Text('• ${AppLocalizations.of(context)!.addExpense}'),
                        Text('• ${AppLocalizations.of(context)!.expenseName}'),
                        Text('• ${AppLocalizations.of(context)!.category}'),
                        Text('• ${AppLocalizations.of(context)!.amount}'),
                        Text('• ${AppLocalizations.of(context)!.date}'),
                        Text('• ${AppLocalizations.of(context)!.paymentMethod}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  title: Text(expense.name),
                  subtitle: Text('\$${expense.amount.toStringAsFixed(2)}'),
                  onTap: () => setState(() => _selectedExpense = expense),
                  selected: _selectedExpense?.id == expense.id,
                );
              },
            ),
          ),
          if (_selectedExpense != null)
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.all(16),
                child: ExpenseFormDialog(
                  expense: _selectedExpense,
                  copyPrevious: false,
                  onSave: (Expense updatedExpense) async {
                    await ExpenseDatabase.instance.update(updatedExpense);
                    await _loadExpenses();
                    setState(() {
                      _selectedExpense = updatedExpense;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .expenseUpdatedSuccessfully,
                        ),
                      ),
                    );
                  },
                  onDelete: () async {
                    await ExpenseDatabase.instance.delete(_selectedExpense!.id!);
                    await _loadExpenses();
                    setState(() {
                      _selectedExpense = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .expenseDeletedSuccessfully,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      )
          : ListView.builder(
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          return ListTile(
            title: Text(expense.name),
            subtitle: Text('\$${expense.amount.toStringAsFixed(2)} - ${expense.category}'),
            onTap: () => _showExpenseForm(expense, false),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStartDialog,
        child: Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.addExpense,
      ),
    );
  }
}

class ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;
  final bool copyPrevious;
  final Function(Expense) onSave;
  final Function()? onDelete;

  const ExpenseFormDialog({
    Key? key,
    this.expense,
    required this.copyPrevious,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  _ExpenseFormDialogState createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _paymentMethodController;
  late String _selectedCategory;
  final _encryptedPrefs = EncryptedSharedPreferences();
  final List<String> _categories = ['Food', 'Transport', 'Entertainment', 'Bills', 'Other'];
  final List<String> _paymentMethods = ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _paymentMethodController = TextEditingController();
    _selectedCategory = _categories[0];
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    if (widget.expense != null) {
      setState(() {
        _nameController.text = widget.expense!.name;
        _amountController.text = widget.expense!.amount.toString();
        _dateController.text = widget.expense!.date;
        _selectedCategory = widget.expense!.category;
        _paymentMethodController.text = widget.expense!.paymentMethod;
      });
    } else if (widget.copyPrevious) {
      try {
        final lastExpenseJson = await _encryptedPrefs.getString('lastExpense');
        if (lastExpenseJson.isNotEmpty) {
          final Map<String, dynamic> lastExpense = json.decode(lastExpenseJson);
          setState(() {
            _nameController.text = lastExpense['name'] ?? '';
            _amountController.text = lastExpense['amount']?.toString() ?? '';
            _dateController.text = lastExpense['date'] ?? '';
            _selectedCategory = lastExpense['category'] ?? _categories[0];
            _paymentMethodController.text = lastExpense['paymentMethod'] ?? _paymentMethods[0];
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load previous expense data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveLastExpense() async {
    final expenseData = {
      'name': _nameController.text,
      'amount': double.parse(_amountController.text),
      'date': _dateController.text,
      'category': _selectedCategory,
      'paymentMethod': _paymentMethodController.text,
    };
    await _encryptedPrefs.setString('lastExpense', json.encode(expenseData));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null
          ? AppLocalizations.of(context)!.addExpense
          : AppLocalizations.of(context)!.update),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.expenseName,
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.pleaseEnterExpenseName
                    : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.amount,
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppLocalizations.of(context)!.pleaseEnterAmount;
                  }
                  if (double.tryParse(value!) == null) {
                    return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.category,
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.date,
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? AppLocalizations.of(context)!.pleaseSelectDate
                        : null,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _paymentMethodController.text.isEmpty
                    ? _paymentMethods[0]
                    : _paymentMethodController.text,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethodController.text = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.paymentMethod,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              await _saveLastExpense();
              widget.onSave(Expense(
                id: widget.expense?.id,
                name: _nameController.text,
                amount: double.parse(_amountController.text),
                date: _dateController.text,
                category: _selectedCategory,
                paymentMethod: _paymentMethodController.text,
              ));
            }
          },
          child: Text(widget.expense == null
              ? AppLocalizations.of(context)!.save
              : AppLocalizations.of(context)!.update),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }
}