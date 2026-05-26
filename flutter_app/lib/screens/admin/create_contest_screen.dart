
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/services/api_service.dart';

class CreateContestScreen extends ConsumerStatefulWidget {
  const CreateContestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateContestScreen> createState() => _CreateContestScreenState();
}

class _CreateContestScreenState extends ConsumerState<CreateContestScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  List<Map<String, dynamic>> selectedProblems = [];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final selected = await showDateTimePicker(
      context,
      initialDate: startTime ?? DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        startTime = selected;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final selected = await showDateTimePicker(
      context,
      initialDate: endTime ?? DateTime.now().add(const Duration(hours: 2)),
    );
    if (selected != null) {
      setState(() {
        endTime = selected;
      });
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext context, {required DateTime initialDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        return DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    }
    return null;
  }

  Future<void> _createContest() async {
    if (titleController.text.isEmpty || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (endTime!.isBefore(startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      await ApiService.post(
        '/contests',
        data: {
          'title': titleController.text,
          'description': descriptionController.text,
          'start_time': startTime!.toIso8601String(),
          'end_time': endTime!.toIso8601String(),
          'problems': selectedProblems,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contest created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Contest'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter contest title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter contest description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectStartTime,
                child: Text(
                  startTime == null
                      ? 'Select Start Time'
                      : startTime!.toString(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('End Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectEndTime,
                child: Text(
                  endTime == null
                      ? 'Select End Time'
                      : endTime!.toString(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Problems', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Add problems to contest (via problem IDs and points)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    if (selectedProblems.isEmpty)
                      const Text('No problems added yet')
                    else
                      ...selectedProblems.asMap().entries.map((entry) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Problem #${entry.value['problemId']} - ${entry.value['points']} pts'),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        selectedProblems.removeAt(entry.key);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createContest,
                  icon: const Icon(Icons.check),
                  label: const Text('Create Contest'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
