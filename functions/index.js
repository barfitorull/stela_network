/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Send immediate notification when mining stops (server-side)
exports.sendMiningStoppedNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

  const { uid } = context.auth;

  try {
    console.log('Sending mining stopped notification for user:', uid);

    // Get user data
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data();
    
    if (!userData.fcmToken) {
      console.log('No FCM token found for user:', uid);
      return { success: false, message: 'No FCM token available' };
    }

    const message = {
      token: userData.fcmToken,
      notification: {
        title: '**STC Mining Session Ended**',
        body: 'Your mining session has ended. Come back and start a new session!',
      },
      data: {
        type: 'MINING_SESSION_END',
        sessionId: uid,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'stela_network_channel',
          priority: 'max',
          sound: 'default',
          icon: 'ic_notification',
          color: '#4A90E2',
          visibility: 'public',
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
        },
        ttl: 60 * 60, // 1 hour
        collapseKey: 'mining_stopped',
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: 'Mining session ended ⛏️',
              body: 'Restart mining to continue earning!',
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
      },
    };

    const result = await admin.messaging().send(message);
    console.log('Mining stopped notification sent successfully:', result);
    
    return { success: true, message: 'Notification sent successfully' };
  } catch (error) {
    console.error('Error sending mining stopped notification:', error);
    return { success: false, error: error.message };
  }
});

// Send delayed notification (1 hour)
exports.sendDelayedNotification1Hour = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("Etc/UTC")
  .onRun(async (context) => {
    const NOTIFICATIONS_ENABLED = false; // Set to true to enable notifications
    
    if (!NOTIFICATIONS_ENABLED) {
      console.log('Firebase notifications disabled - skipping sendDelayedNotification1Hour');
      return null;
    }
    
    try {
      console.log('Sending 1-hour delayed notification');
      
      // Get all users who stopped mining in the last 2 hours
      const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
      const usersSnapshot = await db.collection('users')
        .where('lastMiningUpdate', '>', twoHoursAgo)
        .where('isMining', '==', false)
        .get();

      console.log(`Found ${usersSnapshot.size} users for 1-hour notification`);

      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        if (!userData.fcmToken) {
          console.log(`No FCM token for user ${doc.id}`);
          continue;
        }

        const message = {
          token: userData.fcmToken,
          notification: {
            title: '**Don\'t forget to mine STC!**',
            body: 'Your mining session ended. Come back and start a new session!',
          },
          data: {
            type: 'MINING_REMINDER_1H',
            userId: doc.id,
            timestamp: Date.now().toString(),
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'stela_network_channel',
              priority: 'max',
              sound: 'default',
              icon: 'ic_notification',
              color: '#4A90E2',
              visibility: 'public',
              defaultSound: true,
              defaultVibrateTimings: true,
              defaultLightSettings: true,
            },
            ttl: 60 * 60, // 1 hour
            collapseKey: 'mining_reminder_1h',
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: '**Don\'t forget to mine STC!**',
                  body: 'Your mining session ended. Come back and start a new session!',
                },
                sound: 'default',
                badge: 1,
                'content-available': 1,
              },
            },
            headers: {
              'apns-priority': '10',
              'apns-push-type': 'alert',
            },
          },
        };

        try {
          const result = await admin.messaging().send(message);
          console.log(`1-hour notification sent successfully to user ${doc.id}:`, result);
        } catch (error) {
          console.error(`Error sending 1-hour notification to user ${doc.id}:`, error);
        }
      }

      return null;
    } catch (error) {
      console.error('Error sending 1-hour delayed notification:', error);
      return null;
    }
  });

