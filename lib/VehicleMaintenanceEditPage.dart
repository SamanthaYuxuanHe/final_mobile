import 'package:flutter/material.dart';
import 'VehicleMaintenanceItem.dart';
import 'VehicleMaintenancePage.dart';
import 'VehicleMaintenanceDataRepository.dart';
import 'package:flutter_translate/flutter_translate.dart';

void main() {
  runApp(const VehicleMaintenancePage());
}

class AddVehicleMaintenancePage extends StatelessWidget {
  const AddVehicleMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    VehicleMaintenanceDataRepository.button = "Add";
    return MaterialApp(
      title: translate("vehicle.add_page_title"),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: translate("vehicle.add_page_title")),
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        '/first': (context) => VehicleMaintenancePage(),
        '/AddVehicleMaintenance': (context) => AddVehicleMaintenancePage(),
        '/UpdateVehicleMaintenance': (context) =>
            UpdateVehicleMaintenancePage(),
      },
    );
  }
}

class UpdateVehicleMaintenancePage extends StatelessWidget {
  const UpdateVehicleMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    VehicleMaintenanceDataRepository.button = "Update";
    return MaterialApp(
      title: translate("vehicle.update_page_title"),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: translate("vehicle.update_page_title")),
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        '/first': (context) => VehicleMaintenancePage(),
        '/AddVehicleMaintenance': (context) => AddVehicleMaintenancePage(),
        '/UpdateVehicleMaintenance': (context) =>
            UpdateVehicleMaintenancePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController vehicle_name = TextEditingController();
  final TextEditingController vehicle_type = TextEditingController();
  final TextEditingController service_type = TextEditingController();
  final TextEditingController service_date = TextEditingController();
  final TextEditingController mileage = TextEditingController();
  final TextEditingController cost = TextEditingController();

  final TextEditingController container = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (VehicleMaintenanceDataRepository.button.compareTo("Update") == 0)
      loadData();

    Future.delayed(const Duration(seconds: 1), () {
      SnackBar snackBar =
          SnackBar(content: Text(translate("vehicle.maintenance_page")));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void loadData() {
    setState(() {
      VehicleMaintenanceDataRepository.loadData('vehicle_name', vehicle_name);
      VehicleMaintenanceDataRepository.loadData('vehicle_type', vehicle_type);
      VehicleMaintenanceDataRepository.loadData('service_type', service_type);
      VehicleMaintenanceDataRepository.loadData('service_date', service_date);
      VehicleMaintenanceDataRepository.loadData('mileage', mileage);
      VehicleMaintenanceDataRepository.loadData('cost', cost);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
              TextField(
                controller: vehicle_name,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.vehicle_name')),
                onChanged: (String value) => {
                  VehicleMaintenanceDataRepository.saveData(
                      'vehicle_name', value)
                },
              ),
              TextField(
                controller: vehicle_type,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.vehicle_type')),
                onChanged: (String value) => {
                  VehicleMaintenanceDataRepository.saveData(
                      'vehicle_type', value)
                },
              ),
              TextField(
                controller: service_type,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.vehicle_type')),
                onChanged: (String value) => {
                  VehicleMaintenanceDataRepository.saveData(
                      'service_type', value)
                },
              ),
              TextField(
                controller: service_date,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.service_date')),
                onChanged: (String value) => {
                  VehicleMaintenanceDataRepository.saveData(
                      'service_date', value)
                },
              ),
              TextField(
                controller: mileage,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.mileage')),
                onChanged: (String value) => {
                  VehicleMaintenanceDataRepository.saveData('mileage', value)
                },
              ),
              TextField(
                controller: cost,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: translate('vehicle.cost')),
                onChanged: (String value) =>
                    {VehicleMaintenanceDataRepository.saveData('Cost', value)},
              ),
              buildButton(),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(context);
                  },
                  child: Text(translate("vehicle.cancel"))),
            ])));
  }

  Widget buildButton() {
    String button = VehicleMaintenanceDataRepository.button;
    var list = VehicleMaintenanceDataRepository.list;

    if (button.compareTo("Add") == 0) {
      return ElevatedButton(
          onPressed: () {
            var newItem = VehicleMaintenanceItem(
                VehicleMaintenanceItem.ID++,
                vehicle_name.text,
                vehicle_type.text,
                service_type.text,
                service_date.text,
                double.parse(mileage.text),
                double.parse(cost.text));
            try {
              VehicleMaintenanceDataRepository.myDAO?.insertItem(newItem);
            } catch (e) {
              VehicleMaintenanceItem.ID++;
              VehicleMaintenanceDataRepository.myDAO?.insertItem(newItem);
            }
            list?.add(newItem);
            Navigator.of(context, rootNavigator: true).pop(context);
          },
          child: Text(translate("vehicle.add")));
    } else if (button.compareTo("Update") == 0) {
      int id = VehicleMaintenanceDataRepository.id;
      int rowNum = VehicleMaintenanceDataRepository.rowNum;
      var myDAO = VehicleMaintenanceDataRepository.myDAO;

      return Column(children: [
        ElevatedButton(
            onPressed: () {
              var newItem = VehicleMaintenanceItem(
                  id,
                  vehicle_name.text,
                  vehicle_type.text,
                  service_type.text,
                  service_date.text,
                  double.parse(mileage.text),
                  double.parse(cost.text));
              myDAO?.updateItem(newItem);
              myDAO?.findAllItems().then((listOfItems) {
                setState(() {
                  list.clear();
                  list.addAll(listOfItems);
                  VehicleMaintenanceDataRepository.list = list;
                });
              });
              Navigator.of(context, rootNavigator: true).pop(context);
            },
            child: Text(translate("vehicle.update"))),
        ElevatedButton(
            onPressed: () {
              setState(() {
                myDAO?.deleteItem(list[rowNum]);
                Navigator.of(context, rootNavigator: true).pop(context);
              });
            },
            child: Text(translate("vehicle.delete")))
      ]);
    } else
      return ElevatedButton(
        onPressed: () {},
        child: Text("placeholder"),
      );
  }
}
