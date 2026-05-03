import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/category_sections.dart';
import '../../provider/rider_provider.dart';
import '../../core/widgets/app_loader.dart';
import '../../model/section_model.dart';
import '../../model/section_v2.dart';
import './section_widget.dart';
import '../sections/section_renderer.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String? categoryId;
  const CategoryPage({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  static const String _never = '__NEVER__';
  String _lastKey = _never;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerFetch(widget.categoryId);
    });
  }

  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerFetch(widget.categoryId);
      });
    }
  }

  void _triggerFetch(String? categoryId) {
    final key = categoryId ?? '__NULL__';
    if (_lastKey == key) return;
    _lastKey = key;

    debugPrint('🔄 CategoryPage._triggerFetch → categoryId=$categoryId');

    final userId = _userId;

    ref
        .read(categorySectionsProvider.notifier)
        .fetchSectionsOfCategory(categoryId: categoryId, userId: userId);

    final brandsId = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : '5d70fc95-8a6b-4d04-95e9-9620269ab15e';
    ref.read(categorySectionsProvider.notifier).fetchBrands(brandsId);
  }

  String? get _userId {
    try {
      final user = ref.read(riderPod).user;
      final id = (user['id'] ?? user['userId'] ?? '').toString();
      return id.isNotEmpty ? id : null;
    } catch (_) {
      return null;
    }
  }

  void _navigate(String route, Map<String, String> params) {
    final uri =
        Uri(path: route, queryParameters: params.isEmpty ? null : params);
    Navigator.pushNamed(context, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySectionsProvider);

    final sectionsLoading = state.sectionsLoading;
    final rawSections = state.sections;

    // Build ordered list of (position, widget) supporting both old and new models
    final positioned = <(int, Widget)>[];

    for (final raw in rawSections) {
      try {
        final e = Map<String, dynamic>.from(raw);
        final widgetKey = (e['widgetKey'] as String?) ?? '';

        if (widgetKey.isNotEmpty) {
          // New architecture — parse as SectionV2 + SectionRenderer
          final s2 = SectionV2.fromJson(e);
          if (!s2.active || s2.items.isEmpty) continue;
          positioned.add((
            s2.position,
            SectionRenderer(section: s2, onNavigate: _navigate),
          ));
        } else {
          // Legacy — parse as old Section + SectionWidget
          final s = Section.fromJson(e);
          if (!s.active || s.items.isEmpty) continue;
          positioned.add((
            s.position,
            SectionWidget(section: s, onNavigate: _navigate),
          ));
        }
      } catch (_) {}
    }

    positioned.sort((a, b) => a.$1.compareTo(b.$1));
    final sectionWidgets = positioned.map((p) => p.$2).toList();

    if (sectionsLoading && sectionWidgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: AppSpinner(),
        ),
      );
    }

    if (sectionWidgets.isEmpty && !sectionsLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionWidgets,
    );
  }
}
