import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared visual building blocks for the two community reporting flows.
class ReportFormSection extends StatelessWidget {
  const ReportFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.description,
    this.topSpacing = true,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? description;
  final bool topSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing ? 20 : 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF172554),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: Color(0xFFE8ECF0)),
            ..._spaced(children),
          ],
        ),
      ),
    );
  }
}

class ReportChoiceGroup extends StatelessWidget {
  const ReportChoiceGroup({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.helper,
    this.validator,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? helper;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => FormField<String>(
        initialValue: value,
        validator: validator,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (helper != null) ...[
              const SizedBox(height: 3),
              Text(
                helper!,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final selected = value == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) {
                    state.didChange(option);
                    onChanged(option);
                  },
                  selectedColor: AppColors.cream,
                  backgroundColor: const Color(0xFFF7F7F7),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFD6DCE3),
                  ),
                  labelStyle: TextStyle(
                    color:
                        selected ? AppColors.primaryVariant : Colors.black87,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      );
}

class ReportCheckboxTile extends StatelessWidget {
  const ReportCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        value: value,
        selected: value,
        tileColor: const Color(0xFFF7F7F7),
        selectedTileColor: const Color(0xFFE9EAEC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: value ? AppColors.primary : const Color(0xFFE0E5EA),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: value ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(color: Colors.black54)),
        onChanged: onChanged,
      );
}

class ReportReviewCard extends StatelessWidget {
  const ReportReviewCard({super.key, required this.title, required this.values});

  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...values.entries
                .where((entry) => entry.value.trim().isNotEmpty)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
          ],
        ),
      );
}

List<Widget> _spaced(List<Widget> children) => [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index < children.length - 1) const SizedBox(height: 12),
      ],
    ];
