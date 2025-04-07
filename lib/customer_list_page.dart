import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'customer_list.dart';
import 'database.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  late Future<AppDatabase> _databaseFuture;
  Future<List<Customer>>? _customersFuture;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void _initializeDatabase() {
    _databaseFuture =
        $FloorAppDatabase.databaseBuilder('app_database.db').build();
  }

  void _refreshCustomers(AppDatabase database) {
    setState(() {
      _customersFuture = database.customerDao.getAllCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(translate('customer.list'))),
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

class AddCustomerPage extends StatefulWidget {
  final AppDatabase database;
  const AddCustomerPage({super.key, required this.database});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final EncryptedSharedPreferences encryptedPrefs =
      EncryptedSharedPreferences();

  @override
  void initState() {
    super.initState();
    _loadEncryptedData();
  }

  void _loadEncryptedData() async {
    firstNameController.text =
        await encryptedPrefs.getString("last_first_name");
    lastNameController.text = await encryptedPrefs.getString("last_last_name");
    addressController.text = await encryptedPrefs.getString("last_address");
    birthdayController.text = await encryptedPrefs.getString("last_birthday");
    setState(() {});
  }

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
      _showDialog(translate('customer.added'),
          translate('customer.added_success'), true);
    } catch (e) {
      _showDialog(
          translate('customer.alert'), translate('customer.error'), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(translate('customer.add'))),
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

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  final AppDatabase database;
  final VoidCallback? onCustomerUpdated;

  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.database,
    this.onCustomerUpdated,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;
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
      bool isWideScreen = MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height &&
          MediaQuery.of(context).size.width > 720;
      _showDialog(translate('customer.update_success'),
          translate('customer.update_success'), !isWideScreen);
    } catch (e) {
      _showDialog(translate('customer.update_failed'),
          translate('customer.error'), false);
    }
  }

  Future<void> _deleteCustomer() async {
    try {
      setState(() {
        widget.database.customerDao.deleteCustomerById(widget.customer.id!);
      });
      widget.onCustomerUpdated?.call();
      bool isWideScreen = MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height &&
          MediaQuery.of(context).size.width > 720;
      _showDialog(translate('customer.delete_success'),
          translate('customer.delete_message'), !isWideScreen);
    } catch (e) {
      _showDialog(translate('customer.delete_failed'),
          translate('customer.error'), false);
    }
  }

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
    bool isWideScreen = MediaQuery.of(context).size.width >
            MediaQuery.of(context).size.height &&
        MediaQuery.of(context).size.width > 720;
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('customer.details')),
        leading: isWideScreen
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, !isWideScreen),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _firstNameController,
              decoration:
                  InputDecoration(labelText: translate('customer.first_name')),
            ),
            TextField(
              controller: _lastNameController,
              decoration:
                  InputDecoration(labelText: translate('customer.last_name')),
            ),
            TextField(
              controller: _addressController,
              decoration:
                  InputDecoration(labelText: translate('customer.address')),
            ),
            TextField(
              controller: _birthdayController,
              decoration:
                  InputDecoration(labelText: translate('customer.birthday')),
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
  }
}
