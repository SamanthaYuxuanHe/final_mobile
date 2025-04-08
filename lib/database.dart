import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'customer_list.dart';
import 'customer_dao.dart';

part 'database.g.dart';

@Database(version: 1, entities: [Customer])
abstract class AppDatabase extends FloorDatabase {
  CustomerDao get customerDao;
}
