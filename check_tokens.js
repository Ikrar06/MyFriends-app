const admin = require('firebase-admin');
const serviceAccount = require('./myfriends-app-b016e-firebase-adminsdk-v56fk-8e5a4c5f28.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://myfriends-app-b016e.firebaseio.com'
});

const db = admin.firestore();

async function checkTokens() {
  console.log('\n=== Checking FCM Tokens ===\n');
  
  // User A
  const userAId = 'M0VWiy9z7TN044q0LjC6J4rPyHT2';
  const userADoc = await db.collection('users').doc(userAId).get();
  
  if (userADoc.exists) {
    const userAData = userADoc.data();
    console.log('User A (M0VWiy9z7TN044q0LjC6J4rPyHT2):');
    console.log('  Email:', userAData.email);
    console.log('  Name:', userAData.name);
    console.log('  FCM Token:', userAData.fcmToken ? userAData.fcmToken.substring(0, 30) + '...' : 'NO TOKEN');
    console.log('  Token Updated:', userAData.fcmTokenUpdatedAt ? new Date(userAData.fcmTokenUpdatedAt._seconds * 1000).toISOString() : 'N/A');
    console.log('');
  } else {
    console.log('User A not found!\n');
  }
  
  // User B
  const userBId = 'wEB2mVbT2BatyKRpKro8tLkLpVC2';
  const userBDoc = await db.collection('users').doc(userBId).get();
  
  if (userBDoc.exists) {
    const userBData = userBDoc.data();
    console.log('User B (wEB2mVbT2BatyKRpKro8tLkLpVC2):');
    console.log('  Email:', userBData.email);
    console.log('  Name:', userBData.name);
    console.log('  FCM Token:', userBData.fcmToken ? userBData.fcmToken.substring(0, 30) + '...' : 'NO TOKEN');
    console.log('  Token Updated:', userBData.fcmTokenUpdatedAt ? new Date(userBData.fcmTokenUpdatedAt._seconds * 1000).toISOString() : 'N/A');
    console.log('');
  } else {
    console.log('User B not found!\n');
  }
  
  // Compare tokens
  if (userADoc.exists && userBDoc.exists) {
    const tokenA = userADoc.data().fcmToken;
    const tokenB = userBDoc.data().fcmToken;
    
    if (tokenA && tokenB) {
      if (tokenA === tokenB) {
        console.log('⚠️ WARNING: Both users have THE SAME FCM token!');
        console.log('This is the problem - notifications will go to the same device.');
      } else {
        console.log('✅ Tokens are DIFFERENT (correct)');
      }
    } else if (!tokenB) {
      console.log('⚠️ WARNING: User B has NO FCM token!');
      console.log('This is why notifications are not working correctly.');
    } else if (!tokenA) {
      console.log('⚠️ WARNING: User A has NO FCM token!');
    }
  }
  
  process.exit(0);
}

checkTokens().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
