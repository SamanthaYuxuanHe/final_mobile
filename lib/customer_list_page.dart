import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'customer_list.dart';
import 'database.dart';

/// A StatefulWidget that displays a list of customers.
///
/// This widget serves as the main page for viewing, adding, and managing customers.
/// It adapts its layout based on the screen size, showing either a standard list view
/// or a master-detail view on wider screens.
class CustomerListPage extends StatefulWidget {
  /// Creates a CustomerListPage.
  ///
  /// The [key] parameter is optional and is passed to the superclass.
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

/// The state for [CustomerListPage].
///
/// Manages the database connection, customer list retrieval, and UI state.
class _CustomerListPageState extends State<CustomerListPage> {
  /// Future that resolves to the app's database instance.
  late Future<AppDatabase> _databaseFuture;

  /// Future that resolves to the list of customers from the database.
  Future<List<Customer>>? _customersFuture;

  /// The currently selected customer in master-detail view.
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  /// Initializes the database connection.
  ///
  /// Creates a Future that will resolve to the database instance.
  void _initializeDatabase() {
    _databaseFuture =
        $FloorAppDatabase.databaseBuilder('app_database.db').build();
  }

  /// Refreshes the list of customers from the database.
  ///
  /// Updates the state to trigger a UI rebuild with the latest customer data.
  ///
  /// [database] The database instance to query.
  void _refreshCustomers(AppDatabase database) {
    setState(() {
      _customersFuture = database.customerDao.getAllCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(translate('customer.list')),
          actions: [
            IconButton(
              icon: Icon(Icons.language),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(translate('language.select')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text('English'),
                          onTap: () {
                            changeLocale(context, 'en');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text('中文'),
                          onTap: () {
                            changeLocale(context, 'zh');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<AppDatabase>(
            future: _databaseFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text(translate('customer.error')));
              } else {
                final database = snapshot.data!;
                final size = MediaQuery.of(context).size;
                final isWideScreen =
                    size.width > size.height && size.width > 720;

                return isWideScreen
                    ? _buildWideLayout(database)
                    : _buildNormalLayout(database);
              }
            }));
  }

  /// Builds a standard single-column layout for narrow screens.
  ///
  /// Shows a list of customers that navigate to a detail page when tapped,
  /// with an add button at the bottom.
  ///
  /// [database] The database instance to query for customer data.
  /// Returns a Widget representing the narrow screen layout.
  Widget _buildNormalLayout(AppDatabase database) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: FutureBuilder<List<Customer>>(
            future: database.customerDao.getAllCustomers(),
            builder: (context, customers) {
              if (customers.hasData && customers.data!.isNotEmpty) {
                return ListView.builder(
                  itemCount: customers.data!.length,
                  itemBuilder: (context, index) {
                    final customer = customers.data![index];
                    return ListTile(
                      title: Text("${customer.firstName} ${customer.lastName}"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetailPage(
                            database: database,
                            customer: customer,
                          ),
                        ),
                      ).then((_) => _refreshCustomers(database)),
                    );
                  },
                );
              } else {
                return Center(
                  child: Text(translate('customer.no_customers')),
                );
              }
            },
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCustomerPage(database: database),
              ),
            ).then((_) => _refreshCustomers(database));
          },
          child: Text(translate('customer.add')),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  /// Builds a two-column master-detail layout for wide screens.
  ///
  /// Shows a list of customers on the left side and the selected customer's details
  /// on the right side, with an add button at the bottom of the list.
  ///
  /// [database] The database instance to query for customer data.
  /// Returns a Widget representing the wide screen layout.
  Widget _buildWideLayout(AppDatabase database) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Customer>>(
                  future: database.customerDao.getAllCustomers(),
                  builder: (context, customers) {
                    if (customers.hasData && customers.data!.isNotEmpty) {
                      return ListView.builder(
                        itemCount: customers.data!.length,
                        itemBuilder: (context, index) {
                          final customer = customers.data![index];
                          return ListTile(
                            title: Text(
                                "${customer.firstName} ${customer.lastName}"),
                            selected: _selectedCustomer?.id == customer.id,
                            onTap: () {
                              setState(() {
                                _selectedCustomer = customer;
                              });
                            },
                          );
                        },
                      );
                    } else {
                      return Center(
                        child: Text(translate('customer.no_customers')),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddCustomerPage(database: database),
                      ),
                    );
                    if (shouldRefresh == true) {
                      _refreshCustomers(database);
                    }
                  },
                  child: Text(translate('customer.add')),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: _selectedCustomer != null
              ? CustomerDetailPage(
                  database: database,
                  customer: _selectedCustomer!,
                  onCustomerUpdated: () {
                    _refreshCustomers(database);
                    setState(() {
                      _selectedCustomer = null;
                    });
                  },
                )
              : Center(child: Text(translate('customer.select'))),
        ),
      ],
    );
  }
}

