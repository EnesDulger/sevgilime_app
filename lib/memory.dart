import 'package:flutter/material.dart';

// Veri Modeli
class Memory {
  final String text;      // Notun içeriği
  final String mood;      // Hangi moda ait olduğu
  final Color color;      // Kartın rengi

  Memory({
    required this.text,
    required this.mood,
    required this.color
  });
}