// Send delayed notification (2 hours)
exports.sendDelayedNotification2Hours = functions.pubsub
  .schedule("every 2 hours")
  .timeZone("Etc/UTC")
  .onRun(async (context) => {
    const NOTIFICATIONS_ENABLED = false; // Set to true to enable notifications
    
    if (!NOTIFICATIONS_ENABLED) {
      console.log('Firebase notifications disabled - skipping sendDelayedNotification2Hours');
      return null;
    }
    
    try {
      console.log('Sending 2-hour delayed notification');
      
      // Get all users who stopped mining in the last 4 hours
      const fourHoursAgo = new Date(Date.now() - 4 * 60 * 60 * 1000);
      const usersSnapshot = await db.collection('users')
        .where('lastMiningUpdate', '>', fourHoursAgo)
        .where('isMining', '==', false)
        .get();

      console.log(`Found ${usersSnapshot.size} users for 2-hour notification`);

      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        if (!userData.fcmToken) {
          console.log(`No FCM token for user ${doc.id}`);
          continue;
        }

        const message = {
          token: userData.fcmToken,
          notification: {
            title: '**Your mining session is waiting!**',
            body: 'Don\'t miss out on STC earnings. Start mining now!',
          },
          data: {
            type: 'MINING_REMINDER_2H',
            userId: doc.id,
            timestamp: Date.now().toString(),
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'stela_network_channel',
              priority: 'max',
              sound: 'default',
              icon: 'ic_notification',
              color: '#4A90E2',
              visibility: 'public',
              defaultSound: true,
              defaultVibrateTimings: true,
              defaultLightSettings: true,
            },
            ttl: 60 * 60, // 1 hour
            collapseKey: 'mining_reminder_2h',
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: '**Your mining session is waiting!**',
                  body: 'Don\'t miss out on STC earnings. Start mining now!',
                },
                sound: 'default',
                badge: 1,
                'content-available': 1,
              },
            },
            headers: {
              'apns-priority': '10',
              'apns-push-type': 'alert',
            },
          },
        };

        try {
          const result = await admin.messaging().send(message);
          console.log(`2-hour notification sent successfully to user ${doc.id}:`, result);
        } catch (error) {
          console.error(`Error sending 2-hour notification to user ${doc.id}:`, error);
        }
      }

      return null;
    } catch (error) {
      console.error('Error sending 2-hour delayed notification:', error);
      return null;
    }
  });

// Send delayed notification (3 hours)
exports.sendDelayedNotification3Hours = functions.pubsub
  .schedule("every 3 hours")
  .timeZone("Etc/UTC")
  .onRun(async (context) => {
    const NOTIFICATIONS_ENABLED = false; // Set to true to enable notifications
    
    if (!NOTIFICATIONS_ENABLED) {
      console.log('Firebase notifications disabled - skipping sendDelayedNotification3Hours');
      return null;
    }
    
    try {
      console.log('Sending 3-hour delayed notification');
      
      // Get all users who stopped mining in the last 6 hours
      const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000);
      const usersSnapshot = await db.collection('users')
        .where('lastMiningUpdate', '>', sixHoursAgo)
        .where('isMining', '==', false)
        .get();

      console.log(`Found ${usersSnapshot.size} users for 3-hour notification`);

      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        if (!userData.fcmToken) {
          console.log(`No FCM token for user ${doc.id}`);
          continue;
        }

        const message = {
          token: userData.fcmToken,
          notification: {
            title: '**Last reminder to mine STC!**',
            body: 'Your mining session ended 3 hours ago. Don\'t lose more STC!',
          },
          data: {
            type: 'MINING_REMINDER_3H',
            userId: doc.id,
            timestamp: Date.now().toString(),
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'stela_network_channel',
              priority: 'max',
              sound: 'default',
              icon: 'ic_notification',
              color: '#4A90E2',
              visibility: 'public',
              defaultSound: true,
              defaultVibrateTimings: true,
              defaultLightSettings: true,
            },
            ttl: 60 * 60, // 1 hour
            collapseKey: 'mining_reminder_3h',
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: '**Last reminder to mine STC!**',
                  body: 'Your mining session ended 3 hours ago. Don\'t lose more STC!',
                },
                sound: 'default',
                badge: 1,
                'content-available': 1,
              },
            },
            headers: {
              'apns-priority': '10',
              'apns-push-type': 'alert',
            },
          },
        };

        try {
          const result = await admin.messaging().send(message);
          console.log(`3-hour notification sent successfully to user ${doc.id}:`, result);
        } catch (error) {
          console.error(`Error sending 3-hour notification to user ${doc.id}:`, error);
        }
      }

      return null;
    } catch (error) {
      console.error('Error sending 3-hour delayed notification:', error);
      return null;
    }
  });

