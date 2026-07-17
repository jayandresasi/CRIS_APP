import 'package:flutter/material.dart';

import '../models/abtc_model.dart';

class ABTCMarkerWidget extends StatelessWidget {
  const ABTCMarkerWidget({
    super.key,
    required this.abtc,
    required this.onTap,
  });

  final ABTCModel abtc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Show information for ${abtc.name}',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.local_hospital, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}
