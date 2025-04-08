import 'package:final_mobile/VehicleMaintenanceDatabase.dart';
import 'package:flutter/material.dart';
import 'VehicleMaintenanceDAO.dart';
import 'VehicleMaintenanceDataRepository.dart';
import 'VehicleMaintenanceItem.dart';
import 'VehicleMaintenanceEditPage.dart';
import 'package:flutter_translate/flutter_translate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        '/first': (context) => MyApp(),
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
  var list = <VehicleMaintenanceItem>[];
  late VehicleMaintenanceDAO myDAO;

  @override
  void initState() {
    super.initState();

    $FloorVehicleMaintenanceDatabase
        .databaseBuilder("vehicle_maintenance_database.db")
        .build()
        .then((database) {
      myDAO = database.vehiclemaintenanceDAO;
      VehicleMaintenanceDataRepository.myDAO = myDAO;
      myDAO.findAllItems().then((listOfItems) {
        setState(() {
          list.clear();
          list.addAll(listOfItems);
          VehicleMaintenanceDataRepository.list = list;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('vehicle.list')),
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
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    VehicleMaintenanceDataRepository.button = "Add";
                    Navigator.pushNamed(context, "/AddVehicleMaintenance");
                  },
                  child: Text(translate('vehicle.add_maintenance'))),
              Expanded(
                  child: Center(
                      child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, rowNum) {
                            String listItem;
                            if (list.isEmpty)
                              listItem = translate("vehicle.empty_list");
                            else
                              listItem = list[rowNum].toString();

                            return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    child: Text(listItem),
                                    onLongPress: () =>
                                        dialogBuilder(context, rowNum),
                                  )
                                ]);
                          })))
            ]),
      ),
    );
  }

  Future<void> dialogBuilder(BuildContext context, int rowNum) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(translate('vehicle.update')),
              content: Text(translate("vehicle.update_alert")),
              actions: <Widget>[
                TextButton(
                  child: Text(translate('vehicle.yes')),
                  onPressed: () {
                    VehicleMaintenanceDataRepository.button = "Update";
                    VehicleMaintenanceDataRepository.id = list[rowNum].id; //id
                    VehicleMaintenanceDataRepository.saveData('vehicle_name',
                        list[rowNum].vehicleName); //vehicle_name
                    VehicleMaintenanceDataRepository.saveData('vehicle_type',
                        list[rowNum].vehicleType); //vehicle_type
                    VehicleMaintenanceDataRepository.saveData('service_type',
                        list[rowNum].serviceType); //service_type
                    VehicleMaintenanceDataRepository.saveData('service_date',
                        list[rowNum].serviceDate); //service_date
                    VehicleMaintenanceDataRepository.saveData(
                        'mileage', list[rowNum].mileage.toString()); //mileage
                    VehicleMaintenanceDataRepository.saveData(
                        'cost', list[rowNum].cost.toString()); //cost
                    Navigator.pushNamed(context, "/UpdateVehicleMaintenance");
                  },
                ),
                TextButton(
                    style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge),
                    child: Text(translate('vehicle.no')),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })
              ]);
        });
  }
}
