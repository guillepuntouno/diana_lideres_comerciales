// modelos/base_entity.dart
class BaseEntity {
  String id;
  int createdAt;
  int updatedAt;
  int deletedAt;
  String createdBy;
  String updatedBy;
  String deletedBy;
  bool isDeleted;

  BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.deletedBy,
    required this.isDeleted,
  });

  factory BaseEntity.fromJson(Map<String, dynamic> json) => BaseEntity(
    id: json['id'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    deletedAt: json['deletedAt'],
    createdBy: json['createdBy'],
    updatedBy: json['updatedBy'],
    deletedBy: json['deletedBy'],
    isDeleted: json['isDeleted'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'deletedBy': deletedBy,
    'isDeleted': isDeleted,
  };
}
