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
  if (!context.auth) {
    throw new Error('User must be authenticated');
  }

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

    // Check if user is not trying to use their own referral code
    const userDoc = querySnapshot.docs[0];
    if (userDoc.id === context.auth.uid) {
      return { valid: false, message: 'Cannot use your own referral code' };
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
    const referrerQuery = await db.collection('users')
      .where('referralCode', '==', referralCode.toUpperCase())
      .get();

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

    // Only apply bonus for new users
    const bonusAmount = isNewUser ? 10 : 0;
    console.log('🎁 Will apply bonus:', bonusAmount > 0 ? 'YES' : 'NO');
    console.log('🎁 Bonus amount:', bonusAmount);

    // Update referrer's stats FIRST
    console.log('📈 Updating referrer stats for:', referrerId);
    const referrerRef = db.collection('users').doc(referrerId);
    await referrerRef.update({
      totalReferrals: admin.firestore.FieldValue.increment(1),
      activeReferrals: admin.firestore.FieldValue.increment(1),
      lastMemberJoined: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('✅ Referrer stats updated');

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
          
          // Only update if referredBy is still null (prevent race conditions)
          if (!currentData.referredBy) {
            const updateData = {
              referredBy: referralCode.toUpperCase(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            console.log('🔄 Transaction - Updating with data:', updateData);
            transaction.update(userRef, updateData);
            return { success: true, referredBy: referralCode.toUpperCase() };
          } else {
            console.log('🔄 Transaction - referredBy already set to:', currentData.referredBy);
            return { success: false, reason: 'already_set', referredBy: currentData.referredBy };
          }
        });
        
        console.log('✅ Transaction completed:', result);
        
        if (result.success) {
          console.log('✅ referredBy field updated successfully via transaction');
        } else {
          console.log('⚠️ referredBy was already set to:', result.referredBy);
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

    // Add bonus to new user if applicable
    if (bonusAmount > 0) {
      const currentBalance = userData.balance || 0;
      const newBalance = currentBalance + bonusAmount;
      console.log('💰 New balance after bonus:', newBalance);

      await db.collection('users').doc(uid).update({
        balance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✅ User updated successfully');
      console.log('💰 Balance updated from', currentBalance, 'to:', newBalance);
    }

    console.log('🎉 Referral processed successfully');
    return { 
      success: true, 
      message: 'Referral processed successfully',
      bonusApplied: bonusAmount,
      newBalance: (userData.balance || 0) + bonusAmount,
      referralCode: referralCode.toUpperCase() // CRITICAL: Return referral code
    };

  } catch (error) {
    console.error('❌ Error processing referral:', error);
    return { success: false, error: error.message };
  }
});