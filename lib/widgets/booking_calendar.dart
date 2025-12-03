import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingCalendar extends StatefulWidget {
  final String propertyId;
  final double pricePerNight;
  final void Function(String checkIn, String checkOut, int nights, double total) onDatesSelected;

  const BookingCalendar({
    required this.propertyId,
    required this.pricePerNight,
    required this.onDatesSelected,
    super.key,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  DateTime _focusedDay = DateTime.now();
  // TODO: Implement unavailable dates fetching from Appwrite
  // final Set<DateTime> _unavailableDates = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch unavailable dates from Appwrite
  }

  void _clearDates() {
    setState(() {
      _checkInDate = null;
      _checkOutDate = null;
    });
    widget.onDatesSelected('', '', 0, 0);
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    // Check if date is in the past
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (selectedDay.isBefore(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date')),
      );
      return;
    }

    setState(() {
      _focusedDay = focusedDay;
    });

    if (_checkInDate == null) {
      // First selection - check-in
      setState(() {
        _checkInDate = selectedDay;
        _checkOutDate = null;
      });
    } else if (_checkOutDate == null) {
      // Second selection - check-out
      if (selectedDay.isBefore(_checkInDate!) || selectedDay.isAtSameMomentAs(_checkInDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-out must be after check-in')),
        );
        return;
      }

      // Check availability
      setState(() => _loading = true);
      
      try {
        // TODO: Call Appwrite to check availability
        // final isAvailable = await _appwrite.checkAvailability(
        //   widget.propertyId,
        //   _checkInDate!.toIso8601String().split('T')[0],
        //   selectedDay.toIso8601String().split('T')[0],
        // );

        // For now, assume available
        // TODO: Implement availability checking
        /* Uncomment when ready:
        final isAvailable = _checkAvailability(_checkInDate!, selectedDay);
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Some dates in this range are already booked'),
              ),
            );
            setState(() {
              _checkInDate = null;
              _checkOutDate = null;
            });
          }
          return;
        }
        */

        setState(() {
          _checkOutDate = selectedDay;
        });

        // Calculate costs
        final nights = selectedDay.difference(_checkInDate!).inDays;
        final subtotal = nights * widget.pricePerNight;
        final serviceFee = subtotal * 0.1;
        final total = subtotal + serviceFee;

        widget.onDatesSelected(
          _checkInDate!.toIso8601String().split('T')[0],
          selectedDay.toIso8601String().split('T')[0],
          nights,
          total,
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to check availability')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } else {
      // Third selection - reset
      setState(() {
        _checkInDate = selectedDay;
        _checkOutDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Dates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your check-in and check-out dates',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            TableCalendar<void>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 180)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                if (_checkInDate != null && isSameDay(day, _checkInDate)) {
                  return true;
                }
                if (_checkOutDate != null && isSameDay(day, _checkOutDate)) {
                  return true;
                }
                if (_checkInDate != null && _checkOutDate != null) {
                  return day.isAfter(_checkInDate!) && day.isBefore(_checkOutDate!);
                }
                return false;
              },
              onDaySelected: _onDaySelected,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF191d31),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF191d31).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: const Color(0xFF191d31).withValues(alpha: 0.1),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

            if (_checkInDate != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Check-in',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(_checkInDate!),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_checkOutDate != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-out',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(_checkOutDate!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    if (_checkOutDate != null) ...[
                      const Divider(height: 24),
                      _buildPriceRow(
                        '${_checkOutDate!.difference(_checkInDate!).inDays} nights × \$${widget.pricePerNight.toStringAsFixed(0)}',
                        '\$${(_checkOutDate!.difference(_checkInDate!).inDays * widget.pricePerNight).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Service fee (10%)',
                        '\$${(_checkOutDate!.difference(_checkInDate!).inDays * widget.pricePerNight * 0.1).toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _buildPriceRow(
                        'Total',
                        '\$${(_checkOutDate!.difference(_checkInDate!).inDays * widget.pricePerNight * 1.1).toStringAsFixed(2)}',
                        bold: true,
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _clearDates,
                      child: const Text(
                        'Clear Dates',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? const Color(0xFF0061FF) : null,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
