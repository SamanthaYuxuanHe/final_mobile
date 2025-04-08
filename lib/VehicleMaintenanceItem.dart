import 'package:floor/floor.dart';
import 'package:flutter_translate/flutter_translate.dart';

@entity
class VehicleMaintenanceItem {
  static int ID = 1;

  @primaryKey
  final int id;
  final String vehicleName;
  final String vehicleType;
  final String serviceType;
  final String serviceDate;
  final double mileage;
  final double cost;

  VehicleMaintenanceItem(this.id, this.vehicleName, this.vehicleType,
      this.serviceType, this.serviceDate, this.mileage, this.cost) {
    if (id > ID) {
      ID = id + 1;
    } else {
      ID = id;
    }
  }

  @override
  String toString() {
    return translate("vehicle.id") +
        ": " +
        this.id.toString() +
        "\n" +
        translate("vehicle.vehicle_name") +
        ": " +
        this.vehicleName +
        "\n" +
        translate("vehicle.vehicle_type") +
        ": " +
        this.vehicleType +
        "\n" +
        translate("vehicle.service_type") +
        ": " +
        this.serviceType +
        "\n" +
        translate("vehicle.service_date") +
        ": " +
        this.serviceDate +
        "\n" +
        translate("vehicle.mileage") +
        ": " +
        this.mileage.toString() +
        "\n" +
        translate("vehicle.cost") +
        ": " +
        this.cost.toString() +
        "\n";
  }
}
