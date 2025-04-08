/// A model class representing an Event.
///
/// This class defines the structure for storing and managing event data
/// throughout the application.
class Event {
  /// Unique identifier for the event
  final int? id;
  
  /// Name of the event
  String name;
  
  /// Date of the event in format 'YYYY-MM-DD'
  String date;
  
  /// Time of the event in format 'HH:MM'
  String time;
  
  /// Location where the event takes place
  String location;
  
  /// Detailed description of the event
  String description;

  /// Constructor for creating an Event instance
  ///
  /// [id]: Optional unique identifier, typically provided by the database
  /// [name]: Required name of the event
  /// [date]: Required date of the event
  /// [time]: Required time of the event
  /// [location]: Required location of the event
  /// [description]: Required description of the event
  Event({
    this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });

  /// Creates an Event from a map (used when retrieving from database)
  ///
  /// [map]: A map containing event data with keys matching the property names
  /// Returns: A new Event instance populated with values from the map
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      time: map['time'],
      location: map['location'],
      description: map['description'],
    );
  }

  /// Converts this Event instance to a map (used when storing to database)
  ///
  /// Returns: A map containing all event properties
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
    };
  }

  /// Creates a copy of this Event with optionally updated properties
  ///
  /// This method is useful for creating modified copies without changing
  /// the original event instance.
  ///
  /// Returns: A new Event instance with copied and optionally updated values
  Event copyWith({
    int? id,
    String? name,
    String? date,
    String? time,
    String? location,
    String? description,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      description: description ?? this.description,
    );
  }
}