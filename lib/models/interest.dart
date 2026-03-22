class Interest {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String color;
  final int count;
  final int popularity;
  final List<String> tags;

  Interest({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    required this.count,
    required this.popularity,
    required this.tags,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      count: json['count'] as int,
      popularity: json['popularity'] as int,
      tags: List<String>.from(json['tags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'color': color,
      'count': count,
      'popularity': popularity,
      'tags': tags,
    };
  }
}

