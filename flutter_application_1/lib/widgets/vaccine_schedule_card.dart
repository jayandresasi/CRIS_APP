import 'package:flutter/material.dart';
import '../theme.dart';

class VaccineScheduleCard extends StatefulWidget {
  const VaccineScheduleCard({Key? key}) : super(key: key);

  @override
  State<VaccineScheduleCard> createState() => _VaccineScheduleCardState();
}

class _VaccineScheduleCardState extends State<VaccineScheduleCard> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _schedule = [
    {'day': 'Day 0', 'status': 'completed'},
    {'day': 'Day 3', 'status': 'completed'},
    {'day': 'Day 7', 'status': 'completed'},
    {'day': 'Day 14', 'status': 'upcoming'},
    {'day': 'Day 28', 'status': 'missed'},
  ];

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return const Color(0xFFFF4C4C);
      case 'upcoming':
      default:
        return const Color(0xFFFFC107);
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'missed':
        return Icons.error;
      default:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vaccine Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _schedule.map((dose) {
                  final status = dose['status']!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      constraints: const BoxConstraints(minWidth: 96),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon(status),
                            color: statusColor(status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dose['day']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
