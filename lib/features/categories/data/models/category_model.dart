import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String emoji;
  final int iconCode;
  final int colorValue;
  final bool isIncome;
  final bool isDefault;
  final String userEmail;

  CategoryModel({
    this.id,
    required this.name,
    required this.emoji,
    required this.iconCode,
    required this.colorValue,
    required this.isIncome,
    this.isDefault = false,
    required this.userEmail,
  });

  Color get color => Color(colorValue);
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'isIncome': isIncome ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'userEmail': userEmail,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '🏷️',
      iconCode: map['iconCode'] as int? ?? 0xe14d,
      colorValue: map['colorValue'] as int? ?? 0xFF06B6D4,
      isIncome: (map['isIncome'] as int) == 1,
      isDefault: (map['isDefault'] as int) == 1,
      userEmail: map['userEmail'] as String? ?? '',
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? emoji,
    int? iconCode,
    int? colorValue,
    bool? isIncome,
    bool? isDefault,
    String? userEmail,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isIncome: isIncome ?? this.isIncome,
      isDefault: isDefault ?? this.isDefault,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
