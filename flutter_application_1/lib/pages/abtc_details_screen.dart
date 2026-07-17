import 'package:flutter/material.dart';

import '../models/abtc_model.dart';
import '../theme.dart';

class ABTCDetailsScreen extends StatelessWidget {
  const ABTCDetailsScreen({super.key, required this.abtc});

  final ABTCModel abtc;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('ABTC Details')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      color: AppColors.primary,
                      size: 34,
                    ),
                    const SizedBox(height: 12),
                    Text(abtc.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    _DetailItem(
                      label: 'Complete Address',
                      value: abtc.completeAddress,
                    ),
                    _DetailItem(
                      label: 'Municipality',
                      value: _valueOrUnavailable(abtc.municipality),
                    ),
                    _DetailItem(
                      label: 'Barangay',
                      value: _valueOrUnavailable(abtc.barangay),
                    ),
                    _DetailItem(
                      label: 'Province',
                      value: _valueOrUnavailable(abtc.province),
                    ),
                    _DetailItem(label: 'Schedule', value: abtc.schedule),
                    _DetailItem(label: 'Availability', value: abtc.availability),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 52),
          ],
        ),
      ),
    );
  }

  String _valueOrUnavailable(String value) =>
      value.isEmpty ? 'Information unavailable' : value;
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
