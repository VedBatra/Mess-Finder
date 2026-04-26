// lib/models/menu.dart

class MenuItem {
  final String name;
  final String? description;

  const MenuItem({required this.name, this.description});

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        name: json['name'] as String,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}

class Menu {
  final String id;
  final String messId;
  final String dayOfWeek;
  final String mealType; // lunch or dinner
  final List<String> items;
  final DateTime? createdAt;

  const Menu({
    required this.id,
    required this.messId,
    required this.dayOfWeek,
    required this.mealType,
    required this.items,
    this.createdAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    List<String> parsedItems = [];
    final rawItems = json['items'];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => e.toString()).toList();
    } else if (rawItems is String) {
      // Comma-separated fallback
      parsedItems = rawItems.split(',').map((e) => e.trim()).toList();
    }
    return Menu(
      id: json['id'] as String,
      messId: json['mess_id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      mealType: json['meal_type'] as String,
      items: parsedItems,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mess_id': messId,
        'day_of_week': dayOfWeek,
        'meal_type': mealType,
        'items': items,
        'created_at': createdAt?.toIso8601String(),
      };

  Menu copyWith({
    String? dayOfWeek,
    String? mealType,
    List<String>? items,
  }) {
    return Menu(
      id: id,
      messId: messId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
      createdAt: createdAt,
    );
  }
}