/// A StatefulWidget for adding a new customer to the database.
///
/// Provides a form with text fields for entering customer details,
/// and saves them to the database when submitted.
class AddCustomerPage extends StatefulWidget {
  /// The database instance to use for adding the customer.
  final AppDatabase database;

  /// Creates an AddCustomerPage.
  ///
  /// The [database] parameter is required and provides the database connection.
  /// The [key] parameter is optional and is passed to the superclass.
  const AddCustomerPage({super.key, required this.database});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

/// The state for [AddCustomerPage].
///
/// Manages form controllers, encrypted preferences for saving form data,
/// and customer creation operations.
class _AddCustomerPageState extends State<AddCustomerPage> {
  /// Controller for the first name text field.
  final TextEditingController firstNameController = TextEditingController();

  /// Controller for the last name text field.
  final TextEditingController lastNameController = TextEditingController();

  /// Controller for the address text field.
  final TextEditingController addressController = TextEditingController();

  /// Controller for the birthday text field.
  final TextEditingController birthdayController = TextEditingController();

  /// Encrypted shared preferences instance for securely storing form data.
  final EncryptedSharedPreferences encryptedPrefs =
      EncryptedSharedPreferences();

  /// Initializes the state of the widget.
  ///
  /// This method is called exactly once for each [State] object.
  /// It must call [super.initState].
  ///
  /// The framework will call this method when this [State] object is inserted into the tree.
  /// The [initState] implementation should primarily initialize non-visual state.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDataDialog();
    });
  }

  /// Shows a dialog asking the user if they want to use previous data.
  ///
  /// This method is scheduled to run after the widget's first frame is rendered,
  /// ensuring that the [BuildContext] is ready to show dialogs.
  ///
  /// The dialog presents two options: "Yes" and "No". If the user selects "Yes",
  /// the previously stored encrypted data will be loaded via [_loadEncryptedData].
  ///
  /// Returns: A [Future] that completes when the dialog is dismissed.
  Future<void> _showDataDialog() async {
    final bool useStoredData = await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, // User must tap a button to dismiss the dialog
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(translate('customer.notice')),
              content: Text(translate('customer.previous')),
              actions: [
                TextButton(
                  onPressed: () {
                    // Return true when "Yes" is selected
                    Navigator.of(context).pop(true);
                  },
                  child: Text(translate('yes')),
                ),
                TextButton(
                  onPressed: () {
                    // Return false when "No" is selected
                    Navigator.of(context).pop(false);
                  },
                  child: Text(translate('no')),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed without selection

    // Load encrypted data only if the user chose "Yes"
    if (useStoredData) {
      _loadEncryptedData();
    }
  }

  /// Loads previously saved form data from encrypted shared preferences.
  ///
  /// Populates the form with the last entered values, if any.
  void _loadEncryptedData() async {
    firstNameController.text =
        await encryptedPrefs.getString("last_first_name");
    lastNameController.text = await encryptedPrefs.getString("last_last_name");
    addressController.text = await encryptedPrefs.getString("last_address");
    birthdayController.text = await encryptedPrefs.getString("last_birthday");
    setState(() {});
  }

  /// Shows a dialog with a message and an OK button.
  ///
  /// [title] The title of the dialog.
  /// [message] The content message of the dialog.
  /// [returnToList] Whether to navigate back to the customer list when the dialog is dismissed.
  void _showDialog(String title, String message, bool returnToList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (returnToList) {
                Navigator.pop(context, true);
              }
            },
            child: Text(translate('button.ok')),
          ),
        ],
      ),
    );
  }

  /// Adds a new customer to the database using the form data.
  ///
  /// Shows a success message and returns to the previous screen if successful,
  /// or displays an error dialog if an error occurs.
  Future<void> _addCustomer() async {
    try {
      setState(() {
        widget.database.customerDao.insertCustomer(Customer(
          id: null,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          address: addressController.text.trim(),
          birthday: birthdayController.text.trim(),
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('customer.added_success'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showDialog(
          translate('customer.alert'), translate('customer.error'), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('customer.add')),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(translate('language.select')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('English'),
                        onTap: () {
                          changeLocale(context, 'en');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text('中文'),
                        onTap: () {
                          changeLocale(context, 'zh');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                    labelText: translate('customer.first_name'))),
            TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                    labelText: translate('customer.last_name'))),
            TextField(
                controller: addressController,
                decoration:
                    InputDecoration(labelText: translate('customer.address'))),
            TextField(
                controller: birthdayController,
                decoration:
                    InputDecoration(labelText: translate('customer.birthday'))),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.trim().isNotEmpty &&
                    lastNameController.text.trim().isNotEmpty &&
                    addressController.text.trim().isNotEmpty &&
                    birthdayController.text.trim().isNotEmpty &&
                    RegExp(r"^\d{4}-\d{2}-\d{2}$")
                        .hasMatch(birthdayController.text.trim())) {
                  await encryptedPrefs.setString(
                      "last_first_name", firstNameController.text.trim());
                  await encryptedPrefs.setString(
                      "last_last_name", lastNameController.text.trim());
                  await encryptedPrefs.setString(
                      "last_address", addressController.text.trim());
                  await encryptedPrefs.setString(
                      "last_birthday", birthdayController.text.trim());
                  _addCustomer();
                } else {
                  _showDialog(translate('customer.alert'),
                      translate('customer.fill_fields'), false);
                }
              },
              child: Text(translate('customer.add')),
            ),
          ],
        ),
      ),
    );
  }
}

