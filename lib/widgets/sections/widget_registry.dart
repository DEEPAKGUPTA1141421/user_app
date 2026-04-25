import 'package:flutter/material.dart';
import '../../model/section_v2.dart';
import 'banner_widget.dart';
import 'brand_feature_widget.dart';
import 'brand_rail_widget.dart';
import 'category_tiles_widget.dart';
import 'grid_widget.dart';
import 'highlight_widget.dart';
import 'rail_widget.dart';

typedef OnNavigate = void Function(String route, Map<String, String> params);
typedef SectionBuilder = Widget Function(SectionV2 section, OnNavigate? onNavigate);

/// The ONLY file you edit to add a new layout.
/// widgetKey (backend JSONB) → Flutter widget factory.
final Map<String, SectionBuilder> widgetRegistry = {
  'banner_hero_v1': (s, nav) => BannerWidget(section: s, onNavigate: nav),
  'product_grid_v1': (s, nav) => GridWidget(section: s, onNavigate: nav),
  'product_scroll_v1': (s, nav) => RailWidget(section: s, onNavigate: nav),
  'product_highlight_v1': (s, nav) =>
      HighlightWidget(section: s, onNavigate: nav),
  'brand_spotlight_v1': (s, nav) =>
      BrandRailWidget(section: s, onNavigate: nav),
  'brand_feature_v1': (s, nav) =>
      BrandFeatureWidget(section: s, onNavigate: nav),
  'category_tiles_v1': (s, nav) =>
      CategoryTilesWidget(section: s, onNavigate: nav),
};
