class Property {
  final String id;
  final String homeownerId;
  final String title;
  final String description;
  final double price;
  final double deposit;        
  final double utilities;      
  final double additionalFees; 
  final String location;
  final double distanceInduk; 
  final double distanceTekno; 
  final double latitude;  
  final double longitude; 
  final int capacity;
  final int currentTenants;
  final List<String> facilities;
  final List<String> imageUrls; 
  final String customRules; // <--- NEW: Stores homeowner's custom lease rules! [1]

  Property({
    required this.id,
    required this.homeownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.deposit,        
    required this.utilities,      
    this.additionalFees = 0.0,    
    required this.location,
    required this.distanceInduk,
    required this.distanceTekno,
    required this.latitude,  
    required this.longitude, 
    required this.capacity,
    this.currentTenants = 0,
    required this.facilities,
    this.imageUrls = const[], 
    this.customRules = '', // <--- NEW (Defaults to empty string) [1]
  });

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      homeownerId: data['homeownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),               
      utilities: (data['utilities'] ?? 0).toDouble(),             
      additionalFees: (data['additionalFees'] ?? 0).toDouble(), 
      location: data['location'] ?? '',
      distanceInduk: (data['distanceInduk'] ?? 0).toDouble(),
      distanceTekno: (data['distanceTekno'] ?? 0).toDouble(),
      latitude: (data['latitude'] ?? 2.3083).toDouble(),   
      longitude: (data['longitude'] ?? 102.3177).toDouble(), 
      capacity: data['capacity'] ?? 1,
      currentTenants: data['currentTenants'] ?? 0,
      facilities: List<String>.from(data['facilities'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      customRules: data['customRules'] ?? '', // <--- NEW [1]
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeownerId': homeownerId,
      'title': title,
      'description': description,
      'price': price,
      'deposit': deposit,               
      'utilities': utilities,           
      'additionalFees': additionalFees, 
      'location': location,
      'distanceInduk': distanceInduk, 
      'distanceTekno': distanceTekno, 
      'latitude': latitude,   
      'longitude': longitude, 
      'capacity': capacity,
      'currentTenants': currentTenants,
      'facilities': facilities,
      'imageUrls': imageUrls,
      'customRules': customRules, // <--- NEW [1]
    };
  }
}