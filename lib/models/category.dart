class Category {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<String> tags;
  final int count;
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.tags,
    required this.count,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] as List),
      count: json['count'] as int,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'tags': tags,
      'count': count,
      'color': color,
    };
  }
}