// Validate referral code
exports.validateReferralCode = functions.https.onCall(async (data, context) => {
  // No authentication required for referral code validation during registration
  const { referralCode } = data;
  
  if (!referralCode) {
    return { valid: false, message: 'Referral code is required' };
  }

  try {
    console.log('Validating referral code:', referralCode);
    
    // Check if referral code exists in users collection
    const querySnapshot = await db.collection('users')
      .where('referralCode', '==', referralCode.toUpperCase())
      .get();

    if (querySnapshot.empty) {
      return { valid: false, message: 'Invalid referral code' };
    }

    // Check if user is not trying to use their own referral code (only if authenticated)
    if (context.auth) {
      const userDoc = querySnapshot.docs[0];
      if (userDoc.id === context.auth.uid) {
        return { valid: false, message: 'Cannot use your own referral code' };
      }
    }

    return { valid: true, message: 'Referral code is valid' };
  } catch (error) {
    console.error('Error validating referral code:', error);
    return { valid: false, message: 'Error validating referral code' };
  }
});

// DEBUG: Check user data
exports.debugUserData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

  const { userId } = data;
  const targetUserId = userId || context.auth.uid;

  try {
    console.log('DEBUG: Checking user data for:', targetUserId);
    
    const userDoc = await db.collection('users').doc(targetUserId).get();
    
    if (!userDoc.exists) {
      return { 
        exists: false, 
        message: 'User document does not exist',
        userId: targetUserId
      };
    }

    const userData = userDoc.data();
    console.log('DEBUG: User data:', userData);
    
    return { 
      exists: true, 
      data: userData,
      userId: targetUserId,
      referredBy: userData.referredBy || null,
      referralCode: userData.referralCode || null,
      balance: userData.balance || 0,
      isMining: userData.isMining || false,
      boostersRemaining: userData.boostersRemaining || 10,
      boostersUsedThisSession: userData.boostersUsedThisSession || 0,
      activeAdBoosts: userData.activeAdBoosts || 0,
      miningRate: userData.miningRate || 0.20,
      baseMiningRate: userData.baseMiningRate || 0.20
    };
  } catch (error) {
    console.error('DEBUG: Error checking user data:', error);
    return { 
      error: error.message,
      userId: targetUserId
    };
  }
});

