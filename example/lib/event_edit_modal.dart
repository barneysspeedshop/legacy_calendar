import 'package:flutter/material.dart';
import 'package:legacy_calendar/legacy_calendar.dart';
import 'package:intl/intl.dart';

class EventEditModal extends StatefulWidget {
  final CalendarMonthEvent? event;
  final DateTime? initialDate;
  final DateTime? selectionStart;
  final DateTime? selectionEnd;

  const EventEditModal({
    super.key,
    this.event,
    this.initialDate,
    this.selectionStart,
    this.selectionEnd,
  });

  @override
  State<EventEditModal> createState() => _EventEditModalState();
}

class _EventEditModalState extends State<EventEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nowUtc = now.toUtc();

    if (widget.event != null) {
      _titleController = TextEditingController(text: widget.event!.title);
      // Ensure we are working with UTC dates
      final eventStartDate = widget.event!.startDate.toUtc();
      final eventEndDate = widget.event!.endDate.toUtc();

      _startDate = eventStartDate;
      _startTime = TimeOfDay.fromDateTime(eventStartDate.toLocal());

      _isAllDay =
          eventStartDate.hour == 0 &&
          eventStartDate.minute == 0 &&
          eventEndDate.hour == 0 &&
          eventEndDate.minute == 0 &&
          eventEndDate.isAfter(eventStartDate);

      if (_isAllDay) {
        // For all-day events, the stored end date is exclusive (e.g., midnight of the next day).
        // We subtract a day to show the inclusive end date in the UI.
        _endDate = eventEndDate.subtract(const Duration(days: 1));
        _endTime = const TimeOfDay(hour: 0, minute: 0);
      } else {
        _endDate = eventEndDate;
        _endTime = TimeOfDay.fromDateTime(eventEndDate.toLocal());
      }
    } else {
      _titleController = TextEditingController();
      final initialStart =
          widget.selectionStart ?? widget.initialDate ?? nowUtc;
      final initialEnd = widget.selectionEnd ?? widget.initialDate ?? nowUtc;

      _startDate = DateTime.utc(
        initialStart.year,
        initialStart.month,
        initialStart.day,
      );
      _startTime = TimeOfDay.fromDateTime(now.toLocal());
      _endDate = DateTime.utc(
        initialEnd.year,
        initialEnd.month,
        initialEnd.day,
      );
      _endTime = TimeOfDay.fromDateTime(
        now.toLocal().add(const Duration(hours: 1)),
      );
      _isAllDay = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('All Day'),
                value: _isAllDay,
                onChanged: (bool value) {
                  setState(() {
                    _isAllDay = value;
                    if (_isAllDay) {
                      // When switching to all-day, if the end date is before or on the same day,
                      // set it to be the same as the start date for a single all-day event.
                      if (!_endDate.isAfter(_startDate)) {
                        _endDate = _startDate;
                      }
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat.yMd().format(_startDate)}${_isAllDay ? '' : ' ${_startTime.format(context)}'}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                              // If the end date is before the new start date, update it.
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                      if (!_isAllDay)
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (time != null) {
                              setState(() {
                                _startTime = time;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'End',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat.yMd().format(_endDate)}${_isAllDay ? '' : ' ${_endTime.format(context)}'}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate:
                                _startDate, // End date cannot be before start date
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                      if (!_isAllDay)
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (time != null) {
                              setState(() {
                                _endTime = time;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final DateTime finalStartDate = DateTime.utc(
                          _startDate.year,
                          _startDate.month,
                          _startDate.day,
                          _isAllDay ? 0 : _startTime.hour,
                          _isAllDay ? 0 : _startTime.minute,
                        );

                        // For all-day events, the end date is exclusive (start of the next day).
                        final DateTime uiEndDate = DateTime.utc(
                          _endDate.year,
                          _endDate.month,
                          _endDate.day,
                        );
                        final DateTime finalEndDate = _isAllDay
                            ? uiEndDate.add(const Duration(days: 1))
                            : DateTime.utc(
                                _endDate.year,
                                _endDate.month,
                                _endDate.day,
                                _endTime.hour,
                                _endTime.minute,
                              );

                        final newEvent = CalendarMonthEvent(
                          id:
                              widget.event?.id ??
                              DateTime.now().toIso8601String(),
                          startDate: finalStartDate,
                          endDate: finalEndDate,
                          title: _titleController.text,
                          background: widget.event?.background ?? Colors.blue,
                          textColor: widget.event?.textColor ?? Colors.white,
                        );
                        Navigator.of(context).pop(newEvent);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
