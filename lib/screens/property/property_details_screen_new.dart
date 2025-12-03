import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/property_models.dart';
import '../../models/booking_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/properties_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/appwrite_service.dart';
import '../../../components/payment_method_sheet.dart';

class PropertyDetailsScreenNew extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailsScreenNew({
    super.key,
    required this.propertyId,
  });

  @override
  ConsumerState<PropertyDetailsScreenNew> createState() => _PropertyDetailsScreenNewState();
}

class _PropertyDetailsScreenNewState extends ConsumerState<PropertyDetailsScreenNew> {
  int _currentImageIndex = 0;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  String? _specialRequests;

  @override
  void initState() {
    super.initState();
    _loadUnavailableDates();
  }

  Future<void> _loadUnavailableDates() async {
    try {
      // Load existing bookings for this property
      // TODO: Implement getPropertyBookings method
      // For now, leave empty
    } catch (e) {
      print('Error loading unavailable dates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyByIdProvider(widget.propertyId));
    final currentUser = ref.watch(currentUserProvider);
    final favoritesState = ref.watch(favoritesProvider);

    return propertyAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
      data: (property) {
        if (property == null) {
          return const Scaffold(
            body: Center(child: Text('Property not found')),
          );
        }

        final isOwner = currentUser?.$id == property.agentId;
        final isFavorite = favoritesState.isFavorite(property.id);
        final images = _getPropertyImages(property);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(
                child: _buildImageCarousel(images, isFavorite, property),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Title & Price
                      Text(
                        property.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${property.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0061FF),
                            ),
                          ),
                          Text(
                            property.type == 'rent' ? '/month' : '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF0061FF), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              property.address,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Features Row
                      Row(
                        children: [
                          _buildFeatureChip(Icons.bed, '${property.bedrooms} Beds'),
                          const SizedBox(width: 12),
                          _buildFeatureChip(Icons.bathroom, '${property.bathrooms} Baths'),
                          const SizedBox(width: 12),
                          _buildFeatureChip(Icons.square_foot, '${property.area} sqft'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Owner Actions
                      if (isOwner) ...[
                        _buildOwnerActions(property),
                        const SizedBox(height: 24),
                      ],

                      // Agent Card (if not owner)
                      if (!isOwner) ...[
                        _buildAgentCard(property),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      if (property.description.isNotEmpty) ...[
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          property.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Facilities
                      if (property.facilities.isNotEmpty) ...[
                        const Text(
                          'Facilities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFacilitiesGrid(property.facilities),
                        const SizedBox(height: 24),
                      ],

                      // Reviews Section
                      _buildReviewsSection(property),
                      const SizedBox(height: 24),

                      // Map
                      _buildLocationMap(property),
                      const SizedBox(height: 24),

                      // Booking Calendar (if not owner)
                      if (!isOwner) ...[
                        _buildBookingCalendar(property),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: !isOwner && _checkInDate != null && _checkOutDate != null
              ? FloatingActionButton.extended(
                  onPressed: () => _handleBookNow(property, currentUser),
                  backgroundColor: const Color(0xFF0061FF),
                  label: Text(
                    'Book Now - \$${_calculateTotal(property.price)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.calendar_today),
                )
              : null,
        );
      },
    );
  }

  List<String> _getPropertyImages(PropertyDocument property) {
    // Get all images from array
    final images = <String>[];
    
    // Try gallery array first
    if (property.gallery.isNotEmpty) {
      images.addAll(property.gallery.where((img) => img.isNotEmpty));
    }
    
    // Fallback to single image field
    if (images.isEmpty && property.image.isNotEmpty) {
      images.add(property.image);
    }
    
    return images;
  }

  Widget _buildImageCarousel(List<String> images, bool isFavorite, PropertyDocument property) {
    return Stack(
      children: [
        // Image PageView
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 48),
                ),
              );
            },
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),

        // Top Bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(favoritesProvider.notifier).toggleFavorite(widget.propertyId);
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_outline,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Share.share(
                        'Check out this property: ${property.name}\n'
                        'Price: \$${property.price}\n'
                        'Location: ${property.address}\n'
                        '${property.bedrooms} beds, ${property.bathrooms} baths\n',
                        subject: property.name,
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Page Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentImageIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == _currentImageIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0061FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0061FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0061FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(PropertyDocument property) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to edit property
              context.push('/create-property/${property.id}');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0061FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelete(property),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(PropertyDocument property) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AppwriteService().deleteProperty(property.id);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Property deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting property: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(PropertyDocument property) {
    return FutureBuilder<AgentDocument?>(
      future: AppwriteService().getAgentById(property.agentId),
      builder: (context, snapshot) {
        final agent = snapshot.data;
        final agentName = agent?.name ?? 'Property Agent';
        final agentPhone = agent?.phone ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF0061FF).withValues(alpha: 0.1),
                backgroundImage: agent?.avatar != null && agent!.avatar.isNotEmpty
                    ? NetworkImage(agent.avatar)
                    : null,
                child: agent?.avatar == null || agent!.avatar.isEmpty
                    ? Text(
                        agentName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0061FF),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Property Agent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (agentPhone.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    final url = Uri.parse('tel:$agentPhone');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: const Icon(Icons.phone, color: Color(0xFF0061FF)),
                ),
              IconButton(
                onPressed: () {
                  // Navigate to messages/chat
                  context.push('/messages');
                },
                icon: const Icon(Icons.chat, color: Color(0xFF0061FF)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesGrid(List<String> facilities) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: facilities.map((facility) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0061FF).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0061FF).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 18, color: Color(0xFF0061FF)),
              const SizedBox(width: 8),
              Text(
                facility,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsSection(PropertyDocument property) {
    return FutureBuilder<List<ReviewDocument>>(
      future: AppwriteService().getPropertyReviews(property.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${property.rating.toStringAsFixed(1)} (${reviews.length} reviews)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Write Review Button
            OutlinedButton.icon(
              onPressed: () {
                _showWriteReviewSheet(property);
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0061FF),
                side: const BorderSide(color: Color(0xFF0061FF)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reviews List
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...reviews.take(3).map((review) => _buildReviewCard(review)),
            
            if (reviews.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Show all reviews page
                },
                child: Text('View all ${reviews.length} reviews'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(ReviewDocument review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0061FF).withValues(alpha: 0.1),
                backgroundImage: review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null || review.userAvatar!.isEmpty
                    ? Text(
                        (review.userName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0061FF),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatReviewDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Like button and date footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color: const Color(0xFF0061FF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '120',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                DateTime.now().difference(review.createdAt).inDays == 0
                    ? 'Today'
                    : _formatReviewDate(review.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  void _showWriteReviewSheet(PropertyDocument property) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewSheet(propertyId: property.id),
    );
  }

  Widget _buildLocationMap(PropertyDocument property) {
    // TODO: Implement Google Maps
    // For now, show placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Map will appear here'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            // TODO: Open directions
            final lat = property.latitude;
            final lng = property.longitude;
            final url = 'geo:$lat,$lng';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          icon: const Icon(Icons.directions),
          label: const Text('Get Directions'),
        ),
      ],
    );
  }

  Widget _buildBookingCalendar(PropertyDocument property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Book this Property',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Date Selection
        Row(
          children: [
            Expanded(
              child: _buildDateBox(
                'Check-in',
                _checkInDate,
                () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateBox(
                'Check-out',
                _checkOutDate,
                () => _selectDate(false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Guest Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Guests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _guestCount > 1
                      ? () => setState(() => _guestCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_guestCount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => setState(() => _guestCount++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price Breakdown
        if (_checkInDate != null && _checkOutDate != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPriceRow('${_calculateNights()} nights × \$${property.price}', _calculateSubtotal(property.price)),
                const SizedBox(height: 8),
                _buildPriceRow('Service fee (10%)', _calculateServiceFee(property.price)),
                const Divider(height: 24),
                _buildPriceRow('Total', _calculateTotal(property.price), isTotal: true),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Special Requests
        TextField(
          decoration: const InputDecoration(
            labelText: 'Special Requests (Optional)',
            border: OutlineInputBorder(),
            hintText: 'Any special requests?',
          ),
          maxLines: 3,
          onChanged: (value) => _specialRequests = value,
        ),
      ],
    );
  }

  Widget _buildDateBox(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
            _checkOutDate = null;
          }
        } else {
          if (_checkInDate == null || picked.isAfter(_checkInDate!)) {
            _checkOutDate = picked;
          }
        }
      });
    }
  }

  int _calculateNights() {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double _calculateSubtotal(int pricePerNight) {
    return pricePerNight.toDouble() * _calculateNights();
  }

  double _calculateServiceFee(int pricePerNight) {
    return _calculateSubtotal(pricePerNight) * 0.1;
  }

  double _calculateTotal(int pricePerNight) {
    return _calculateSubtotal(pricePerNight) + _calculateServiceFee(pricePerNight);
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF0061FF) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _handleBookNow(PropertyDocument property, dynamic currentUser) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book')),
      );
      context.push('/sign-in');
      return;
    }

    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select check-in and check-out dates')),
      );
      return;
    }

    // Show payment sheet
    await PaymentMethodSheet.show(
      context: context,
      amount: _calculateTotal(property.price),
      onConfirm: ({required method, card}) async {
        // Process booking
        try {
          final booking = BookingDocument(
            id: '',
            propertyId: property.id,
            guestId: currentUser.$id as String,
            agentId: property.agentId,
            checkInDate: _checkInDate!,
            checkOutDate: _checkOutDate!,
            numberOfGuests: _guestCount,
            numberOfNights: _calculateNights(),
            pricePerNight: property.price.toDouble(),
            subtotal: _calculateSubtotal(property.price),
            serviceFee: _calculateServiceFee(property.price),
            totalPrice: _calculateTotal(property.price),
            status: BookingStatus.pending,
            paymentStatus: PaymentStatus.unpaid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            specialRequests: _specialRequests,
          );

          final created = await AppwriteService().createBooking(booking: booking);

          if (created != null && method == PaymentMethod.card) {
            // Create payment record
            await AppwriteService().createPaymentRecord(
              bookingId: created.id,
              userId: currentUser.$id as String,
              agentId: property.agentId,
              amount: _calculateTotal(property.price),
              paymentMethod: 'card',
              paymentGateway: 'mock-card',
              transactionId: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
              status: 'succeeded',
            );
          }

          if (mounted) {
            Navigator.pop(context); // Close payment sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking created successfully!')),
            );
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating booking: $e')),
            );
          }
        }
      },
    );
  }
}

// Write Review Sheet Widget
class _WriteReviewSheet extends StatefulWidget {
  final String propertyId;

  const _WriteReviewSheet({required this.propertyId});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement submitReview method in AppwriteService
      // await AppwriteService().submitReview(
      //   propertyId: widget.propertyId,
      //   rating: _rating,
      //   comment: _commentController.text.trim(),
      // );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() => _rating = (index + 1).toDouble());
                        },
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  Text(
                    '${_rating.toStringAsFixed(1)} stars',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comment
                  const Text(
                    'Your Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience with this property...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0061FF),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
