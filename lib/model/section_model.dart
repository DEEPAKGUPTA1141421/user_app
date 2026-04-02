// lib/models/section_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';

enum SectionType {
  PRODUCT_GRID,
  PRODUCT_SCROLL,
  CATEGORY,
  BANNER,
  BRAND,
  SPONSORED,
  UNKNOWN,
}

enum ItemType {
  PRODUCT,
  CATEGORY,
  BRAND,
  BANNER,
  MARKETING_PAGE,
  UNKNOWN,
}

enum ColorType { simple, gradient }

// ─── Section Config ─────────────────────────────────────────────────────────
class SectionConfig {
  final double? height;
  final bool scrollable;
  final int columns;
  final ColorType colorType;
  final Color background;
  final Color? firstHalf;
  final Color? secondHalf;
  final int? eachColumn; // rows per column for PRODUCT_GRID

  SectionConfig({
    this.height,
    required this.scrollable,
    required this.columns,
    required this.colorType,
    required this.background,
    this.firstHalf,
    this.secondHalf,
    this.eachColumn,
  });

  factory SectionConfig.fromJson(Map<String, dynamic> json) {
    final ct = json['colortype'] == 'gradient' ? ColorType.gradient : ColorType.simple;
    return SectionConfig(
      height: _parseHeight(json['height']),
      scrollable: json['scrollable'] == true || json['scrollable'] == 'true',
      columns: int.tryParse(json['columns']?.toString() ?? '1') ?? 1,
      colorType: ct,
      background: _parseColor(json['background'] ?? 'white'),
      firstHalf: _parseColor(json['firsthalf'] ?? 'white'),
      secondHalf: _parseColor(json['secondhalf'] ?? 'white'),
      eachColumn: int.tryParse(json['each_column']?.toString() ?? ''),
    );
  }

  static double? _parseHeight(dynamic v) {
    if (v == null) return null;
    final s = v.toString().replaceAll('rem', '').trim();
    final parsed = double.tryParse(s);
    if (parsed == null) return null;
    return parsed * 16; // 1rem = 16px approx
  }

  static Color _parseColor(String? v) {
    if (v == null || v.isEmpty) return Colors.white;
    final lv = v.toLowerCase().trim();
    const named = {
      'white': Colors.white,
      'green': Color(0xFF2E7D32),
      'red': Color(0xFFD32F2F),
      'blue': Color(0xFF1565C0),
      'orange': Color(0xFFE65100),
      'beige': Color(0xFFF5F0E0),
      'lightblue': Color(0xFFB3E5FC),
      'transparent': Colors.transparent,
    };
    if (named.containsKey(lv)) return named[lv]!;
    if (lv.startsWith('#') && lv.length == 7) {
      return Color(int.parse('FF${lv.substring(1)}', radix: 16));
    }
    return Colors.white;
  }
}

// ─── Section Item ────────────────────────────────────────────────────────────
class SectionItemFilter {
  final String? type; // price | percent
  final double? gte;
  final int? discount;
  final String? categoryId;

  SectionItemFilter({this.type, this.gte, this.discount, this.categoryId});

  factory SectionItemFilter.fromJson(Map<String, dynamic> json) {
    return SectionItemFilter(
      type: json['type'],
      gte: double.tryParse(json['gte']?.toString() ?? ''),
      discount: int.tryParse(json['discount']?.toString() ?? ''),
      categoryId: json['categoryid'],
    );
  }

  Map<String, String> toQueryParams() {
    final m = <String, String>{};
    if (type != null) m['filterType'] = type!;
    if (gte != null) m['minPrice'] = gte!.toStringAsFixed(0);
    if (discount != null) m['minDiscount'] = discount!.toString();
    if (categoryId != null) m['categoryId'] = categoryId!;
    return m;
  }
}

class SectionItemMeta {
  final String? name;
  final String? imageUrl;
  final bool showName;
  final bool showDescription;
  final String? description;
  final ColorType colorType;
  final Color background;
  final bool showRating;
  final bool showPrice;
  final bool showDiscount;
  final SectionItemFilter? filter;

  SectionItemMeta({
    this.name,
    this.imageUrl,
    required this.showName,
    required this.showDescription,
    this.description,
    required this.colorType,
    required this.background,
    required this.showRating,
    required this.showPrice,
    required this.showDiscount,
    this.filter,
  });

  factory SectionItemMeta.fromJson(Map<String, dynamic> json) {
    return SectionItemMeta(
      name: json['name'],
      imageUrl: json['imageurl'] ?? json['imageUrl'],
      showName: json['showname'] == true || json['showname'] == 'true',
      showDescription:
          json['showdescription'] == true || json['showdescription'] == 'true',
      description: json['description'],
      colorType:
          json['colortype'] == 'gradient' ? ColorType.gradient : ColorType.simple,
      background: SectionConfig._parseColor(json['background'] ?? 'white'),
      showRating: json['showRating'] == true || json['showRating'] == 'true',
      showPrice: json['showprice'] == true || json['showprice'] == 'true',
      showDiscount:
          json['showdiscount'] == true || json['showdiscount'] == 'true',
      filter: json['filter'] != null
          ? SectionItemFilter.fromJson(Map<String, dynamic>.from(json['filter']))
          : null,
    );
  }
}

class SectionItem {
  final String id;
  final ItemType itemType;
  final String? itemRefId;
  final SectionItemMeta meta;

  SectionItem({
    required this.id,
    required this.itemType,
    this.itemRefId,
    required this.meta,
  });

  factory SectionItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['itemType'] ?? 'UNKNOWN').toString().toUpperCase();
    final type = ItemType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ItemType.UNKNOWN,
    );
    return SectionItem(
      id: json['id'] ?? '',
      itemType: type,
      itemRefId: json['itemRefId'],
      meta: SectionItemMeta.fromJson(
          Map<String, dynamic>.from(json['metadata'] ?? {})),
    );
  }
}

// ─── Section ─────────────────────────────────────────────────────────────────
class Section {
  final String id;
  final String title;
  final SectionType type;
  final SectionConfig config;
  final int position;
  final List<SectionItem> items;
  final String category;
  final bool active;

  Section({
    required this.id,
    required this.title,
    required this.type,
    required this.config,
    required this.position,
    required this.items,
    required this.category,
    required this.active,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'UNKNOWN').toString().toUpperCase();
    final type = SectionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SectionType.UNKNOWN,
    );
    final itemsList = (json['items'] as List? ?? [])
        .map((e) => SectionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return Section(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: type,
      config: SectionConfig.fromJson(
          Map<String, dynamic>.from(json['config'] ?? {})),
      position: int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      items: itemsList,
      category: json['category'] ?? '',
      active: json['active'] == true,
    );
  }
}