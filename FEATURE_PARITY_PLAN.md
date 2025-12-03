# Flutter App - Feature Parity Implementation Plan

## Current Status: ~40% Feature Parity

The Flutter app is missing approximately **60% of advanced features** from React Native.

---

## 🔴 CRITICAL MISSING FEATURES (Must Implement)

### 1. ✅ Explore Screen - Advanced Filters **[COMPLETED]**
- [x] Booking relationship hydration (agent, guest, property)
- [x] Agent contact cards in bookings
- [x] Guest contact cards in booking requests  
- [x] Payment system with fallback

### 2. ❌ Explore Screen - Advanced Filters Sidebar
**Priority:** CRITICAL  
**Files to Create:**
- `lib/widgets/advanced_filters_sheet.dart`
- `lib/providers/filters_provider.dart`

**Features Needed:**
- Price range slider (min/max inputs)
- Bedroom filter (dropdown or chips)
- Bathroom filter (dropdown or chips)
- Facilities multi-select (Swimming Pool, Gym, Parking, etc.)
- Sort options dropdown (newest, price_high, price_low, rating)
- Reset all filters button
- Apply filters button
- Bottom sheet or side drawer UI
- URL parameter management

**Implementation:**
```dart
class AdvancedFiltersSheet extends StatefulWidget {
  final FilterState initial;
  final void Function(FilterState) onApply;
  
  // Price range
  RangeSlider priceRange;
  
  // Bedrooms/Bathrooms
  DropdownButton<int> bedroomsDropdown;
  DropdownButton<int> bathroomsDropdown;
  
  // Facilities
  Wrap facilities; // Checkboxes
  
  // Sort
  DropdownButton<SortOption> sortDropdown;
}
```

---

### 3. ❌ Property Details - Image Carousel
**Priority:** CRITICAL  
**Files to Modify:**
- `lib/screens/property/property_details_screen.dart`

**Current:** Single image in SliverAppBar  
**Needed:** 
- PageView with horizontal scrolling
- Dot indicators (current page / total pages)
- Support for `images` array from property
- Full-width images
- Swipe gesture

