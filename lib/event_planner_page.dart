import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';

import 'event_model.dart';
import 'event_database_helper.dart';
import 'event_preferences.dart';
import 'main.dart';

class EventPlannerPage extends StatefulWidget {
  const EventPlannerPage({super.key});

  @override
  State<EventPlannerPage> createState() => _EventPlannerPageState();
}

class _EventPlannerPageState extends State<EventPlannerPage> {
  final EventDatabase _database = EventDatabase();
  final EventPreferences _preferences = EventPreferences();
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
                      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
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

  Widget _buildPhoneLayout() => _buildEventList();

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
                        final index = _events.indexWhere((e) => e.id == updatedEvent.id);
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

class EventFormPage extends StatefulWidget {
  final Function(Event) onEventAdded;

  const EventFormPage({Key? key, required this.onEventAdded}) : super(key: key);

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final EventDatabase _database = EventDatabase();
  final EventPreferences _preferences = EventPreferences();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

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
                validator: (value) =>
                    value == null || value.isEmpty ? translate('required_fields') : null,
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
                      validator: (value) =>
                          value == null || value.isEmpty ? translate('required_fields') : null,
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
                      validator: (value) =>
                          value == null || value.isEmpty ? translate('required_fields') : null,
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
                validator: (value) =>
                    value == null || value.isEmpty ? translate('required_fields') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: translate('event_description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? translate('required_fields') : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(translate('submit')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventDetailPage extends StatefulWidget {
  final Event event;
  final Function(Event) onEventUpdated;
  final Function(Event) onEventDeleted;

  const EventDetailPage({
    Key? key,
    required this.event,
    required this.onEventUpdated,
    required this.onEventDeleted,
  }) : super(key: key);

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  final EventDatabase _database = EventDatabase();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _dateController = TextEditingController(text: widget.event.date);
    _timeController = TextEditingController(text: widget.event.time);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
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
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

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
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

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
              validator: (value) =>
                  value == null || value.isEmpty ? translate('required_fields') : null,
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
                    validator: (value) =>
                        value == null || value.isEmpty ? translate('required_fields') : null,
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
                    validator: (value) =>
                        value == null || value.isEmpty ? translate('required_fields') : null,
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
              validator: (value) =>
                  value == null || value.isEmpty ? translate('required_fields') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: translate('event_description'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) =>
                  value == null || value.isEmpty ? translate('required_fields') : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateEvent,
                    child: Text(translate('update')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onEventDeleted(widget.event),
                    child: Text(translate('delete')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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

