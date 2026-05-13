import 'package:flutter/material.dart';
import '../widgets/vaccine_schedule_card.dart';

/// Dashboard page (placeholder for actual dashboard content)
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            VaccineScheduleCard(),
          ],
        ),
      ),
    );
  }
}
