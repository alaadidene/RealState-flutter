import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_models.dart';
import '../../components/payment_method_sheet.dart';
import '../../services/appwrite_service.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _filter = 'all';
  BookingDocument? _bookingToPay;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bookingsProvider.notifier).refresh());
  }

  void _handleViewAgentProfile(String? agentId) {
    if (agentId == null) {
      _showAlert('Unavailable', 'Host profile is not accessible right now.');
      return;
    }
    context.push('/agent-profile/$agentId');
  }

  void _handleEmailPress(String? email) async {
    if (email == null || email.isEmpty) {
      _showAlert('Unavailable', 'Host email not available.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(email),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied to clipboard')),
              );
            },
            child: const Text('Copy email'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse('mailto:$email');
              if (await canLaunchUrl(url)) {
                launchUrl(url);
              } else {
                if (mounted) {
                  _showAlert('Error', 'Unable to launch email app.');
                }
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

  void _handlePhonePress(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showAlert('Unavailable', 'Host phone number not available.');
      return;
    }

    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) {
      _showAlert('Invalid', 'Phone number format is invalid.');
      return;
    }

    final url = Uri.parse('tel:$sanitized');
    if (await canLaunchUrl(url)) {
      launchUrl(url);
    } else {
      if (mounted) {
        _showAlert('Unsupported', 'Phone calls are not supported on this device.');
      }
    }
  }

  void _handleCancelBooking(BookingDocument booking) async {
    if (booking.paymentStatus == PaymentStatus.paid) {
      _showAlert('Contact host',
          'This booking is already paid and confirmed. Please reach out to the host to request any changes.');
      return;
    }

    final checkIn = booking.checkInDate;
    final now = DateTime.now();
    final daysUntil = checkIn.difference(now).inDays;

    String message = 'Are you sure you want to cancel this booking?\n\n';
    if (daysUntil >= 7) {
      message += 'You will receive a full refund (excluding service fee).';
    } else if (daysUntil >= 3) {
      message += 'You will receive a 50% refund.';
    } else {
      message += 'No refund will be issued as per the cancellation policy.';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showAlert('Error', 'Failed to cancel booking');
        }
      }
    }
  }

  void _openPaymentSheet(BookingDocument booking) {
    setState(() => _bookingToPay = booking);

    PaymentMethodSheet.show(
      context: context,
      amount: booking.totalPrice,
      subtitle:
          '${DateFormat('MMM d').format(booking.checkInDate)} → ${DateFormat('MMM d').format(booking.checkOutDate)}',
      onConfirm: ({required method, card}) => _handlePaymentConfirm(method, card),
    );
  }

  Future<void> _handlePaymentConfirm(PaymentMethod method, CardDetails? card) async {
    if (_bookingToPay == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final status = method == PaymentMethod.card ? 'succeeded' : 'pending';
      final lastFour = card?.number.replaceAll(' ', '').substring(card.number.length - 4);

      await AppwriteService().createPaymentRecord(
        bookingId: _bookingToPay!.id,
        userId: currentUser.$id,
        agentId: _bookingToPay!.agentId as String,
        amount: _bookingToPay!.totalPrice,
        paymentMethod: method.toString().split('.').last,
        paymentGateway: method == PaymentMethod.card ? 'mock-card' : method.toString().split('.').last,
        transactionId: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        status: status,
        gatewayResponse: lastFour != null ? '{"last4": "$lastFour"}' : null,
      );

      final message = method == PaymentMethod.card
          ? 'Payment completed successfully'
          : 'We saved your payment preference. The host will share the remaining instructions.';

      if (mounted) {
        Navigator.pop(context); // Close payment sheet
        _showAlert('Success', message);
        ref.read(bookingsProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showAlert('Error', 'Payment failed');
      }
    } finally {
      setState(() {
        _bookingToPay = null;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(bookingsProvider);

    final filteredBookings = _filter == 'all'
        ? bookingsState.bookings
        : bookingsState.bookings.where((b) => b.status.value == _filter).toList();

    if (bookingsState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0061FF))),
      );
    }

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
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your rental reservations',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterButton(
                    label: 'all',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'pending',
                    selected: _filter == 'pending',
                    onTap: () => setState(() => _filter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'confirmed',
                    selected: _filter == 'confirmed',
                    onTap: () => setState(() => _filter = 'confirmed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'cancelled',
                    selected: _filter == 'cancelled',
                    onTap: () => setState(() => _filter = 'cancelled'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bookings list
            Expanded(
              child: filteredBookings.isEmpty
                  ? _EmptyState(filter: _filter)
                  : RefreshIndicator(
                      onRefresh: () async => ref.read(bookingsProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _BookingCard(
                            booking: filteredBookings[index],
                            onViewProfile: _handleViewAgentProfile,
                            onEmailPress: _handleEmailPress,
                            onPhonePress: _handlePhonePress,
                            onCancel: _handleCancelBooking,
                            onPayNow: _openPaymentSheet,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0061FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              filter == 'all' ? 'No bookings found' : 'No $filter bookings found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking requests will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0061FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Explore Properties',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingDocument booking;
  final void Function(String?) onViewProfile;
  final void Function(String?) onEmailPress;
  final void Function(String?) onPhonePress;
  final void Function(BookingDocument) onCancel;
  final void Function(BookingDocument) onPayNow;

  const _BookingCard({
    required this.booking,
    required this.onViewProfile,
    required this.onEmailPress,
    required this.onPhonePress,
    required this.onCancel,
    required this.onPayNow,
  });

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA500);
      case BookingStatus.confirmed:
        return const Color(0xFF10B981);
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return const Color(0xFFEF4444);
      case BookingStatus.completed:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getStatusBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFF3CD);
      case BookingStatus.confirmed:
        return const Color(0xFFD1FAE5);
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return const Color(0xFFFEE2E2);
      case BookingStatus.completed:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.unpaid:
        return const Color(0xFFFFA500);
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _getPaymentBgColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFFD1FAE5);
      case PaymentStatus.unpaid:
        return const Color(0xFFFFEDCC);
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return const Color(0xFFEDE9FE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property header with badges
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/properties/${booking.propertyId}'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0061FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🏠', style: TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR STAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0061FF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Listing ${booking.propertyId.substring(0, min(8, booking.propertyId.length))}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentBgColor(booking.paymentStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.paymentStatus.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPaymentColor(booking.paymentStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Agent contact section
          if (booking.agent != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => onViewProfile(booking.agent![ '\$id'] as String?),
                    child: Row(
                      children: [
                        // Agent avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFF0061FF).withValues(alpha: 0.1),
                          ),
                          child: booking.agent!['avatar'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    booking.agent!['avatar'] as String,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    (booking.agent!['name'] as String? ?? '?')[0].toUpperCase(),
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
                                'Host contact',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.agent!['name'] as String? ?? 'Host',
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
                          onTap: () => onEmailPress(booking.agent!['email'] as String?),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
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
                                        booking.agent!['email'] as String? ?? 'Not provided',
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
                          onTap: () => onPhonePress(booking.agent!['phone'] as String?),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
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
                                        booking.agent!['phone'] as String? ?? 'Not provided',
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
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(_formatDate(booking.checkInDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-out', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(_formatDate(booking.checkOutDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guests', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('${booking.numberOfGuests}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nights', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('${booking.numberOfNights}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('\$${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0061FF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(booking.status.value[0].toUpperCase() + booking.status.value.substring(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          
          // Rejection reason
          if (booking.status == BookingStatus.rejected && booking.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejection Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red[800])),
                  const SizedBox(height: 4),
                  Text(booking.rejectionReason!, style: TextStyle(fontSize: 14, color: Colors.red[700])),
                ],
              ),
            ),
          ],
          
          // Actions
          if (booking.status == BookingStatus.confirmed && booking.paymentStatus == PaymentStatus.unpaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onPayNow(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
          
          if ((booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) &&
              booking.paymentStatus != PaymentStatus.paid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onCancel(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
          
          if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061FF).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF0061FF),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Leave Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
          
          // Special requests
          if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Special Requests:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(booking.specialRequests!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;
