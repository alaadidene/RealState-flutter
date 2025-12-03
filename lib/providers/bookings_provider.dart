import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env_config.dart';
import '../models/booking_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

class BookingsState {
  final List<BookingDocument> bookings;
  final bool isLoading;
  final String? error;
  final bool isConnected;

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
  });

  BookingsState copyWith({
    List<BookingDocument>? bookings,
    bool? isLoading,
    String? error,
    bool? isConnected,
  }) => BookingsState(
        bookings: bookings ?? this.bookings,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        isConnected: isConnected ?? this.isConnected,
      );
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final AppwriteService _service;
  final Ref _ref;
  RealtimeSubscription? _subscription;

  BookingsNotifier(this._service, this._ref)
      : super(const BookingsState()) {
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getUserBookings(user.$id);
      items.sort((BookingDocument a, BookingDocument b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(bookings: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => _load();

  Future<void> createBooking(BookingDocument booking) async {
    try {
      await _service.createBooking(booking: booking);
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _service.databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
        data: {'status': status},
      );
      
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
  }

  void _subscribe() {
    try {
      final channel =
          'databases.${EnvConfig.appwriteDatabaseId}.collections.${EnvConfig.bookingsCollectionId}.documents';
      _subscription = _service.realtime.subscribe([channel]);
      _subscription!.stream.listen((event) {
        try {
          state = state.copyWith(isConnected: true);
          final payload = event.payload;
          final booking = BookingDocument.fromJson(payload);
          
          if (event.events.any((e) => e.endsWith('create'))) {
            final next = [booking, ...state.bookings];
            state = state.copyWith(bookings: next);
          } else if (event.events.any((e) => e.endsWith('update'))) {
            final next = state.bookings
                .map((b) => b.id == booking.id ? booking : b)
                .toList();
            state = state.copyWith(bookings: next);
          } else if (event.events.any((e) => e.endsWith('delete'))) {
            state = state.copyWith(
              bookings: state.bookings.where((b) => b.id != booking.id).toList(),
            );
          }
        } catch (_) {}
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final service = ref.watch(appwriteServiceProvider);
  return BookingsNotifier(service, ref);
});

// Booking requests for property owners
class BookingRequestsState {
  final List<BookingDocument> requests;
  final bool isLoading;
  final String? error;

  const BookingRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  BookingRequestsState copyWith({
    List<BookingDocument>? requests,
    bool? isLoading,
    String? error,
  }) => BookingRequestsState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class BookingRequestsNotifier extends StateNotifier<BookingRequestsState> {
  final AppwriteService _service;
  final Ref _ref;

  BookingRequestsNotifier(this._service, this._ref)
      : super(const BookingRequestsState()) {
    _load();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get all bookings where user is the property owner
      final response = await _service.databases.listDocuments(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        queries: [
          Query.equal('hostId', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );
      
      final items = response.documents
          .map((doc) => BookingDocument.fromJson(doc.data))
          .toList();
      
      state = state.copyWith(requests: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => _load();

  Future<void> acceptBooking(String bookingId) async {
    try {
      await _service.databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
        data: {'status': 'confirmed'},
      );
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      await _service.databases.updateDocument(
        databaseId: EnvConfig.appwriteDatabaseId,
        collectionId: EnvConfig.bookingsCollectionId,
        documentId: bookingId,
        data: {'status': 'rejected'},
      );
      _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final bookingRequestsProvider =
    StateNotifierProvider<BookingRequestsNotifier, BookingRequestsState>((ref) {
  final service = ref.watch(appwriteServiceProvider);
  return BookingRequestsNotifier(service, ref);
});

// Agent bookings provider - accepts agent ID parameter
final agentBookingsProvider = StateNotifierProvider.family<AgentBookingsNotifier, AsyncValue<List<BookingDocument>>, String>((ref, agentId) {
  final service = ref.watch(appwriteServiceProvider);
  return AgentBookingsNotifier(service, agentId);
});

class AgentBookingsNotifier extends StateNotifier<AsyncValue<List<BookingDocument>>> {
  final AppwriteService _service;
  final String _agentId;

  AgentBookingsNotifier(this._service, this._agentId) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      state = const AsyncValue.loading();
      final bookings = await _service.getAgentBookings(_agentId);
      state = AsyncValue.data(bookings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
