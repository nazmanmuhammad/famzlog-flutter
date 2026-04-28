class StoreOption {
  final int id;
  final String storeName;
  final double? latitude;
  final double? longitude;

  StoreOption({
    required this.id,
    required this.storeName,
    this.latitude,
    this.longitude,
  });

  factory StoreOption.fromJson(Map<String, dynamic> json) {
    return StoreOption(
      id: json['id'] as int,
      storeName: json['store_name'] as String,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
