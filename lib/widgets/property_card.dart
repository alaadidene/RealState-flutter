import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_models.dart';
import '../providers/favorites_provider.dart';
import '../core/theme/app_theme.dart';

class PropertyCard extends ConsumerWidget {
  final PropertyDocument property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.isFavorite(property.id);

    return GestureDetector(
      onTap: () {
        context.push('/property/${property.id}');
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: property.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.grey100,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.grey100,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),

                // Category Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: property.category == 'rent'
                          ? AppTheme.primary
                          : AppTheme.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      property.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(property.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_outline,
                        color: isFavorite ? Colors.red : AppTheme.grey400,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Property Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Name
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Property Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.grey400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Property Details
                    Row(
                      children: [
                        _buildFeature(Icons.bed_outlined, '${property.bedrooms}'),
                        const SizedBox(width: 12),
                        _buildFeature(Icons.bathtub_outlined, '${property.bathrooms}'),
                        const SizedBox(width: 12),
                        _buildFeature(Icons.square_foot_outlined, '${property.area}'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      '\$${property.price.toStringAsFixed(0)}${property.category == 'rent' ? '/mo' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey400),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.grey500,
          ),
        ),
      ],
    );
  }
}