// Update referrals when new user registers
exports.updateReferrals = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

  const { referralCode } = data;
  const { uid } = context.auth;

  try {
    console.log('🚀 DEBUG: updateReferrals called with:', data);
    console.log('🔄 updateReferrals called for user:', uid);
    console.log('🎯 Referral code:', referralCode);

    // Validate referral code exists
    console.log('🔍 Searching for referral code:', referralCode.toUpperCase());
    const referrerQuery = await db.collection('users')
      .where('referralCode', '==', referralCode.toUpperCase())
      .get();

    console.log('🔍 Query result size:', referrerQuery.size);
    console.log('🔍 Query empty:', referrerQuery.empty);

    if (referrerQuery.empty) {
      console.log('❌ Referral code not found:', referralCode);
      return { success: false, message: 'Invalid referral code' };
    }

    const referrerDoc = referrerQuery.docs[0];
    const referrerId = referrerDoc.id;
    console.log('✅ Referrer found:', referrerId);

    // Check if user is not trying to refer themselves
    if (referrerId === uid) {
      console.log('❌ User trying to refer themselves');
      return { success: false, message: 'Cannot refer yourself' };
    }

    // Get current user data
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      console.log('❌ User document not found:', uid);
      return { success: false, message: 'User not found' };
    }

    const userData = userDoc.data();
    console.log('📊 User data:', userData);
    console.log('💰 User balance before:', userData.balance || 0);
    console.log('📅 User created at:', userData.createdAt);
    console.log('⏰ Current time:', admin.firestore.Timestamp.now());
    
    // Check if user is new (created within last 5 minutes)
    const currentTime = admin.firestore.Timestamp.now();
    const userCreatedAt = userData.createdAt;
    
    console.log('⏰ Current time:', currentTime);
    console.log('📅 User created at:', userCreatedAt);
    
    let isNewUser = false;
    if (!userCreatedAt) {
      console.log('❌ User createdAt is null, treating as new user');
      isNewUser = true;
    } else {
      const timeDiff = currentTime.toMillis() - userCreatedAt.toMillis();
      isNewUser = timeDiff < 5 * 60 * 1000; // 5 minutes
      console.log('⏰ Time difference (seconds):', Math.floor(timeDiff / 1000));
      console.log('🆕 Is new user:', isNewUser);
    }

    // Apply bonus to ANY user who doesn't have referredBy set yet
    // It doesn't matter when they created the account or their current balance
    const hasReferralCode = userData.referredBy && userData.referredBy !== null && userData.referredBy !== '';
    const bonusAmount = !hasReferralCode ? 10 : 0;
    console.log('🎁 User balance:', userData.balance || 0);
    console.log('🎁 User already has referredBy:', hasReferralCode);
    console.log('🎁 Will apply bonus:', bonusAmount > 0 ? 'YES' : 'NO');
    console.log('🎁 Bonus amount:', bonusAmount);

    // Don't update referrer stats here - will be done in transaction after validation

    // Update new user's referredBy field if not already set
    if (!userData.referredBy) {
      console.log('🔄 Setting referredBy field to referral code:', referralCode);
      console.log('🔄 User UID:', uid);
      console.log('🔄 Referral code to save:', referralCode.toUpperCase());
      
      try {
        // CRITICAL FIX: Use transaction to guarantee the update
        const userRef = db.collection('users').doc(uid);
        const result = await db.runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) {
            throw new Error('User document does not exist');
          }
          
          const currentData = userDoc.data();
          console.log('🔄 Transaction - Current referredBy:', currentData.referredBy);
          
          // CRITICAL: Check if user is trying to use their own referral code
          if (currentData.referralCode && currentData.referralCode === referralCode.toUpperCase()) {
            console.log('🔄 Transaction - User trying to use own referral code');
            return { success: false, reason: 'own_code', message: 'Nu poți folosi propriul tău cod de invitație' };
          }

          // CRITICAL: Check if user already has referredBy set
          if (currentData.referredBy && currentData.referredBy !== null && currentData.referredBy !== '') {
            console.log('🔄 Transaction - User already has referredBy:', currentData.referredBy);
            return { success: false, reason: 'already_set', message: 'Utilizatorul are deja un cod referral' };
          }

          // Update referredBy AND apply bonus
          const updateData = {
            referredBy: referralCode.toUpperCase(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          
          // Apply bonus for new referral
          updateData.balance = admin.firestore.FieldValue.increment(bonusAmount);
          console.log('🎁 Transaction - Applying bonus:', bonusAmount);
          
          console.log('🔄 Transaction - Updating with data:', updateData);
          transaction.update(userRef, updateData);
          
          // CRITICAL: Update referrer's stats ONLY after successful validation
          const referrerRef = db.collection('users').doc(referrerId);
          transaction.update(referrerRef, {
            totalReferrals: admin.firestore.FieldValue.increment(1),
            lastMemberJoined: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log('🔄 Transaction - Referrer stats updated');
          
          console.log('🔄 Transaction - referredBy updated to:', referralCode.toUpperCase());
          return { success: true, referredBy: referralCode.toUpperCase() };
        });
        
        console.log('✅ Transaction completed:', result);
        
        // CRITICAL: Update userData to reflect the new referredBy value
        userData.referredBy = referralCode.toUpperCase();
        
        if (result.success) {
          console.log('✅ referredBy field updated successfully via transaction');
        } else {
          console.log('⚠️ Transaction failed but referredBy was force saved:', result);
        }
        
        // Verify the update
        const verifyDoc = await db.collection('users').doc(uid).get();
        const verifyData = verifyDoc.data();
        console.log('✅ Verification - referredBy after transaction:', verifyData.referredBy);
        console.log('✅ Verification - Document ID:', uid);
        console.log('✅ Verification - Document exists:', verifyDoc.exists);
        
      } catch (error) {
        console.error('❌ Error updating referredBy field via transaction:', error);
        console.error('❌ Error details:', error.message);
        console.error('❌ Error code:', error.code);
        console.error('❌ Error stack:', error.stack);
        throw error; // Re-throw to see the error in client
      }
    } else {
      console.log('🔄 referredBy already set to:', userData.referredBy);
    }

    // Bonus is already applied in transaction above

    console.log('🎉 Referral processed successfully');
    return { 
      success: true, 
      message: 'Referral processed successfully',
      bonusApplied: bonusAmount,
      referralCode: referralCode.toUpperCase()
    };

  } catch (error) {
    console.error('❌ Error processing referral:', error);
    return { success: false, error: error.message };
  }
});

