import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final bool open;
  final Function(bool) onOpenChange;
  final List<String> selectedFilters;
  final Function(List<String>) onFiltersChange;

  const FilterModal({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.selectedFilters,
    required this.onFiltersChange,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  final List<Map<String, String>> filterOptions = [
    {'value': '40', 'label': '40% or more'},
    {'value': '30', 'label': '30% or more'},
    {'value': '20', 'label': '20% or more'},
    {'value': '10', 'label': '10% or more'},
    {'value': 'below-10', 'label': '10% and below'},
  ];

  void handleToggleFilter(String value) {
    final filters = [...widget.selectedFilters];
    if (filters.contains(value)) {
      filters.remove(value);
    } else {
      filters.add(value);
    }
    widget.onFiltersChange(filters);
  }

  void handleClear() {
    widget.onFiltersChange([]);
  }

  void handleApply() {
    widget.onOpenChange(false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filters",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 24),
                    onPressed: () => widget.onOpenChange(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filterOptions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 44,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final option = filterOptions[index];
                  final selected = widget.selectedFilters.contains(option['value']);
                  return InkWell(
                    onTap: () => handleToggleFilter(option['value']!),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (_) => handleToggleFilter(option['value']!),
                        ),
                        Expanded(
                          child: Text(
                            option['label']!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: handleClear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Clear"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: handleApply,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Apply"),
                    ),
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
