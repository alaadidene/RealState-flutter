import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_models.dart';
import '../../services/appwrite_service.dart';

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  String _filter = 'pending';
  bool _processingAction = false;
  
  // Reject modal state
  BookingDocument? _selectedBooking;
  bool _showRejectModal = false;
  final _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        await ref.read(agentBookingsProvider(currentUser.$id).notifier).loadBookings();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleAcceptBooking(BookingDocument booking) async {
    if (booking.paymentStatus == PaymentStatus.paid) {
      _showAlert('Already paid', 'This booking was auto-confirmed because the guest paid online.');
      return;
    }

    setState(() => _processingAction = true);
    try {
      await AppwriteService().updateBookingStatus(booking.id, BookingStatus.confirmed.value);
      _showAlert('Success', 'Booking accepted.');
      await _loadBookings();
    } catch (error) {
      _showAlert('Error', 'Failed to accept booking');
    } finally {
      setState(() => _processingAction = false);
    }
  }

  void _handleRejectBooking(BookingDocument booking) {
    setState(() {
      _selectedBooking = booking;
      _rejectionReasonController.clear();
      _showRejectModal = true;
    });
  }

  Future<void> _submitRejection() async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      _showAlert('Required', 'Please provide a reason for rejection');
      return;
    }

    if (_selectedBooking == null) return;

    setState(() => _processingAction = true);
    try {
      await AppwriteService().updateBookingStatus(
        _selectedBooking!.id,
        BookingStatus.rejected.value,
        rejectionReason: _rejectionReasonController.text.trim(),
      );
      _showAlert('Success', 'Booking rejected. The guest has been notified.');
      setState(() => _showRejectModal = false);
      await _loadBookings();
    } catch (error) {
      _showAlert('Error', 'Failed to reject booking');
    } finally {
      setState(() => _processingAction = false);
    }
  }

  void _handleViewGuestProfile(String? guestId) {
    if (guestId == null) {
      _showAlert('Unavailable', 'Guest profile is not accessible right now.');
      return;
    }
    context.push('/agent-profile/$guestId');
  }

  void _handleEmailPress(String? email) {
    if (email == null || email == 'Not provided') {
      _showAlert('Unavailable', 'Guest email not available.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact guest'),
        content: Text(email),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (mounted) {
                Navigator.pop(context);
                _showAlert('Copied', 'Email copied to clipboard.');
              }
            },
            child: const Text('Copy email'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final mailUrl = Uri.parse('mailto:$email');
              if (await canLaunchUrl(mailUrl)) {
                await launchUrl(mailUrl);
              } else {
                _showAlert('Unavailable', 'No email app found on this device.');
              }
            },
            child: const Text('Send email'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handlePhonePress(String? phone) {
    if (phone == null || phone == 'Not provided') {
      _showAlert('Unavailable', 'Guest phone number not available.');
      return;
    }

    final sanitizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitizedPhone.isEmpty) {
      _showAlert('Invalid', 'Phone number format is invalid.');
      return;
    }

    final phoneUrl = Uri.parse('tel:$sanitizedPhone');
    launchUrl(phoneUrl).catchError((_) {
      _showAlert('Unsupported', 'Phone calls are not supported on this device.');
      return false;
    });
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<BookingDocument> _getFilteredBookings(List<BookingDocument> bookings) {
    if (_filter == 'all') return bookings;
    return bookings.where((b) => b.status.value == _filter).toList();
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.yellow[100]!;
      case BookingStatus.confirmed:
        return Colors.green[100]!;
      case BookingStatus.rejected:
        return Colors.red[100]!;
      case BookingStatus.cancelled:
        return Colors.grey[100]!;
      case BookingStatus.completed:
        return Colors.blue[100]!;
    }
  }

  Color _getStatusTextColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.yellow[800]!;
      case BookingStatus.confirmed:
        return Colors.green[800]!;
      case BookingStatus.rejected:
        return Colors.red[800]!;
      case BookingStatus.cancelled:
        return Colors.grey[800]!;
      case BookingStatus.completed:
        return Colors.blue[800]!;
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green[100]!;
      case PaymentStatus.unpaid:
        return Colors.orange[100]!;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.purple[100]!;
    }
  }

  Color _getPaymentTextColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green[800]!;
      case PaymentStatus.unpaid:
        return Colors.orange[800]!;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.purple[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bookingsAsync = ref.watch(agentBookingsProvider(currentUser.$id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Requests',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage bookings for your properties',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: ['all', 'pending', 'confirmed', 'cancelled'].map((status) {
                  final isSelected = _filter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _filter = status);
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF0061FF),
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bookings List
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading booking requests',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (bookings) {
                  final filteredBookings = _getFilteredBookings(bookings);

                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_filter != "all" ? _filter : ""} booking requests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Booking requests for your properties will appear here',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        return _BookingRequestCard(
                          booking: booking,
                          onAccept: () => _handleAcceptBooking(booking),
                          onReject: () => _handleRejectBooking(booking),
                          onViewGuestProfile: () => _handleViewGuestProfile(booking.guestId),
                          onEmailPress: () => _handleEmailPress(null),
                          onPhonePress: () => _handlePhonePress(null),
                          onViewProperty: () => context.push('/properties/${booking.propertyId}'),
                          processingAction: _processingAction,
                          getStatusColor: _getStatusColor,
                          getStatusTextColor: _getStatusTextColor,
                          getPaymentColor: _getPaymentColor,
                          getPaymentTextColor: _getPaymentTextColor,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Rejection Modal
      floatingActionButton: _showRejectModal ? Container() : null,
      bottomSheet: _showRejectModal
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reject Booking Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedBooking != null) ...[
                          Text(
                            'Booking ID: ${_selectedBooking!.id.substring(0, 8)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dates: ${DateFormat('MMM d, yyyy').format(_selectedBooking!.checkInDate)} - ${DateFormat('MMM d, yyyy').format(_selectedBooking!.checkOutDate)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Reason for Rejection *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _rejectionReasonController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Please provide a reason (required)',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _showRejectModal = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: const Color(0xFF1A1A1A),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _processingAction ? null : _submitRejection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _processingAction
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Reject Booking',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final BookingDocument booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewGuestProfile;
  final VoidCallback onEmailPress;
  final VoidCallback onPhonePress;
  final VoidCallback onViewProperty;
  final bool processingAction;
  final Color Function(BookingStatus) getStatusColor;
  final Color Function(BookingStatus) getStatusTextColor;
  final Color Function(PaymentStatus) getPaymentColor;
  final Color Function(PaymentStatus) getPaymentTextColor;

  const _BookingRequestCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
    required this.onViewGuestProfile,
    required this.onEmailPress,
    required this.onPhonePress,
    required this.onViewProperty,
    required this.processingAction,
    required this.getStatusColor,
    required this.getStatusTextColor,
    required this.getPaymentColor,
    required this.getPaymentTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final propertyTitle = 'Property ${booking.propertyId.substring(booking.propertyId.length - 6)}';
    const guestEmail = 'Not provided';
    const guestPhone = 'Not provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Summary Row
            Row(
              children: [
                GestureDetector(
                  onTap: onViewProperty,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0061FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🏡', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR PROPERTY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0061FF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        propertyTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status.value.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getStatusTextColor(booking.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: getPaymentColor(booking.paymentStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.paymentStatus.value.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getPaymentTextColor(booking.paymentStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Guest Info Card
            if (booking.guest != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[100]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to guest profile
                        // context.push('/agent-profile/${booking.guestId}');
                      },
                      child: Row(
                        children: [
                          // Guest avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xFF0061FF).withValues(alpha: 0.1),
                            ),
                            child: booking.guest!['avatar'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(
                                      booking.guest!['avatar'] as String,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      (booking.guest!['name'] as String? ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0061FF),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guest contact',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.guest!['name'] as String? ?? 'Guest',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap to view profile',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF0061FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final guestEmail = booking.guest!['email'] as String?;
                              if (guestEmail != null) {
                                // TODO: Implement email dialog
                                // _handleEmailPress(guestEmail);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[100]!),
                              ),
                              child: Row(
                                children: [
                                  const Text('@',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0061FF))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          booking.guest!['email'] as String? ?? 'Not provided',
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final guestPhone = booking.guest!['phone'] as String?;
                              if (guestPhone != null) {
                                // TODO: Implement phone call
                                // _handlePhonePress(guestPhone);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[100]!),
                              ),
                              child: Row(
                                children: [
                                  const Text('☎',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0061FF))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          booking.guest!['phone'] as String? ?? 'Not provided',
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Dates
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-in', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(booking.checkInDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-out', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(booking.checkOutDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _DetailItem(label: 'Guests', value: booking.numberOfGuests.toString()),
                _DetailItem(label: 'Nights', value: booking.numberOfNights.toString()),
                _DetailItem(
                  label: 'Total',
                  value: '\$${booking.totalPrice.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF0061FF),
                ),
                _DetailItem(
                  label: 'Your Earnings',
                  value: '\$${booking.subtotal.toStringAsFixed(2)}',
                  valueColor: Colors.green[600],
                ),
              ],
            ),

            // Special Requests
            if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special Requests:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.specialRequests!,
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],

            // Rejection Reason
            if (booking.status == BookingStatus.rejected && booking.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.rejectionReason!,
                      style: TextStyle(fontSize: 14, color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (booking.status == BookingStatus.pending && booking.paymentStatus != PaymentStatus.paid) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: processingAction ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: processingAction
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: processingAction ? null : onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Timestamp
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Text(
                'Requested on ${DateFormat('MMM d, yyyy, hh:mm a').format(booking.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
