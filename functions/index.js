/**
 * Cloud Functions for MyFriends SOS Feature
 *
 * This file contains Firebase Cloud Functions that handle SOS emergency alerts:
 * 1. onSOSCreate - Triggered when a new SOS message is created
 * 2. onSOSUpdate - Triggered when an SOS message is updated (e.g., cancelled)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Triggered when a new SOS message is created
 *
 * This function:
 * 1. Gets the SOS message data
 * 2. Retrieves FCM tokens for all emergency contacts
 * 3. Sends push notifications to all emergency contacts
 * 4. Continues sending notifications until SOS is cancelled
 */
exports.onSOSCreate = functions.firestore
  .document('sos_messages/{sosId}')
  .onCreate(async (snapshot, context) => {
    const sosId = context.params.sosId;
    const sosData = snapshot.data();

    console.log('New SOS created:', sosId);
    console.log('SOS Data:', sosData);

    try {
      // Get emergency contact user IDs (exclude sender)
      let emergencyContactIds = sosData.emergencyContactIds || [];

      // Remove sender from recipients (don't send SOS notification to yourself)
      emergencyContactIds = emergencyContactIds.filter(id => id !== sosData.senderId);

      if (emergencyContactIds.length === 0) {
        console.log('No emergency contacts found (after excluding sender)');
        return null;
      }

      console.log(`Sending to ${emergencyContactIds.length} emergency contacts (excluding sender)`);
      console.log('Emergency Contact IDs:', emergencyContactIds);
      console.log('🚫 Sender ID (excluded):', sosData.senderId);

      // Get FCM tokens for all emergency contacts
      const tokens = await getEmergencyContactTokens(emergencyContactIds);

      if (tokens.length === 0) {
        console.log('No FCM tokens found for emergency contacts');
        return null;
      }

      console.log(`🔑 Found ${tokens.length} FCM tokens`);
      tokens.forEach((token, idx) => {
        console.log(`  Token ${idx + 1}: ${token.substring(0, 30)}...`);
      });

      // Prepare notification payload
      const notification = {
        title: `EMERGENCY SOS`,
        body: `${sosData.senderName} sent an emergency SOS! Tap to view location.`,
      };

      const data = {
        sosId: sosId,
        senderId: sosData.senderId,
        senderName: sosData.senderName,
        senderPhone: sosData.senderPhone,
        googleMapsUrl: sosData.googleMapsUrl,
        message: sosData.message,
        latitude: String(sosData.location.latitude),
        longitude: String(sosData.location.longitude),
        type: 'sos', // Changed from 'sos_alert' to match notification_service.dart detection
      };

      // Send notification to all emergency contacts
      const message = {
        notification: notification,
        data: data,
        tokens: tokens,
        android: {
          priority: 'high',
          notification: {
            channelId: 'sos_channel',
            priority: 'max',
            sound: 'default',
            visibility: 'public',
            tag: sosId,
            color: '#FF0000',
            defaultVibrateTimings: false,
            vibrateTimingsMillis: [0, 1000, 500, 1000, 500, 1000],
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              sound: 'default',
              badge: 1,
              'interruption-level': 'critical',
            },
          },
        },
      };

      const response = await messaging.sendEachForMulticast(message);

      console.log(`Successfully sent ${response.successCount} notifications`);
      if (response.failureCount > 0) {
        console.log(`Failed to send ${response.failureCount} notifications`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`Error for token ${tokens[idx]}:`, resp.error);
          }
        });
      }

      return null;
    } catch (error) {
      console.error('Error in onSOSCreate:', error);
      return null;
    }
  });

/**
 * Triggered when an SOS message is updated
 *
 * This function handles SOS cancellation:
 * 1. Checks if status changed to 'cancelled'
 * 2. Sends cancellation notification to emergency contacts
 * 3. Removes the ongoing notification
 */
