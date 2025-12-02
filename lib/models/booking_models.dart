// Booking Status Enums
enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
  completed;

  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}

enum PaymentStatus {
  unpaid,
  paid,
  refunded,
  partiallyRefunded;

  String get value {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
    }
  }

  static PaymentStatus fromString(String status) {
    switch (status) {
      case 'unpaid':
        return PaymentStatus.unpaid;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      default:
        return PaymentStatus.unpaid;
    }
  }
}

// Booking Model
class BookingDocument {
  final String id;
  final String propertyId;
  final String guestId;
  final String agentId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final int numberOfNights;
  final double pricePerNight;
  final double subtotal;
  final double serviceFee;
  final double totalPrice;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? specialRequests;
  final String? rejectionReason;
  final String? cancelledBy;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingDocument({
    required this.id,
    required this.propertyId,
    required this.guestId,
    required this.agentId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.numberOfNights,
    required this.pricePerNight,
    required this.subtotal,
    required this.serviceFee,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.specialRequests,
    this.rejectionReason,
    this.cancelledBy,
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingDocument.fromJson(Map<String, dynamic> json) {
    return BookingDocument(
      id: (json['\$id'] ?? '') as String,
      propertyId: (json['propertyId'] ?? '') as String,
      guestId: (json['guestId'] ?? '') as String,
      agentId: (json['agentId'] ?? '') as String,
      checkInDate: DateTime.parse((json['checkInDate'] ?? '') as String),
      checkOutDate: DateTime.parse((json['checkOutDate'] ?? '') as String),
      numberOfGuests: (json['numberOfGuests'] ?? 0) as int,
      numberOfNights: (json['numberOfNights'] ?? 0) as int,
      pricePerNight: ((json['pricePerNight'] ?? 0) as num).toDouble(),
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      serviceFee: ((json['serviceFee'] ?? 0) as num).toDouble(),
      totalPrice: ((json['totalPrice'] ?? 0) as num).toDouble(),
      status: BookingStatus.fromString((json['status'] ?? 'pending') as String),
      paymentStatus: PaymentStatus.fromString((json['paymentStatus'] ?? 'unpaid') as String),
      specialRequests: json['specialRequests'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'guestId': guestId,
      'agentId': agentId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'numberOfNights': numberOfNights,
      'pricePerNight': pricePerNight,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'totalPrice': totalPrice,
      'status': status.value,
      'paymentStatus': paymentStatus.value,
      'specialRequests': specialRequests,
      'rejectionReason': rejectionReason,
      'cancelledBy': cancelledBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }
}

// Payment Model
class PaymentDocument {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentGateway;
  final String transactionId;
  final String status;
  final String? receiptUrl;
  final double? refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;
  final String? gatewayResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentDocument({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentGateway,
    required this.transactionId,
    required this.status,
    this.receiptUrl,
    this.refundAmount,
    this.refundReason,
    this.refundedAt,
    this.gatewayResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentDocument.fromJson(Map<String, dynamic> json) {
    return PaymentDocument(
      id: (json['\$id'] ?? '') as String,
      bookingId: (json['bookingId'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'USD') as String,
      paymentMethod: (json['paymentMethod'] ?? '') as String,
      paymentGateway: (json['paymentGateway'] ?? '') as String,
      transactionId: (json['transactionId'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      receiptUrl: json['receiptUrl'] as String?,
      refundAmount: json['refundAmount'] != null ? ((json['refundAmount']) as num).toDouble() : null,
      refundReason: json['refundReason'] as String?,
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt'] as String) : null,
      gatewayResponse: json['gatewayResponse'] as String?,
      createdAt: DateTime.parse((json['\$createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['\$updatedAt'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentGateway': paymentGateway,
      'transactionId': transactionId,
      'status': status,
      'receiptUrl': receiptUrl,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
      'refundedAt': refundedAt?.toIso8601String(),
      'gatewayResponse': gatewayResponse,
    };
  }
}
