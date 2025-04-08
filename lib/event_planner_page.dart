import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'event_model.dart';
import 'event_database_helper.dart';
import 'event_preferences.dart';

/// A stateful widget that displays a list of events and allows users to create,
/// view, edit, and delete events in an event planning application.
///
/// This page adapts its layout based on screen size, showing a master-detail view
/// on tablets and a list-only view on phones.
class EventPlannerPage extends StatefulWidget {
  /// Creates an instance of [EventPlannerPage].
  const EventPlannerPage({super.key});

  @override
  State<EventPlannerPage> createState() => _EventPlannerPageState();
}

/// The state for [EventPlannerPage] that manages the list of events and
/// handles user interactions.
class _EventPlannerPageState extends State<EventPlannerPage> {
  /// Database helper for event CRUD operations.
  final EventDatabase _database = EventDatabase();

  /// Helper for accessing and storing user preferences.
  final EventPreferences _preferences = EventPreferences();

  /// List of all events retrieved from the database.
  List<Event> _events = [];

  /// Currently selected event for detailed view (used in tablet layout).
  Event? _selectedEvent;

  /// Flag to show loading state during database operations.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// Loads all events from the database and updates the UI.
  ///
  /// Sets [_isLoading] to true while fetching data and false when complete.
  /// Handles any errors by displaying a snackbar with the error message.
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _database.getEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error loading events: $e');
    }
  }

  /// Displays a snackbar with the provided [message].
  ///
  /// Used for showing success/error notifications to the user.
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a help dialog with information about using the app.
  ///
  /// The dialog content is localized using the translate function.
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('help_title')),
        content: SingleChildScrollView(child: Text(translate('help_message'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate('cancel')),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting an event.
  ///
  /// If the user confirms, calls [_deleteEvent] to remove the [event].
  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('confirm_delete')),
        content: Text(translate('delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translate('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent(event);
            },
            child: Text(translate('yes')),
          ),
        ],
      ),
    );
  }

  /// Deletes the specified [event] from the database and updates the UI.
  ///
  /// Shows a success message if the deletion is successful, or an error message if not.
  /// If the deleted event was selected, clears the selection.
  Future<void> _deleteEvent(Event event) async {
    if (event.id == null) return;
    try {
      await _database.deleteEvent(event.id!);
      _showSnackbar(translate('event_deleted'));
      setState(() {
        _events.removeWhere((e) => e.id == event.id);
        if (_selectedEvent?.id == event.id) _selectedEvent = null;
      });
    } catch (e) {
      _showSnackbar('Error deleting event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('events')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: translate('help'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isTablet
              ? _buildTabletLayout()
              : _buildPhoneLayout(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventFormPage(
                onEventAdded: (event) {
                  setState(() {
                    _events.add(event);
                    _selectedEvent = event;
                  });
                },
              ),
            ),
          );
        },
        tooltip: translate('add_event'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds the tablet-specific layout with a master-detail view.
  ///
  /// Shows the event list on the left side and the selected event details on the right.
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildEventList()),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: 3,
          child: _selectedEvent == null
              ? Center(
                  child: Text(
                    translate('no_events'),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : EventDetailPage(
                  event: _selectedEvent!,
                  onEventUpdated: (updatedEvent) {
                    setState(() {
                      final index =
                          _events.indexWhere((e) => e.id == updatedEvent.id);
                      if (index >= 0) {
                        _events[index] = updatedEvent;
                        _selectedEvent = updatedEvent;
                      }
                    });
                  },
                  onEventDeleted: _confirmDelete,
                ),
        ),
      ],
    );
  }

  /// Builds the phone-specific layout showing only the event list.
  ///
  /// Event details are shown by navigating to a new screen when an event is tapped.
  Widget _buildPhoneLayout() => _buildEventList();

  /// Builds a list view of all events.
  ///
  /// Shows a message if there are no events. Otherwise, displays a scrollable
  /// list of events with their names and dates. Tapping an event either selects
  /// it in tablet mode or navigates to its detail page in phone mode.
  Widget _buildEventList() {
    if (_events.isEmpty) {
      return Center(
        child: Text(
          translate('no_events'),
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return ListTile(
          title: Text(event.name),
          subtitle: Text('${event.date} | ${event.time}'),
          onTap: () {
            if (MediaQuery.of(context).size.width > 600) {
              setState(() => _selectedEvent = event);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                    event: event,
                    onEventUpdated: (updatedEvent) {
                      setState(() {
                        final index =
                            _events.indexWhere((e) => e.id == updatedEvent.id);
                        if (index >= 0) {
                          _events[index] = updatedEvent;
                          _selectedEvent = updatedEvent;
                        }
                      });
                    },
                    onEventDeleted: (event) {
                      Navigator.pop(context);
                      _confirmDelete(event);
                    },
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// A form page for creating new events.
///
/// This page provides input fields for all event properties and handles
/// saving the new event to the database.
class EventFormPage extends StatefulWidget {
  /// Callback function that is called when a new event is successfully added.
  ///
  /// The newly created [Event] object is passed to this function.
  final Function(Event) onEventAdded;

  /// Creates an instance of [EventFormPage].
  ///
  /// The [onEventAdded] callback is required to notify the parent widget
  /// when a new event has been created.
  const EventFormPage({super.key, required this.onEventAdded});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

/// The state for [EventFormPage] that manages the form inputs and validation.
class _EventFormPageState extends State<EventFormPage> {
  /// Key for the form to enable validation.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the event name input.
  final _nameController = TextEditingController();

  /// Controller for the event date input.
  final _dateController = TextEditingController();

  /// Controller for the event time input.
  final _timeController = TextEditingController();

  /// Controller for the event location input.
  final _locationController = TextEditingController();

  /// Controller for the event description input.
  final _descriptionController = TextEditingController();

  /// Database helper for saving the new event.
  final EventDatabase _database = EventDatabase();

  /// Helper for accessing and storing user preferences.
  final EventPreferences _preferences = EventPreferences();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Loads the details of the most recently created event into the form.
  ///
  /// This allows users to quickly create similar events by copying
  /// data from a previous event.
  Future<void> _loadPreviousEvent() async {
    final event = await _preferences.getLastEvent();
    if (event != null) {
      setState(() {
        _nameController.text = event.name;
        _dateController.text = event.date;
        _timeController.text = event.time;
        _locationController.text = event.location;
        _descriptionController.text = event.description;
      });
    }
  }

  /// Opens a date picker dialog and updates the date field with the selected date.
  ///
  /// The date is formatted as YYYY-MM-DD.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Opens a time picker dialog and updates the time field with the selected time.
  ///
  /// The time is formatted as HH:MM in 24-hour format.
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Validates and submits the form to create a new event.
  ///
  /// If validation passes, creates an [Event] object, saves it to the database,
  /// stores it in preferences as the last event, and notifies the parent widget
  /// via the [onEventAdded] callback. Shows appropriate success or error messages.
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final event = Event(
          name: _nameController.text,
          date: _dateController.text,
          time: _timeController.text,
          location: _locationController.text,
          description: _descriptionController.text,
        );

        final id = await _database.insertEvent(event);
        await _preferences.saveLastEvent(event);
        final insertedEvent = event.copyWith(id: id);
        widget.onEventAdded(insertedEvent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('event_added'))),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding event: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('required_fields'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('add_event')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(translate('help_title')),
                  content: Text(translate('help_message')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(translate('cancel')),
                    ),
                  ],
                ),
              );
            },
            tooltip: translate('help'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _loadPreviousEvent,
                icon: const Icon(Icons.copy),
                label: Text(translate('copy_previous')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: translate('event_name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? translate('required_fields')
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: translate('event_date'),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('required_fields')
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                    tooltip: translate('pick_date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: translate('event_time'),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                      validator: (value) => value == null || value.isEmpty
                          ? translate('required_fields')
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: _selectTime,
                    tooltip: translate('pick_time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: translate('event_location'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? translate('required_fields')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: translate('event_description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? translate('required_fields')
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(translate('submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page for viewing and editing the details of an existing event.
///
/// This page can be shown either as a separate screen on phones or as part
/// of the master-detail view on tablets.
class EventDetailPage extends StatefulWidget {
  /// The event to display and potentially edit.
  final Event event;

  /// Callback function that is called when the event is updated.
  ///
  /// The updated [Event] object is passed to this function.
  final Function(Event) onEventUpdated;

  /// Callback function that is called when the user requests to delete the event.
  ///
  /// The [Event] to be deleted is passed to this function.
  final Function(Event) onEventDeleted;

  /// Creates an instance of [EventDetailPage].
  ///
  /// All parameters are required:
  /// - [event]: The event to display and edit
  /// - [onEventUpdated]: Callback for when the event is updated
  /// - [onEventDeleted]: Callback for when deletion is requested
  const EventDetailPage({
    super.key,
    required this.event,
    required this.onEventUpdated,
    required this.onEventDeleted,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

/// The state for [EventDetailPage] that manages the form inputs and validation
/// for editing an existing event.
class _EventDetailPageState extends State<EventDetailPage> {
  /// Key for the form to enable validation.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the event name input.
  late TextEditingController _nameController;

  /// Controller for the event date input.
  late TextEditingController _dateController;

  /// Controller for the event time input.
  late TextEditingController _timeController;

  /// Controller for the event location input.
  late TextEditingController _locationController;

  /// Controller for the event description input.
  late TextEditingController _descriptionController;

  /// Database helper for updating the event.
  final EventDatabase _database = EventDatabase();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _dateController = TextEditingController(text: widget.event.date);
    _timeController = TextEditingController(text: widget.event.time);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController =
        TextEditingController(text: widget.event.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Opens a date picker dialog and updates the date field with the selected date.
  ///
  /// The date picker is initialized with the event's current date if valid,
  /// or with the current date otherwise. The selected date is formatted as YYYY-MM-DD.
  Future<void> _selectDate() async {
    final initialDate = DateTime.tryParse(widget.event.date) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Opens a time picker dialog and updates the time field with the selected time.
  ///
  /// The time picker is initialized with the event's current time if valid,
  /// or with the current time otherwise. The selected time is formatted as HH:MM in 24-hour format.
  Future<void> _selectTime() async {
    final parts = widget.event.time.split(':');
    final initialTime = parts.length == 2
        ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Validates and submits the form to update the existing event.
  ///
  /// If validation passes, creates an updated [Event] object with the same ID,
  /// saves it to the database, and notifies the parent widget via the [onEventUpdated]
  /// callback. Shows appropriate success or error messages. On phones, navigates back
  /// after a successful update.
  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      final updatedEvent = Event(
        id: widget.event.id,
        name: _nameController.text,
        date: _dateController.text,
        time: _timeController.text,
        location: _locationController.text,
        description: _descriptionController.text,
      );

      try {
        await _database.updateEvent(updatedEvent);
        widget.onEventUpdated(updatedEvent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('event_updated'))),
        );

        if (MediaQuery.of(context).size.width <= 600) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating event: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('required_fields'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return isTablet
        ? _buildContent()
        : Scaffold(
            appBar: AppBar(
              title: Text(widget.event.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(translate('help_title')),
                        content: Text(translate('help_message')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(translate('cancel')),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: translate('help'),
                ),
              ],
            ),
            body: _buildContent(),
          );
  }

  /// Builds the form content for viewing and editing the event.
  ///
  /// This content is used both in the standalone page on phones and
  /// in the detail view on tablets.
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: translate('event_name'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? translate('required_fields')
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: translate('event_date'),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? translate('required_fields')
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                  tooltip: translate('pick_date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: translate('event_time'),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? translate('required_fields')
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _selectTime,
                  tooltip: translate('pick_time'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: translate('event_location'),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? translate('required_fields')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: translate('event_description'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value == null || value.isEmpty
                  ? translate('required_fields')
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(translate('update')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEventDeleted(widget.event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(translate('delete')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
