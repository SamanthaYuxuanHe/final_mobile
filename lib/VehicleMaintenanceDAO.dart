import 'package:floor/floor.dart';
import 'VehicleMaintenanceItem.dart';

@dao
abstract class VehicleMaintenanceDAO {
  //this performs a SQL query and returns a List of your @entity class
  @Query('SELECT * FROM VehicleMaintenanceItem')
  Future<List<VehicleMaintenanceItem>> findAllItems();

  //this performs a SQL query and returns a List of your @entity class
  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateItem(VehicleMaintenanceItem item);

  //This performs a SQL delete operation where the p.id matches that in the database
  @delete
  Future<void> deleteItem(VehicleMaintenanceItem item);

  //This performs a SQL insert operation, but you must create a unique id variable
  @insert
  Future<void> insertItem(VehicleMaintenanceItem item);
}