// Update referrer's active referrals when user starts/stops mining
exports.updateReferrerActiveReferrals = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

  const { isMining } = data;
  const { uid } = context.auth;

  try {
    console.log('🔄 updateReferrerActiveReferrals called for user:', uid);
    console.log('🔄 isMining:', isMining);

    // Get user data to find their referrer
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data();
    const referredBy = userData.referredBy;

    if (!referredBy) {
      console.log('🔄 User has no referrer, skipping update');
      return { success: true, message: 'No referrer to update' };
    }

    console.log('🔄 User referred by:', referredBy);

    // Find the referrer user
    const referrerQuery = await db.collection('users')
      .where('referralCode', '==', referredBy)
      .get();

    if (referrerQuery.empty) {
      console.log('❌ Referrer not found for code:', referredBy);
      return { success: false, message: 'Referrer not found' };
    }

    const referrerDoc = referrerQuery.docs[0];
    const referrerId = referrerDoc.id;
    const referrerData = referrerDoc.data();

    console.log('✅ Referrer found:', referrerId);
    console.log('🔄 Current referrer activeReferrals:', referrerData.activeReferrals);
    console.log('🔄 Current referrer miningRate:', referrerData.miningRate);

    // Calculate new values
    const currentActiveReferrals = referrerData.activeReferrals || 0;
    const currentMiningRate = referrerData.miningRate || 0.20;
    const baseMiningRate = referrerData.baseMiningRate || 0.20;

    let newActiveReferrals;
    let newMiningRate;

    if (isMining) {
      // User started mining - add to active referrals
      newActiveReferrals = currentActiveReferrals + 1;
      newMiningRate = baseMiningRate + (newActiveReferrals * 0.20);
      console.log('🔄 User started mining - adding to active referrals');
    } else {
      // User stopped mining - remove from active referrals
      newActiveReferrals = Math.max(0, currentActiveReferrals - 1);
      newMiningRate = baseMiningRate + (newActiveReferrals * 0.20);
      console.log('🔄 User stopped mining - removing from active referrals');
    }

    console.log('🔄 New activeReferrals:', newActiveReferrals);
    console.log('🔄 New miningRate:', newMiningRate);

    // Update referrer's data
    await db.collection('users').doc(referrerId).update({
      activeReferrals: newActiveReferrals,
      miningRate: newMiningRate,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Referrer updated successfully');

    return { 
      success: true, 
      message: 'Referrer updated successfully',
      newActiveReferrals: newActiveReferrals,
      newMiningRate: newMiningRate
    };

  } catch (error) {
    console.error('❌ Error updating referrer active referrals:', error);
    return { success: false, error: error.message };
  }
});

