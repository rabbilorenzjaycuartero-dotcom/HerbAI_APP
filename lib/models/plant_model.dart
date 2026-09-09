import 'package:flutter/material.dart';

class Plant {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final double rating;
  final int reviewCount;
  final List<String> medicinalUses;
  final List<String> preparationMethods;
  final List<String> safetyWarnings;
  final String ethnobotanicalInfo;
  final String imageUrl;
  final List<String> categories;
  final List<String> symptomsHelped;
  final AvailabilityStatus availability;
  final SafetyInfo safetyInfo;
  final bool isDohRecognized;
  final bool isEasyToPrepare;
  // Only present on results from the /recommend endpoint (how well this
  // herb matches the selected symptoms); null for herbs fetched via /plants.
  final double? relevanceScore;

  Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.medicinalUses,
    required this.preparationMethods,
    required this.safetyWarnings,
    required this.ethnobotanicalInfo,
    required this.imageUrl,
    required this.categories,
    required this.symptomsHelped,
    required this.availability,
    required this.safetyInfo,
    this.isDohRecognized = true,
    this.isEasyToPrepare = true,
    this.relevanceScore,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      medicinalUses: List<String>.from(json['medicinalUses'] as List? ?? []),
      preparationMethods:
          List<String>.from(json['preparationMethods'] as List? ?? []),
      safetyWarnings: List<String>.from(json['safetyWarnings'] as List? ?? []),
      ethnobotanicalInfo: json['ethnobotanicalInfo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      categories: List<String>.from(json['categories'] as List? ?? []),
      symptomsHelped: List<String>.from(json['symptomsHelped'] as List? ?? []),
      availability: AvailabilityStatus.values.firstWhere(
        (e) => e.name == json['availability'],
        orElse: () => AvailabilityStatus.common,
      ),
      safetyInfo: SafetyInfo.fromJson(
        json['safetyInfo'] as Map<String, dynamic>? ?? const {},
      ),
      isDohRecognized: json['isDohRecognized'] as bool? ?? false,
      isEasyToPrepare: json['isEasyToPrepare'] as bool? ?? true,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble(),
    );
  }
}

enum AvailabilityStatus {
  common("Common", Colors.green),
  uncommon("Uncommon", Colors.orange),
  rare("Rare", Colors.red);

  const AvailabilityStatus(this.label, this.color);
  final String label;
  final Color color;
}

class SafetyInfo {
  // null = not verified/unknown (no gathered data), not a false safety claim.
  final bool? safeForAdults;
  final bool? safeForChildren;
  final bool? safeForElderly;
  final bool? safeForPregnant;

  const SafetyInfo({
    this.safeForAdults,
    this.safeForChildren,
    this.safeForElderly,
    this.safeForPregnant,
  });

  factory SafetyInfo.fromJson(Map<String, dynamic> json) {
    return SafetyInfo(
      safeForAdults: json['safeForAdults'] as bool?,
      safeForChildren: json['safeForChildren'] as bool?,
      safeForElderly: json['safeForElderly'] as bool?,
      safeForPregnant: json['safeForPregnant'] as bool?,
    );
  }
}

class Review {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class Symptom {
  final String id;
  final String name;
  final String? icon;

  const Symptom({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}
