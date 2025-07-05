class PickupLine {
  final String id;
  final String text;
  final String category;
  final String context;
  final int intensity;
  final bool isFavorite;
  final DateTime? createdAt;
  final List<String>? tags;

  PickupLine({
    required this.id,
    required this.text,
    required this.category,
    required this.context,
    required this.intensity,
    this.isFavorite = false,
    this.createdAt,
    this.tags,
  });

  factory PickupLine.fromJson(Map<String, dynamic> json) {
    return PickupLine(
      id: json['id'],
      text: json['text'],
      category: json['category'],
      context: json['context'],
      intensity: json['intensity'],
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'context': context,
      'intensity': intensity,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.toIso8601String(),
      'tags': tags,
    };
  }

  PickupLine copyWith({
    String? id,
    String? text,
    String? category,
    String? context,
    int? intensity,
    bool? isFavorite,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return PickupLine(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      context: context ?? this.context,
      intensity: intensity ?? this.intensity,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}

// Énumérations pour les catégories et contextes
enum PickupLineCategory {
  classiques('classiques', 'Classiques', '💎'),
  drole('drole', 'Drôle', '😂'),
  intellectuel('intellectuel', 'Intellectuel', '🧠'),
  directe('directe', 'Directe', '🔥'),
  surprenante('surprenante', 'Surprenante', '⚡'),
  situationniste('situationniste', 'Situationniste', '🎯');

  const PickupLineCategory(this.name, this.displayName, this.emoji);
  
  final String name;
  final String displayName;
  final String emoji;
}

enum PickupContext {
  general('general', 'Général', '💬'),
  bar('bar', 'Bar/Soirée', '🍸'),
  app('app', 'App de rencontre', '📱'),
  cafe('cafe', 'Café/Restaurant', '☕'),
  salle('salle', 'Salle de sport', '💪'),
  plage('plage', 'Plage/Vacances', '🏖️');

  const PickupContext(this.name, this.displayName, this.emoji);
  
  final String name;
  final String displayName;
  final String emoji;
}
