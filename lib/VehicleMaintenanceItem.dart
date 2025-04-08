import 'package:floor/floor.dart';

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

  VehicleMaintenanceItem(this.id, this.vehicleName, this.vehicleType, this.serviceType, this.serviceDate, this.mileage, this.cost){
    if (id > ID) {
      ID = id + 1;
    }else{
      ID = id;
    }
  }

  @override
  String toString() {
    return "id: " + this.id.toString()
        + "\nvehicle name: " + this.vehicleName
        + "\nvehicle type: " + this.vehicleType
        + "\nservice type: " + this.serviceType
        + "\nvehicle date: " + this.serviceDate
        + "\nmilage: " + this.mileage.toString()
        + "\ncost: " + this.cost.toString() +"\n";
  }
}