**Implementation:**
```dart
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) => CachedNetworkImage(url: images[index]),
        ),
        // Dot indicators
        Positioned(
          bottom: 16,
          child: Row(
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(/* dot */),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

### 4. ❌ Property Details - Agent Contact Card
**Priority:** CRITICAL  
**Files to Modify:**
- `lib/screens/property/property_details_screen.dart`

**Current:** "Contact Agent" button (placeholder)  
**Needed:**
- Agent avatar (with fallback to initials)
- Agent name
- Agent phone number
- Call button (launches phone dialer via `url_launcher`)
- Chat button (navigates to chat screen or creates conversation)
- Owner detection (hide contact if current user is owner)

**Implementation:**
```dart
class AgentCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final bool isOwner;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(/* card style */),
      child: Row(
        children: [
          CircleAvatar(/* agent avatar */),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent['name'], style: /* bold */),
                Text(agent['phone'], style: /* gray */),
              ],
            ),
          ),
          if (!isOwner) ...[
            IconButton(
              icon: Icon(Icons.phone),
              onPressed: () => _launchPhone(agent['phone']),
            ),
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () => _startChat(agent['\$id']),
            ),
          ],
        ],
      ),
    );
  }
  
  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  void _startChat(String agentId) {
    // Navigate to chat or create conversation
    context.push('/chat/$agentId');
  }
}
```

---

### 5. ❌ Property Details - Review System
**Priority:** CRITICAL  
**Files to Create:**
- `lib/widgets/property_reviews_list.dart`
- `lib/widgets/review_card.dart`
- `lib/widgets/write_review_sheet.dart`

**Needed:**
- Average rating display (stars + number)
- Review count (e.g., "(12 reviews)")
- Reviews list (shows first 3-5)
- Expand to see all reviews
- "Write Review" button (opens bottom sheet)
- Review submission to Appwrite
- Star rating input
- Comment textarea

**Implementation:**
```dart
class PropertyReviewsList extends StatelessWidget {
  final String propertyId;
  final double averageRating;
  final int reviewCount;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rating Summary
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('$averageRating (${reviewCount} reviews)'),
          ],
        ),
        SizedBox(height: 16),
        
        // Reviews List
        Consumer(
          builder: (context, ref, child) {
            final reviews = ref.watch(propertyReviewsProvider(propertyId));
            return reviews.when(
              data: (data) => ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: min(3, data.length),
                itemBuilder: (context, index) => ReviewCard(review: data[index]),
              ),
              loading: () => CircularProgressIndicator(),
              error: (e, s) => Text('Error loading reviews'),
            );
          },
        ),
        
        // Write Review Button
        ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (context) => WriteReviewSheet(propertyId: propertyId),
          ),
          child: Text('Write Review'),
        ),
      ],
    );
  }
}
```

---

### 6. ❌ Property Details - Booking Calendar
**Priority:** CRITICAL  
**Files to Create:**
- `lib/widgets/booking_calendar_widget.dart`

**Needed:**
- Date range picker
- Shows unavailable dates (from existing bookings)
- Price calculation:
  - Number of nights
  - Subtotal (price × nights)
  - Service fee (10% of subtotal)
  - Total price
- Guest count selector
- "Book Now" button
- Special requests textarea
- Booking creation via Appwrite

**Implementation:**
```dart
class BookingCalendarWidget extends StatefulWidget {
  final PropertyDocument property;
  final List<BookingDocument> existingBookings;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Range Picker
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => /* check if selected */,
          enabledDayPredicate: (day) => !_isDateUnavailable(day),
          onDaySelected: (selected, focused) => _handleDateSelect(selected),
        ),
        
        SizedBox(height: 16),
        
        // Guest Count
        Row(
          children: [
            Text('Guests:'),
            IconButton(icon: Icon(Icons.remove), onPressed: _decrementGuests),
            Text('$_guestCount'),
            IconButton(icon: Icon(Icons.add), onPressed: _incrementGuests),
          ],
        ),
        
        // Price Breakdown
        if (_checkInDate != null && _checkOutDate != null) ...[
          _PriceBreakdown(
            pricePerNight: property.price,
            nights: _nights,
            subtotal: _subtotal,
            serviceFee: _serviceFee,
            total: _total,
          ),
        ],
        
        // Book Now Button
        ElevatedButton(
          onPressed: _canBook ? _handleBookNow : null,
          child: Text('Book Now'),
        ),
      ],
    );
  }
  
  bool _isDateUnavailable(DateTime date) {
    // Check if date falls within any existing booking
    return existingBookings.any((booking) =>
      date.isAfter(booking.checkInDate.subtract(Duration(days: 1))) &&
      date.isBefore(booking.checkOutDate.add(Duration(days: 1))));
  }
}
```

---

### 7. ❌ Property Details - Owner Actions
**Priority:** HIGH  
**Files to Modify:**
- `lib/screens/property/property_details_screen.dart`

**Needed:**
- Detect if current user is property owner
- Show "Edit" button (if owner)
- Show "Delete" button (if owner)
- Edit navigates to create/edit property screen with pre-filled data
- Delete shows confirmation dialog
- Delete calls Appwrite deleteProperty

**Implementation:**
```dart
// In PropertyDetailsScreen
Widget _buildOwnerActions() {
  final currentUser = ref.watch(currentUserProvider);
  final isOwner = property.agentId == currentUser?.$id;
  
  if (!isOwner) return SizedBox.shrink();
  
  return Row(
    children: [
      ElevatedButton.icon(
        icon: Icon(Icons.edit),
        label: Text('Edit'),
        onPressed: () => context.push('/create-property/${property.id}'),
      ),
      SizedBox(width: 12),
      ElevatedButton.icon(
        icon: Icon(Icons.delete),
        label: Text('Delete'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: _confirmDelete,
      ),
    ],
  );
}

void _confirmDelete() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Property'),
      content: Text('Are you sure? This cannot be undone.'),
      actions: [
        TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
        TextButton(
          child: Text('Delete', style: TextStyle(color: Colors.red)),
          onPressed: () async {
            await ref.read(appwriteServiceProvider).deleteProperty(property.id);
            Navigator.pop(context); // Close dialog
            context.pop(); // Go back
          },
        ),
      ],
    ),
  );
}
```

---

### 8. ❌ Property Details - Map Integration
**Priority:** HIGH  
**Files to Modify:**
- `lib/screens/property/property_details_screen.dart`
- Add `google_maps_flutter` dependency

**Needed:**
- Google Map showing property location
- Map marker at property coordinates
- "Get Directions" button
- Opens Google Maps/Apple Maps with directions
- Parse geolocation JSON from property

**Implementation:**
```dart
class PropertyLocationMap extends StatelessWidget {
  final PropertyDocument property;
  
