class Item {
  final String id;
  final String name;
  final List<String> description;
  final String photoUrl;
  final String qtyTotal;
  final String qtyAvailable;
  final String isActive;

  Item({
    this.id = '',
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.qtyTotal,
    required this.qtyAvailable,
    required this.isActive,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] != null
          ? List<String>.from(json['description'].map((e) => e.toString()))
          : <String>[],
      photoUrl: json['photoUrl']?.toString() ?? '',
      qtyTotal: json['qtyTotal']?.toString() ?? '',
      qtyAvailable: json['qtyAvailable']?.toString() ?? '',
      isActive: json['isActive']?.toString() ?? '',
    );
  }
}
