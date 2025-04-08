import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'dart:convert';
import 'expense_model.dart';
import 'expense_database.dart';
import 'database_debug_page.dart';

/// A stateful widget that displays and manages expenses.
///
/// This page provides a UI for users to view, add, edit, and delete expenses.
/// It includes features like copying previous expense data and responsive
/// layout for different screen sizes.
class ExpenseTrackerPage extends StatefulWidget {
  /// Creates an instance of [ExpenseTrackerPage].
  const ExpenseTrackerPage({super.key});

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

/// The state for [ExpenseTrackerPage].
///
/// Manages the list of expenses, the currently selected expense,
/// and provides methods for CRUD operations on expenses.
class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  /// List of all expenses retrieved from the database.
  List<Expense> _expenses = [];

  /// Currently selected expense for viewing or editing in wide screen layouts.
  Expense? _selectedExpense;

  /// Instance of encrypted shared preferences for securely storing data.
  final _encryptedPrefs = EncryptedSharedPreferences();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  /// Loads all expenses from the database and updates the state.
  ///
  /// This method is called during initialization and after any changes
  /// to the expense data.
  Future<void> _loadExpenses() async {
    final expenses = await ExpenseDatabase.instance.getAllExpenses();
    setState(() {
      _expenses = expenses;
    });
  }

  /// Shows a dialog asking if the user wants to start with a blank form
  /// or copy data from the previous expense.
  ///
  /// The "Copy Previous" option is only enabled if there's a saved expense.
  Future<void> _showStartDialog() async {
    final lastExpenseJson = await _encryptedPrefs.getString('lastExpense');
    final hasPreviousExpense = lastExpenseJson.isNotEmpty;

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translate('copyPreviousExpense')),
          content: Text(translate('copyPreviousExpenseMessage')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showExpenseForm(null, false);
              },
              child: Text(translate('startBlank')),
            ),
            TextButton(
              onPressed: hasPreviousExpense
                  ? () {
                      Navigator.pop(context);
                      _showExpenseForm(null, true);
                    }
                  : null,
              child: Text(
                translate('copyPrevious'),

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

  /// Shows an expense form for adding or editing expenses.
  ///
  /// In wide screen layouts, the form is shown in a side panel.
  /// In narrow layouts, the form is shown in a dialog.
  ///
  /// [expense] is the expense to edit, or null to create a new expense.
  /// [copyPrevious] determines whether to populate the form with data from
  /// the previously saved expense.
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
                        ? translate('expenseAddedSuccessfully')
                        : translate('expenseUpdatedSuccessfully'),
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
                          translate('expenseDeletedSuccessfully'),
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
        title: Text(translate('expenseTracker')),
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
                  title: Text(translate('howToUseTitle')),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        Text('• ${translate('addExpense')}'),
                        Text('• ${translate('expenseName')}'),
                        Text('• ${translate('category')}'),
                        Text('• ${translate('amount')}'),
                        Text('• ${translate('date')}'),
                        Text('• ${translate('paymentMethod')}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(translate('ok')),
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
                        subtitle:
                            Text('\$${expense.amount.toStringAsFixed(2)}'),
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
                                translate('expenseUpdatedSuccessfully'),
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          await ExpenseDatabase.instance
                              .delete(_selectedExpense!.id!);
                          await _loadExpenses();
                          setState(() {
                            _selectedExpense = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                translate('expenseDeletedSuccessfully'),
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
                  subtitle: Text(
                      '\$${expense.amount.toStringAsFixed(2)} - ${expense.category}'),
                  onTap: () => _showExpenseForm(expense, false),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStartDialog,
        child: Icon(Icons.add),
        tooltip: translate('addExpense'),
      ),
    );
  }
}

/// A dialog that displays a form for adding or editing expenses.
///
/// This widget can be used both as a dialog in narrow layouts and
/// as a panel in wide layouts.
class ExpenseFormDialog extends StatefulWidget {
  /// The expense to edit, or null to create a new expense.
  final Expense? expense;

  /// Whether to populate the form with data from the previously saved expense.
  final bool copyPrevious;

  /// Callback function called when the user saves an expense.
  final Function(Expense) onSave;

  /// Callback function called when the user deletes an expense.
  /// This is null when creating a new expense.
  final Function()? onDelete;

  /// Creates an instance of [ExpenseFormDialog].
  ///
  /// The [copyPrevious] parameter determines whether to populate the form
  /// with data from the previously saved expense.
  /// The [onSave] callback is called when the user saves an expense.
  /// The [onDelete] callback is called when the user deletes an expense.

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

/// The state for [ExpenseFormDialog].
///
/// Manages the form controllers and validation for expense data.
class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  /// Key for the form to enable validation.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the expense name field.
  late TextEditingController _nameController;

  /// Controller for the expense amount field.
  late TextEditingController _amountController;

  /// Controller for the expense date field.
  late TextEditingController _dateController;

  /// Controller for the expense payment method field.
  late TextEditingController _paymentMethodController;

  /// Currently selected category.
  late String _selectedCategory;

  /// Instance of encrypted shared preferences for securely storing data.
  final _encryptedPrefs = EncryptedSharedPreferences();

  /// List of available expense categories.
  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Bills',
    'Other'
  ];

  /// List of available payment methods.
  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer'
  ];

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

  /// Initializes form controllers based on the provided expense or the last saved expense.
  ///
  /// If [widget.expense] is not null, the form is populated with its data.
  /// If [widget.copyPrevious] is true, the form is populated with data from
  /// the previously saved expense.
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
            _paymentMethodController.text =
                lastExpense['paymentMethod'] ?? _paymentMethods[0];
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(translate('failedToLoadPreviousExpenseData')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Shows a date picker and updates the date field with the selected date.
  ///
  /// The date is formatted as YYYY-MM-DD.
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

  /// Saves the current expense data to encrypted shared preferences.
  ///
  /// This data can be used to pre-fill the form when creating a new expense.
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
          ? translate('addExpense')
          : translate('update')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: translate('expenseName'),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? translate('pleaseEnterExpenseName')
                    : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: translate('amount'),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return translate('pleaseEnterAmount');
                  }
                  if (double.tryParse(value!) == null) {
                    return translate('pleaseEnterValidNumber');
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
                  labelText: translate('category'),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: translate('date'),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? translate('pleaseSelectDate')
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
                  labelText: translate('paymentMethod'),
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
              translate('delete'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(translate('cancel')),
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
          child: Text(
              widget.expense == null ? translate('save') : translate('update')),
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
