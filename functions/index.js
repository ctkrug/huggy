const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// Trigger: new hug created → notify receiver
exports.onHugCreated = functions.firestore
  .document("hugs/{hugId}")
  .onCreate(async (snap, context) => {
    const hug = snap.data();
    const { receiverId, senderId, hugType } = hug;

    // Get sender name
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().displayName
      : "Someone";

    // Get receiver FCM token
    const receiverDoc = await db.collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) return null;

    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return null;

    const hugId = context.params.hugId;

    const message = {
      token: fcmToken,
      notification: {
        title: `${senderName} sent you a hug!`,
        body: `You received a ${hugType} hug 🤗`,
      },
      data: {
        hugId: hugId,
        type: "hug_received",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);

      // Update streak
      const coupleId = hug.coupleId;
      if (coupleId) {
        const coupleRef = db.collection("couples").doc(coupleId);
        const coupleDoc = await coupleRef.get();
        if (coupleDoc.exists) {
          const coupleData = coupleDoc.data();
          const lastHugAt = coupleData.lastHugAt
            ? coupleData.lastHugAt.toDate()
            : null;
          const now = new Date();
          const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
          const twoDaysAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000);

          let newStreak = coupleData.hugStreak || 0;

          if (lastHugAt && lastHugAt > oneDayAgo) {
            // Already hugged today, no streak change
          } else if (lastHugAt && lastHugAt > twoDaysAgo) {
            // Hugged yesterday, increment streak
            newStreak += 1;
          } else {
            // Streak broken or first hug
            newStreak = 1;
          }

          await coupleRef.update({ hugStreak: newStreak });
        }
      }
    } catch (error) {
      console.error("Error sending hug notification:", error);
    }

    return null;
  });

// Trigger: hug request → notify partner
exports.onHugRequested = functions.firestore
  .document("hugRequests/{reqId}")
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const { senderUid, receiverUid } = request;

    // Get sender name
    const senderDoc = await db.collection("users").doc(senderUid).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().displayName
      : "Someone";

    // Get receiver FCM token
    const receiverDoc = await db.collection("users").doc(receiverUid).get();
    if (!receiverDoc.exists) return null;

    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return null;

    const message = {
      token: fcmToken,
      notification: {
        title: `${senderName} needs a hug!`,
        body: `Send them some love 💕`,
      },
      data: {
        type: "hug_request",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending hug request notification:", error);
    }

    return null;
  });