exports.onSOSUpdate = functions.firestore
  .document('sos_messages/{sosId}')
  .onUpdate(async (change, context) => {
    const sosId = context.params.sosId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if SOS was cancelled or resolved
    const wasCancelled = beforeData.status === 'active' && afterData.status === 'cancelled';
    const wasResolved = beforeData.status === 'active' && afterData.status === 'resolved';

    if (wasCancelled) {
      console.log('SOS cancelled:', sosId);

      try {
        // Get emergency contact user IDs (exclude sender)
        let emergencyContactIds = afterData.emergencyContactIds || [];

        // Remove sender from recipients
        emergencyContactIds = emergencyContactIds.filter(id => id !== afterData.senderId);

        if (emergencyContactIds.length === 0) {
          console.log('No emergency contacts found (after excluding sender)');
          return null;
        }

        console.log(`Sending cancellation to ${emergencyContactIds.length} emergency contacts (excluding sender)`);

        // Get FCM tokens
        const tokens = await getEmergencyContactTokens(emergencyContactIds);

        if (tokens.length === 0) {
          console.log('No FCM tokens found');
          return null;
        }

        // Send cancellation notification
        const notification = {
          title: `SOS Cancelled - ${afterData.senderName}`,
          body: `${afterData.senderName} has cancelled the emergency SOS.`,
        };

        const data = {
          sosId: sosId,
          senderId: afterData.senderId,
          senderName: afterData.senderName,
          type: 'sos_cancelled',
        };

        const message = {
          notification: notification,
          data: data,
          tokens: tokens,
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
              tag: sosId, // Same tag to replace the SOS notification
            },
          },
        };

        const response = await messaging.sendEachForMulticast(message);

        console.log(`Successfully sent ${response.successCount} cancellation notifications`);
        if (response.failureCount > 0) {
          console.log(`Failed to send ${response.failureCount} notifications`);
        }

        return null;
      } catch (error) {
        console.error('Error in onSOSUpdate (cancel):', error);
        return null;
      }
    }

    if (wasResolved) {
      console.log('SOS resolved:', sosId);
      console.log('Full SOS Data:', afterData);

      try {
        // Send "SOS Resolved" notification to SENDER ONLY
        const senderIds = [afterData.senderId];

        console.log('Sending resolution notification to sender:', afterData.senderId);
        console.log('Sender email/name:', afterData.senderName);

        // Get FCM token for sender
        const tokens = await getEmergencyContactTokens(senderIds);

        if (tokens.length === 0) {
          console.log('No FCM tokens found');
          return null;
        }

        // Send resolved notification
        const notification = {
          title: `SOS Resolved - ${afterData.senderName}`,
          body: `${afterData.senderName}'s emergency has been resolved.`,
        };

        const data = {
          sosId: sosId,
          senderId: afterData.senderId,
          senderName: afterData.senderName,
          type: 'sos_resolved',
        };

        const message = {
          notification: notification,
          data: data,
          tokens: tokens,
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
              tag: sosId, // Same tag to replace the SOS notification
            },
          },
        };

        const response = await messaging.sendEachForMulticast(message);

        console.log(`Successfully sent ${response.successCount} resolved notifications`);
        if (response.failureCount > 0) {
          console.log(`Failed to send ${response.failureCount} notifications`);
        }

        return null;
      } catch (error) {
        console.error('Error in onSOSUpdate (resolve):', error);
        return null;
      }
    }

    return null;
  });

/**
 * Helper function to get FCM tokens for emergency contacts
 *
 * @param {Array<string>} userIds - Array of user IDs
 * @returns {Promise<Array<string>>} Array of FCM tokens
 */
async function getEmergencyContactTokens(userIds) {
  try {
    const tokens = [];

    // Get user documents for all emergency contacts
    const userPromises = userIds.map(userId =>
      db.collection('users').doc(userId).get()
    );

    const userDocs = await Promise.all(userPromises);

    userDocs.forEach(doc => {
      if (doc.exists) {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
          console.log(`Found token for user: ${doc.id} (${userData.email || 'no email'})`);
          console.log(`   Token: ${userData.fcmToken.substring(0, 30)}...`);
        } else {
          console.log(`No FCM token for user: ${doc.id} (${userData.email || 'no email'})`);
        }
      } else {
        console.log(`User not found: ${doc.id}`);
      }
    });

    return tokens;
  } catch (error) {
    console.error('Error getting FCM tokens:', error);
    return [];
  }
}
