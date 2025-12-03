// Property Model
class PropertyDocument {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final String type;
  final String category;
  final int price;
  final List<String> facilities;
  final String image;
  final List<String> gallery;
  final String agentId;
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.type,
    required this.category,
    required this.price,
    required this.facilities,
    required this.image,
    required this.gallery,
    required this.agentId,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.reviewsCount = 0,
  });

  factory PropertyDocument.fromJson(Map<String, dynamic> json) {
    return PropertyDocument(
      id: (json['\$id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      latitude: ((json['latitude'] ?? 0.0) as num).toDouble(),
      longitude: ((json['longitude'] ?? 0.0) as num).toDouble(),
      bedrooms: (json['bedrooms'] ?? 0) as int,
      bathrooms: (json['bathrooms'] ?? 0) as int,
      area: (json['area'] ?? 0) as int,
      type: (json['type'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      price: (json['price'] ?? 0) as int,
      facilities: (json['facilities'] as List? ?? []).cast<String>(),
      image: (json['image'] ?? '') as String,
      gallery: (json['gallery'] as List? ?? []).cast<String>(),
      agentId: (json['agentId'] ?? '') as String,
      rating: ((json['rating'] ?? 0.0) as num).toDouble(),
      reviewsCount: (json['reviewsCount'] ?? 0) as int,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'type': type,
      'category': category,
      'price': price,
      'facilities': facilities,
      'image': image,
      'gallery': gallery,
      'agentId': agentId,
      'rating': rating,
      'reviewsCount': reviewsCount,
    };
  }
}

// Agent Model
class AgentDocument {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final double rating;
  final int propertiesCount;
  final int completedDeals;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgentDocument({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.propertiesCount = 0,
    this.completedDeals = 0,
  });

  factory AgentDocument.fromJson(Map<String, dynamic> json) {
    return AgentDocument(
      id: (json['\$id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      avatar: (json['avatar'] ?? '') as String,
      rating: ((json['rating'] ?? 0.0) as num).toDouble(),
      propertiesCount: ((json['propertiesCount'] ?? 0) as num).toInt(),
      completedDeals: ((json['completedDeals'] ?? 0) as num).toInt(),
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'rating': rating,
      'propertiesCount': propertiesCount,
      'completedDeals': completedDeals,
    };
  }
}

// Review Model
class ReviewDocument {
  final String id;
  final String propertyId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final List<String> images;
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewDocument({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.images = const [],
    this.verified = false,
    this.verifiedAt,
  });

  factory ReviewDocument.fromJson(Map<String, dynamic> json) {
    return ReviewDocument(
      id: (json['\$id'] ?? '') as String,
      propertyId: (json['propertyId'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      rating: ((json['rating'] ?? 0.0) as num).toDouble(),
      comment: (json['comment'] ?? '') as String,
      images: (json['images'] as List? ?? []).cast<String>(),
      verified: (json['verified'] ?? false) as bool,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'images': images,
      'verified': verified,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}

// User Info Model (minimal)
class UserInfo {
  final String id;
  final String name;
  final String? email;
  final String? avatar;

  UserInfo({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['\$id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: json['email'] as String?,
      avatar: (json['avatar'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}
