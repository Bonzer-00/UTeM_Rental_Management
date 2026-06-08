class Property {
  final String id;
  final String homeownerId;
  final String title;
  final String description;
  final double price;
  final String location;
  final double distanceInduk;
  final double distanceTekno; 
  final int capacity;
  final int currentTenants;
  final List<String> facilities;
  final List<String> imageUrls; 

  Property({
    required this.id,
    required this.homeownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.distanceInduk,
    required this.distanceTekno,
    required this.capacity,
    this.currentTenants = 0,
    required this.facilities,
    this.imageUrls = const[], 
  });

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      homeownerId: data['homeownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      
      // Fallbacks in case old properties don't have these fields yet
      distanceInduk: (data['distanceInduk'] ?? data['distanceFromUTeM'] ?? 0).toDouble(),
      distanceTekno: (data['distanceTekno'] ?? data['distanceFromUTeM'] ?? 0).toDouble(),
      
      capacity: data['capacity'] ?? 1,
      currentTenants: data['currentTenants'] ?? 0,
      facilities: List<String>.from(data['facilities'] ??[]),
      imageUrls: List<String>.from(data['imageUrls'] ??[]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeownerId': homeownerId,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'distanceInduk': distanceInduk, 
      'distanceTekno': distanceTekno, 
      'capacity': capacity,
      'currentTenants': currentTenants,
      'facilities': facilities,
      'imageUrls': imageUrls,
    };
  }
}