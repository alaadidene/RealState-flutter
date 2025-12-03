# Fix Payments Collection Schema

## Problem
The payments collection is missing the `userId` and `agentId` attributes, causing errors:
```
AppwriteException: Invalid document structure: Unknown attribute: "userId"
```

## Current Status
✅ **Both apps have fallback mechanisms** to handle missing attributes
- React Native: Working (errors shown but payments succeed)
- Flutter: Fixed with same fallback logic

## Permanent Fix (Optional)

To eliminate the errors completely, add these attributes to the Appwrite payments collection:

### Steps in Appwrite Console:

1. **Go to**: https://cloud.appwrite.io/console/project/69146dd000167aa04353/databases/database/69173df30017df60e6e3/collection/payments/attributes

2. **Add `userId` attribute:**
   - Click "+ Create Attribute"
   - Type: **String**
   - Attribute ID: `userId`
   - Size: `255`
   - Required: **No** (optional to support existing records)
   - Default: Leave empty
   - Array: **No**
   - Click "Create"

3. **Add `agentId` attribute:**
   - Click "+ Create Attribute"
   - Type: **String**
   - Attribute ID: `agentId`
   - Size: `255`
   - Required: **No** (optional to support existing records)
   - Default: Leave empty
   - Array: **No**
   - Click "Create"

4. **Create indexes (optional, for better queries):**
   - Click "Indexes" tab
   - Add index:
     - Key: `userId`
     - Type: **Key**
     - Attribute: `userId`
   - Add another index:
     - Key: `agentId`
     - Type: **Key**
     - Attribute: `agentId`

## What Happens Without This Fix?

**Both apps will continue to work** because:
- Fallback mechanism removes problematic attributes
- Payments are still created (just without userId/agentId stored)
- Booking status still updates to 'paid'
- Users can complete transactions

**However:**
- Console errors will appear (harmless)
- Can't query payments by userId or agentId
- Harder to track payment history per user/agent

## Verification

After adding the attributes, test by:
1. Making a booking
2. Completing payment
3. Check console - errors should be gone
4. Check Appwrite - payment record should have userId and agentId populated

## Alternative: Update Environment Config

If using a different collection ID for payments with the correct schema, update:

**Flutter**: `lib/core/config/env_config.dart`
```dart
static const String paymentsCollectionId = 'your-correct-collection-id';
```

**React Native**: `.env`
```
EXPO_PUBLIC_APPWRITE_PAYMENTS_COLLECTION_ID=your-correct-collection-id
```