// Check mining sessions every minute and stop expired ones
exports.checkMiningSessions = functions.pubsub
  .schedule('every 120 minutes')
  .timeZone('Etc/UTC')
  .onRun(async (context) => {
    try {
      console.log('🔄 Checking mining sessions...');
      
      const now = Date.now();
      const sessionDuration = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
      
      // Get all users who are currently mining
      const usersSnapshot = await db.collection('users')
        .where('isMining', '==', true)
        .get();
        
      console.log(`Found ${usersSnapshot.size} users currently mining`);
      
      const batch = db.batch();
      let expiredCount = 0;
      
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const sessionStartTime = userData.sessionStartTime;
        
        if (sessionStartTime && (now - sessionStartTime) > sessionDuration) {
          // Session has expired - stop mining
          console.log(`⏰ Session expired for user ${doc.id}`);
          
          // Update user data immediately (not in batch)
          await doc.ref.update({
            isMining: false,
            lastMiningStopTime: now,
            notificationSent1: false,
            notificationSent2: false,
            notificationSent3: false,
            notificationSent4: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          expiredCount++;
          
          // Send notification 1 immediately if user has FCM token
          if (userData.fcmToken) {
            try {
              const message = {
                token: userData.fcmToken,
                notification: {
                  title: 'STC Mining Session Ended',
                  body: 'Your mining session has ended. Come back and start a new session!',
                },
                data: {
                  type: 'MINING_SESSION_END',
                  userId: doc.id,
                  timestamp: now.toString(),
                },
                android: {
                  priority: 'high',
                  notification: {
                    channelId: 'stc_channel',
                    priority: 'max',
                    sound: 'default',
                    icon: 'ic_notification',
                    color: '#4A90E2',
                    visibility: 'public',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    defaultLightSettings: true,
                  },
                  ttl: 60 * 60, // 1 hour
                  collapseKey: 'mining_session_end',
                },
                apns: {
                  payload: {
                    aps: {
                      alert: {
                        title: 'STC Mining Session Ended',
                        body: 'Your mining session has ended. Come back and start a new session!',
                      },
                      sound: 'default',
                      badge: 1,
                      'content-available': 1,
                    },
                  },
                  headers: {
                    'apns-priority': '10',
                    'apns-push-type': 'alert',
                  },
                },
              };
              
              await admin.messaging().send(message);
              console.log(`✅ Notification 1 sent to user ${doc.id}`);
              
              // Mark notification 1 as sent
              await doc.ref.update({
                notificationSent1: true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });
            } catch (error) {
              console.error(`❌ Error sending notification 1 to user ${doc.id}:`, error);
              
              // If token is invalid, remove it from user document
              if (error.code === 'messaging/registration-token-not-registered') {
                console.log(`🗑️ Removing invalid FCM token for user ${doc.id}`);
                await doc.ref.update({
                  fcmToken: admin.firestore.FieldValue.delete(),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
              }
            }
          }
        }
      }
      
      // Delayed notifications (2, 3, 4) are disabled
      console.log('Firebase delayed notifications disabled - skipping notifications 2, 3, 4');
      
      if (expiredCount > 0) {
        console.log(`✅ Stopped ${expiredCount} expired mining sessions`);
      } else {
        console.log('✅ No expired sessions found');
      }
      
      return null;
    } catch (error) {
      console.error('❌ Error checking mining sessions:', error);
      return null;
    }
  });

// Ping inactive team members to start mining
exports.pingInactiveMembers = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

  const { uid } = context.auth;

  try {
    console.log('🔄 pingInactiveMembers called for user:', uid);

    // Get user data to find their referral code
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data();
    const referralCode = userData.referralCode;

    if (!referralCode) {
      console.log('🔄 User has no referral code, no team to ping');
      return { success: true, message: 'No referral code found', pingedCount: 0 };
    }

    console.log('🔄 User referral code:', referralCode);

    // Find all team members (users referred by this user)
    const teamQuery = await db.collection('users')
      .where('referredBy', '==', referralCode)
      .get();

    if (teamQuery.empty) {
      console.log('🔄 No team members found');
      return { success: true, message: 'No team members found', pingedCount: 0 };
    }

    console.log('🔄 Found team members:', teamQuery.docs.length);

    const now = Date.now();
    let pingedCount = 0;
    const pingResults = [];

    // Check each team member and ping inactive ones
    for (const doc of teamQuery.docs) {
      const memberData = doc.data();
      const memberId = doc.id;
      const email = memberData.email || 'Unknown';
      const isMining = memberData.isMining || false;
      const lastMiningUpdate = memberData.lastMiningUpdate;
      const lastAppActivity = memberData.lastAppActivity;
      const fcmToken = memberData.fcmToken;

      // Determine if member is inactive
      const isInactive = !isMining && 
                        ((lastMiningUpdate == null || (now - lastMiningUpdate) > 24 * 60 * 60 * 1000) ||
                         (lastAppActivity == null || (now - lastAppActivity) > 7 * 24 * 60 * 60 * 1000));

      console.log(`🔄 Member ${email}: isMining=${isMining}, isInactive=${isInactive}`);

      if (isInactive && fcmToken) {
        try {
          // Send push notification to inactive member
          const message = {
            notification: {
              title: '⛏️ Start Mining!',
              body: 'Your team leader wants you to start mining! Earn STC now!',
            },
            data: {
              type: 'ping_inactive',
              from: userData.email || 'Team Leader',
              action: 'start_mining',
            },
            token: fcmToken,
          };

          await admin.messaging().send(message);
          console.log(`✅ Ping sent to inactive member: ${email}`);
          pingedCount++;
          pingResults.push({ email, status: 'pinged' });
        } catch (error) {
          console.error(`❌ Failed to ping member ${email}:`, error);
          pingResults.push({ email, status: 'failed', error: error.message });
        }
      } else if (isInactive && !fcmToken) {
        console.log(`⚠️ Member ${email} is inactive but has no FCM token`);
        pingResults.push({ email, status: 'no_token' });
      } else {
        console.log(`✅ Member ${email} is already active`);
        pingResults.push({ email, status: 'already_active' });
      }
    }

    console.log(`✅ Ping completed. Pinged ${pingedCount} inactive members`);

    return {
      success: true,
      message: `Pinged ${pingedCount} inactive team members`,
      pingedCount: pingedCount,
      totalMembers: teamQuery.docs.length,
      results: pingResults
    };

  } catch (error) {
    console.error('❌ Error pinging inactive members:', error);
    return { success: false, error: error.message };
  }
});