import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'event_model.dart';

/// Secure preferences manager for event data
///
/// This class provides methods to save and retrieve event data using
/// encrypted shared preferences for security.
class EventPreferences {
  static final EventPreferences _instance = EventPreferences._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Keys used for storing different event properties
  static const String _keyLastEventName = 'last_event_name';
  static const String _keyLastEventDate = 'last_event_date';
  static const String _keyLastEventTime = 'last_event_time';
  static const String _keyLastEventLocation = 'last_event_location';
  static const String _keyLastEventDescription = 'last_event_description';

  /// Factory constructor that returns the singleton instance
  factory EventPreferences() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  EventPreferences._internal();

  /// Saves the last event entered by the user
  ///
  /// [event]: The Event object to save
  /// Returns: A Future that completes when the save operation is done
  Future<void> saveLastEvent(Event event) async {
    await _secureStorage.write(key: _keyLastEventName, value: event.name);
    await _secureStorage.write(key: _keyLastEventDate, value: event.date);
    await _secureStorage.write(key: _keyLastEventTime, value: event.time);
    await _secureStorage.write(key: _keyLastEventLocation, value: event.location);
    await _secureStorage.write(key: _keyLastEventDescription, value: event.description);
  }

  /// Retrieves the last event entered by the user
  ///
  /// Returns: A Future that resolves to an Event object if data exists,
  /// or null if no previous event data is found
  Future<Event?> getLastEvent() async {
    final name = await _secureStorage.read(key: _keyLastEventName);
    final date = await _secureStorage.read(key: _keyLastEventDate);
    final time = await _secureStorage.read(key: _keyLastEventTime);
    final location = await _secureStorage.read(key: _keyLastEventLocation);
    final description = await _secureStorage.read(key: _keyLastEventDescription);

    // Return null if any required field is missing
    if (name == null || date == null || time == null || 
        location == null || description == null) {
      return null;
    }

    return Event(
      name: name,
      date: date,
      time: time,
      location: location,
      description: description,
    );
  }

  /// Clears all saved event data
  ///
  /// Returns: A Future that completes when the clear operation is done
  Future<void> clearLastEvent() async {
    await _secureStorage.delete(key: _keyLastEventName);
    await _secureStorage.delete(key: _keyLastEventDate);
    await _secureStorage.delete(key: _keyLastEventTime);
    await _secureStorage.delete(key: _keyLastEventLocation);
    await _secureStorage.delete(key: _keyLastEventDescription);
  }
}