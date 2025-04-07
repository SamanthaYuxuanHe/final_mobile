import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'event_model.dart';

/// Database helper for managing events in SQLite database
///
/// This class provides methods to create, read, update, and delete (CRUD) 
/// events from a local SQLite database.
class EventDatabase {
  static final EventDatabase _instance = EventDatabase._internal();
  static Database? _database;

  /// Factory constructor that returns the singleton instance
  factory EventDatabase() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  EventDatabase._internal();

  /// Gets the database instance, initializing it if necessary
  ///
  /// Returns: A Future that resolves to the Database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database by creating it if it doesn't exist
  ///
  /// Returns: A Future that resolves to the initialized Database
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'events.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  /// Creates the events table in the database
  ///
  /// [db]: The database instance
  /// [version]: The database version
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
  }

  /// Inserts a new event into the database
  ///
  /// [event]: The Event object to be inserted
  /// Returns: A Future that resolves to the ID of the inserted event
  Future<int> insertEvent(Event event) async {
    final Database db = await database;
    return await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all events from the database
  ///
  /// Returns: A Future that resolves to a list of Event objects
  Future<List<Event>> getEvents() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  /// Updates an existing event in the database
  ///
  /// [event]: The Event object with updated values (must have an ID)
  /// Returns: A Future that resolves to the number of rows affected
  Future<int> updateEvent(Event event) async {
    final Database db = await database;
    
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Deletes an event from the database
  ///
  /// [id]: The ID of the event to delete
  /// Returns: A Future that resolves to the number of rows affected
  Future<int> deleteEvent(int id) async {
    final Database db = await database;
    
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all events from the database
  ///
  /// Use with caution - this will delete all events!
  /// Returns: A Future that resolves to the number of rows affected
  Future<int> deleteAllEvents() async {
    final Database db = await database;
    return await db.delete('events');
  }
}