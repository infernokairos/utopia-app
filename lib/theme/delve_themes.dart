import 'package:flutter/material.dart';
import 'delve_theme.dart';

/// Clean minimalist monochrome dark themes for Delve.
class DelveThemes {
  /// Midnight Graphite
  static const mapleDark = DelveTheme(
    name: 'Graphite',
    background: Color(0xFF16181A),
    text: Color(0xFFE6E8EB),
    botanicalInk: Color(0xFF6B7280), 
    accent: Color(0xFFFFFFFF), 
    accentSecondary: Color(0xFFD1D5DB),
    isDark: true,
    feel: 'Refined cool graphite.',
    flowerType: FlowerType.maple,
  );

  /// Grayscale Dark 1
  static const wisteriaLight = DelveTheme(
    name: 'Monochrome 1',
    background: Color(0xFF080808),
    text: Color(0xFFFAFAFA),
    botanicalInk: Color(0xFF71717A),
    accent: Color(0xFFFFFFFF), 
    accentSecondary: Color(0xFFE4E4E7),
    isDark: true,
    feel: 'Ultra minimalist dark tone.',
    flowerType: FlowerType.wisteria,
  );

  /// Grayscale Dark 2
  static const bauhiniaLight = DelveTheme(
    name: 'Monochrome 2',
    background: Color(0xFF0D0D0E),
    text: Color(0xFFF4F4F5),
    botanicalInk: Color(0xFF52525B),
    accent: Color(0xFFFAFAFA), 
    accentSecondary: Color(0xFFD4D4D8),
    isDark: true,
    feel: 'Crisp structural dark workspace.',
    flowerType: FlowerType.bauhinia,
  );

  /// Grayscale Dark 3
  static const sakuraLight = DelveTheme(
    name: 'Monochrome 3',
    background: Color(0xFF141416),
    text: Color(0xFFFFFFFF),
    botanicalInk: Color(0xFF71717A),
    accent: Color(0xFFFFFFFF), 
    accentSecondary: Color(0xFFE4E4E7),
    isDark: true,
    feel: 'Clean typography focus.',
    flowerType: FlowerType.sakura,
  );

  /// Grayscale Dark 4
  static const mapleLight = DelveTheme(
    name: 'Monochrome 4',
    background: Color(0xFF18181B),
    text: Color(0xFFFAFAFA),
    botanicalInk: Color(0xFFA1A1AA),
    accent: Color(0xFFFFFFFF), 
    accentSecondary: Color(0xFFD4D4D8),
    isDark: true,
    feel: 'Subtle slate elegance.',
    flowerType: FlowerType.maple,
  );

  /// Rose Gold (light)
  static const roseGoldLight = DelveTheme(
    name: 'Rose Gold',
    background: Color(0xFFFAF8F7),
    text: Color(0xFF1F191B),
    botanicalInk: Color(0xFFE6DDD8),
    accent: Color(0xFFC2727E),
    accentSecondary: Color(0xFFD47A62),
    isDark: false,
    feel: 'Clean ivory canvas with elegant rose-gold highlights.',
    flowerType: FlowerType.sakura,
  );

  /// Baby Lav (light)
  static const purpleBabyLight = DelveTheme(
    name: 'Baby Lav',
    background: Color(0xFFF7F5FC),
    text: Color(0xFF1B1626),
    botanicalInk: Color(0xFFE2D9F3),
    accent: Color(0xFF8353E2),
    accentSecondary: Color(0xFF537BE2),
    isDark: false,
    feel: 'Restorative lavender pastel palette with soothing digital violet accents.',
    flowerType: FlowerType.wisteria,
  );

  /// Sweet Lime (dark)
  static const sweetLimeDark = DelveTheme(
    name: 'Sweet Lime',
    background: Color(0xFF0B0F0B),
    text: Color(0xFFF1F7F1),
    botanicalInk: Color(0xFF263A29),
    accent: Color(0xFF84E042),
    accentSecondary: Color(0xFF38D9A9),
    isDark: true,
    feel: 'Vibrant lime & electric citrus on deep obsidian slate.',
    flowerType: FlowerType.bauhinia,
  );

  /// Say Inferno (dark)
  static const sayInfernoDark = DelveTheme(
    name: 'Say Inferno',
    background: Color(0xFF120F10),
    text: Color(0xFFFFFBF7),
    botanicalInk: Color(0xFF5C2016),
    accent: Color(0xFFFF3D00),
    accentSecondary: Color(0xFFFF6D00),
    isDark: true,
    feel: 'Blazing flame red & warm ember soot dark mode.',
    flowerType: FlowerType.maple,
  );

  static const List<DelveTheme> all = [
    sayInfernoDark,
    sweetLimeDark,
    roseGoldLight,
    purpleBabyLight,
    mapleDark,
    wisteriaLight,
    bauhiniaLight,
    sakuraLight,
    mapleLight,
  ];

  static List<DelveTheme> get darkThemes => all.where((t) => t.isDark).toList();
  static List<DelveTheme> get lightThemes => all.where((t) => !t.isDark).toList();

  static DelveTheme getByName(String name) {
    return all.firstWhere((t) => t.name == name, orElse: () => sweetLimeDark);
  }

  static DelveTheme getByNameAndMode(String name, bool isDark) {
    return getByName(name);
  }
}