  @override
  Widget build(BuildContext context) {
    final geolocation = _parseGeolocation(property.geolocation);
    final latLng = LatLng(geolocation['lat'], geolocation['lng']);
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
            markers: {
              Marker(
                markerId: MarkerId(property.id),
                position: latLng,
              ),
            },
          ),
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.directions),
          label: Text('Get Directions'),
          onPressed: () => _openDirections(latLng),
        ),
      ],
    );
  }
  
  Map<String, double> _parseGeolocation(String geolocationJson) {
    final data = json.decode(geolocationJson);
    return {'lat': data['lat'], 'lng': data['lng']};
  }
  
  void _openDirections(LatLng destination) async {
    final url = Platform.isIOS
        ? 'maps:?daddr=${destination.latitude},${destination.longitude}'
        : 'geo:${destination.latitude},${destination.longitude}';
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
```

---

## 🟠 HIGH PRIORITY FEATURES

### 9. ❌ Home Screen - Featured Properties Carousel
**Priority:** HIGH  
**Files to Modify:**
- `lib/screens/home/home_screen.dart`

**Needed:**
- Horizontal PageView for featured properties
- Larger card design (FeaturedCard)
- "See All" link
- Separate API call to get latest/featured properties
- Auto-scroll animation

---

### 10. ❌ Messages - Search & Agent Suggestions
**Priority:** HIGH  
**Files to Modify:**
- `lib/screens/messages/messages_list_screen.dart`

**Needed:**
- Search TextField at top
- Real-time agent suggestions dropdown
- Search by agent name, email, phone, agency
- Show top 5 matching agents
- Click to start new conversation

---

### 11. ❌ Profile - Additional Features
**Priority:** MEDIUM  
**Files to Modify:**
- `lib/screens/profile/profile_screen.dart`

**Needed:**
- Language selector dialog (English/Français)
- Help Center popup (email, phone, website, hours)
- Invite friends (share functionality)
- Seed data button (dev only)
- User avatar image upload
- Logout confirmation dialog

---

## 📊 Implementation Sequence

### Week 1: Property Details (Most Critical)
1. Image carousel
2. Agent card
3. Review system
4. Booking calendar
5. Owner actions
6. Map integration

### Week 2: Search & Discovery
1. Advanced filters sidebar
2. Featured carousel on home
3. Map toggle in explore
4. Property count display

### Week 3: Messaging & Profile
1. Messages search
2. Agent suggestions
3. Online indicators
4. Profile enhancements

---

## Dependencies to Add

```yaml
dependencies:
  # Maps
  google_maps_flutter: ^2.5.0
  
  # Calendar
  table_calendar: ^3.0.9
  
  # URL Launcher (for phone/maps)
  url_launcher: ^6.2.2
  
  # Image Carousel
  carousel_slider: ^4.2.1
  
  # Already have:
  # - cached_network_image
  # - flutter_riverpod
  # - go_router
  # - image_picker
```

---

## Testing Checklist

After each implementation:
- [ ] Feature works in Flutter
- [ ] Matches React Native UI exactly
- [ ] Handles edge cases (no data, errors)
- [ ] Works on both iOS and Android
- [ ] Performance is acceptable
- [ ] Appwrite integration works

---

## Current Progress

- ✅ Bookings system (100%)
- ✅ Payment system (100%)
- ❌ Property details (40%)
- ❌ Explore/filters (30%)
- ❌ Home screen (60%)
- ❌ Messages (50%)
- ❌ Profile (70%)

**Overall:** ~40% complete
