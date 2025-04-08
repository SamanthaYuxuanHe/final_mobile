import 'dart:async';
import 'VehicleMaintenanceItem.dart';
import 'VehicleMaintenanceDAO.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'VehicleMaintenanceDatabase.g.dart';

@Database(version: 1,entities: [VehicleMaintenanceItem])
abstract class VehicleMaintenanceDatabase extends FloorDatabase{
  VehicleMaintenanceDAO get vehiclemaintenanceDAO;
}