/// A StatefulWidget for viewing and editing customer details.
///
/// Provides a form with the customer's current information and allows
/// for updating or deleting the customer.
class CustomerDetailPage extends StatefulWidget {
  /// The customer to display and edit.
  final Customer customer;

  /// The database instance to use for customer operations.
  final AppDatabase database;

  /// Optional callback to invoke when the customer is updated or deleted.
  ///
  /// This is used primarily in wide-screen layouts to refresh the master list.
  final VoidCallback? onCustomerUpdated;

  /// Creates a CustomerDetailPage.
  ///
  /// The [customer] and [database] parameters are required.
  /// The [onCustomerUpdated] parameter is optional and is called when changes are made.
  /// The [key] parameter is optional and is passed to the superclass.
  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.database,
    this.onCustomerUpdated,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

/// The state for [CustomerDetailPage].
///
/// Manages form controllers and customer update/delete operations.
class _CustomerDetailPageState extends State<CustomerDetailPage> {
  /// Controller for the first name text field.
  late TextEditingController _firstNameController;

  /// Controller for the last name text field.
  late TextEditingController _lastNameController;

  /// Controller for the address text field.
  late TextEditingController _addressController;

  /// Controller for the birthday text field.
  late TextEditingController _birthdayController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.customer.firstName);
    _lastNameController = TextEditingController(text: widget.customer.lastName);
    _addressController = TextEditingController(text: widget.customer.address);
    _birthdayController = TextEditingController(text: widget.customer.birthday);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  /// Updates the customer in the database with the current form values.
  ///
  /// Shows a success message if successful, or an error dialog if validation fails
  /// or an error occurs. If on a narrow screen, returns to the previous page.
  Future<void> _updateCustomer() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _birthdayController.text.isEmpty) {
      _showDialog(translate('customer.update_failed'),
          translate('customer.fill_fields'), false);
      return;
    }

    final updatedCustomer = Customer(
      id: widget.customer.id,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      address: _addressController.text,
      birthday: _birthdayController.text,
    );

    try {
      setState(() {
        widget.database.customerDao.updateCustomer(updatedCustomer);
      });
      widget.onCustomerUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('customer.update_success'))),
      );
      bool isWideScreen = MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height &&
          MediaQuery.of(context).size.width > 720;
      if (!isWideScreen) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showDialog(translate('customer.update_failed'),
          translate('customer.error'), false);
    }
  }

  /// Deletes the customer from the database.
  ///
  /// Shows a success message if successful, or an error dialog if an error occurs.
  /// If on a narrow screen, returns to the previous page.
  Future<void> _deleteCustomer() async {
    try {
      setState(() {
        widget.database.customerDao.deleteCustomerById(widget.customer.id!);
      });
      widget.onCustomerUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('customer.delete_success'))),
      );
      bool isWideScreen = MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height &&
          MediaQuery.of(context).size.width > 720;
      if (!isWideScreen) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showDialog(translate('customer.delete_failed'),
          translate('customer.error'), false);
    }
  }

  /// Shows a dialog with a message and an OK button.
  ///
  /// [title] The title of the dialog.
  /// [message] The content message of the dialog.
  /// [returnToList] Whether to navigate back to the customer list when the dialog is dismissed.
  void _showDialog(String title, String message, bool returnToList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (returnToList) {
                Navigator.pop(context, true);
              }
            },
            child: Text(translate('button.ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = MediaQuery.of(context).size.width >
                MediaQuery.of(context).size.height &&
            MediaQuery.of(context).size.width > 720;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !isWideScreen,
            title: Text(translate('customer.details')),
            actions: [
              if (!isWideScreen) // Only show language button in narrow screens
                IconButton(
                  icon: Icon(Icons.language),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(translate('language.select')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text('English'),
                              onTap: () {
                                changeLocale(context, 'en');
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text('中文'),
                              onTap: () {
                                changeLocale(context, 'zh');
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                      labelText: translate('customer.first_name')),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                      labelText: translate('customer.last_name')),
                ),
                TextField(
                  controller: _addressController,
                  decoration:
                      InputDecoration(labelText: translate('customer.address')),
                ),
                TextField(
                  controller: _birthdayController,
                  decoration: InputDecoration(
                      labelText: translate('customer.birthday')),
                  keyboardType: TextInputType.datetime,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _updateCustomer,
                      child: Text(translate('customer.update')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(translate('customer.alert')),
                            content: Text(translate('customer.confirm_delete')),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteCustomer();
                                },
                                child: Text(translate('customer.yes')),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(translate('customer.no')),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
