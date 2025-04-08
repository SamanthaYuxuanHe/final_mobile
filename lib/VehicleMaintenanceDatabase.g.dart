// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VehicleMaintenanceDatabase.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $VehicleMaintenanceDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $VehicleMaintenanceDatabaseBuilderContract addMigrations(
      List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $VehicleMaintenanceDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<VehicleMaintenanceDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorVehicleMaintenanceDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $VehicleMaintenanceDatabaseBuilderContract databaseBuilder(
          String name) =>
      _$VehicleMaintenanceDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $VehicleMaintenanceDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$VehicleMaintenanceDatabaseBuilder(null);
}

class _$VehicleMaintenanceDatabaseBuilder
    implements $VehicleMaintenanceDatabaseBuilderContract {
  _$VehicleMaintenanceDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $VehicleMaintenanceDatabaseBuilderContract addMigrations(
      List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $VehicleMaintenanceDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<VehicleMaintenanceDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$VehicleMaintenanceDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$VehicleMaintenanceDatabase extends VehicleMaintenanceDatabase {
  _$VehicleMaintenanceDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  VehicleMaintenanceDAO? _vehiclemaintenanceDAOInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `VehicleMaintenanceItem` (`id` INTEGER NOT NULL, `vehicleName` TEXT NOT NULL, `vehicleType` TEXT NOT NULL, `serviceType` TEXT NOT NULL, `serviceDate` TEXT NOT NULL, `mileage` REAL NOT NULL, `cost` REAL NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  VehicleMaintenanceDAO get vehiclemaintenanceDAO {
    return _vehiclemaintenanceDAOInstance ??=
        _$VehicleMaintenanceDAO(database, changeListener);
  }
}

class _$VehicleMaintenanceDAO extends VehicleMaintenanceDAO {
  _$VehicleMaintenanceDAO(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _vehicleMaintenanceItemInsertionAdapter = InsertionAdapter(
            database,
            'VehicleMaintenanceItem',
            (VehicleMaintenanceItem item) => <String, Object?>{
                  'id': item.id,
                  'vehicleName': item.vehicleName,
                  'vehicleType': item.vehicleType,
                  'serviceType': item.serviceType,
                  'serviceDate': item.serviceDate,
                  'mileage': item.mileage,
                  'cost': item.cost
                }),
        _vehicleMaintenanceItemUpdateAdapter = UpdateAdapter(
            database,
            'VehicleMaintenanceItem',
            ['id'],
            (VehicleMaintenanceItem item) => <String, Object?>{
                  'id': item.id,
                  'vehicleName': item.vehicleName,
                  'vehicleType': item.vehicleType,
                  'serviceType': item.serviceType,
                  'serviceDate': item.serviceDate,
                  'mileage': item.mileage,
                  'cost': item.cost
                }),
        _vehicleMaintenanceItemDeletionAdapter = DeletionAdapter(
            database,
            'VehicleMaintenanceItem',
            ['id'],
            (VehicleMaintenanceItem item) => <String, Object?>{
                  'id': item.id,
                  'vehicleName': item.vehicleName,
                  'vehicleType': item.vehicleType,
                  'serviceType': item.serviceType,
                  'serviceDate': item.serviceDate,
                  'mileage': item.mileage,
                  'cost': item.cost
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VehicleMaintenanceItem>
      _vehicleMaintenanceItemInsertionAdapter;

  final UpdateAdapter<VehicleMaintenanceItem>
      _vehicleMaintenanceItemUpdateAdapter;

  final DeletionAdapter<VehicleMaintenanceItem>
      _vehicleMaintenanceItemDeletionAdapter;

  @override
  Future<List<VehicleMaintenanceItem>> findAllItems() async {
    return _queryAdapter.queryList('SELECT * FROM VehicleMaintenanceItem',
        mapper: (Map<String, Object?> row) => VehicleMaintenanceItem(
            row['id'] as int,
            row['vehicleName'] as String,
            row['vehicleType'] as String,
            row['serviceType'] as String,
            row['serviceDate'] as String,
            row['mileage'] as double,
            row['cost'] as double));
  }

  @override
  Future<void> insertItem(VehicleMaintenanceItem item) async {
    await _vehicleMaintenanceItemInsertionAdapter.insert(
        item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateItem(VehicleMaintenanceItem item) async {
    await _vehicleMaintenanceItemUpdateAdapter.update(
        item, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteItem(VehicleMaintenanceItem item) async {
    await _vehicleMaintenanceItemDeletionAdapter.delete(item);
  }
}
