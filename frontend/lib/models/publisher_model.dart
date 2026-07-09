class PublisherModel {
  final int id;
  final String name;
  final String? address;

  PublisherModel({
    required this.id,
    required this.name,
    this.address,
  });

  factory PublisherModel.fromJson(Map<String, dynamic> json) {
    return PublisherModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}
