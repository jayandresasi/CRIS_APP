import 'package:flutter/material.dart';

import '../models/abtc_model.dart';
import '../services/nearest_abtc_service.dart';
import '../theme.dart';

class ABTCListWidget extends StatelessWidget {
  const ABTCListWidget({
    super.key,
    required this.centers,
    required this.scrollController,
    required this.onViewDetails,
    required this.onDirections,
    this.nearestABTCId,
    this.emptyMessage,
  });

  final List<ABTCWithDistance> centers;
  final ScrollController scrollController;
  final ValueChanged<ABTCModel> onViewDetails;
  final ValueChanged<ABTCModel> onDirections;
  final String? nearestABTCId;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (centers.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          const Text(
            'Nearby Animal Bite Treatment Centers',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 40),
          Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            emptyMessage ?? 'No centers found for your search.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      itemCount: centers.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 12 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _SheetHandle()),
              SizedBox(height: 16),
              Text(
                'Nearby Animal Bite Treatment Centers',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          );
        }
        final center = centers[index - 1];
        return _ABTCCard(
          center: center,
          isNearest: center.abtc.id == nearestABTCId,
          onViewDetails: () => onViewDetails(center.abtc),
          onDirections: () => onDirections(center.abtc),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(99),
        ),
      );
}

class _ABTCCard extends StatelessWidget {
  const _ABTCCard({
    required this.center,
    required this.isNearest,
    required this.onViewDetails,
    required this.onDirections,
  });

  final ABTCWithDistance center;
  final bool isNearest;
  final VoidCallback onViewDetails;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final abtc = center.abtc;
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    abtc.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (isNearest) ...[
                  const SizedBox(width: 8),
                  const _NearestBadge(),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _DetailLine(icon: Icons.near_me_outlined, text: center.distanceLabel),
            const SizedBox(height: 5),
            _DetailLine(icon: Icons.schedule_outlined, text: abtc.schedule),
            const SizedBox(height: 5),
            _DetailLine(icon: Icons.medical_information_outlined, text: abtc.availability),
            const SizedBox(height: 5),
            _DetailLine(icon: Icons.location_on_outlined, text: abtc.completeAddress),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearestBadge extends StatelessWidget {
  const _NearestBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'Nearest',
          style: TextStyle(
            color: AppColors.primaryVariant,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      );
}
