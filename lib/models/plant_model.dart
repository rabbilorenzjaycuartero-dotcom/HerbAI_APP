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
  // One entry per health condition the user flagged on the health-check
  // screen that this herb's own Precautions text actually mentions; empty
  // when no conditions were sent (e.g. herbs fetched via /plants).
  final List<ConditionWarning> conditionWarnings;

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
    this.conditionWarnings = const [],
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
      conditionWarnings: (json['conditionWarnings'] as List<dynamic>? ?? [])
          .map((w) => ConditionWarning.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  // Plants are re-fetched from the API (e.g. a fresh call to /recommend)
  // as new object instances representing the same herb, so equality must
  // be based on id rather than the default identity comparison -- otherwise
  // favorites tracking (PlantProvider.isFavorite/toggleFavorite) breaks
  // across separate fetches of the same plant.
  @override
  bool operator ==(Object other) => other is Plant && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

/// A caution quoted verbatim from this herb's own Precautions text because
/// it mentions a health condition the user flagged -- never a generated
/// safety claim. severity "avoid" means the sentence itself uses
/// avoid/contraindication language; "caution" is a softer "consult a
/// doctor" style deferral.
class ConditionWarning {
  final String condition;
  final String severity;
  final String note;

  const ConditionWarning({
    required this.condition,
    required this.severity,
    required this.note,
  });

  factory ConditionWarning.fromJson(Map<String, dynamic> json) {
    return ConditionWarning(
      condition: json['condition'] as String,
      severity: json['severity'] as String,
      note: json['note'] as String,
    );
  }
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
