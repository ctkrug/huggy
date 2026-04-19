const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// Trigger: new hug created → notify receiver
exports.onHugCreated = onDocumentCreated("hugs/{hugId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const hug = snap.data();
  const { receiverId, senderId, hugType } = hug;

  // Get sender name
  const senderDoc = await db.collection("users").doc(senderId).get();
  const senderName = senderDoc.exists
    ? senderDoc.data().displayName
    : "Someone";

  // Get receiver FCM token
  const receiverDoc = await db.collection("users").doc(receiverId).get();
  if (!receiverDoc.exists) return;

  const fcmToken = receiverDoc.data().fcmToken;
  if (!fcmToken) return;

  const hugId = event.params.hugId;

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
    await getMessaging().send(message);

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
});

// Trigger: hug request → notify partner
exports.onHugRequested = onDocumentCreated(
  "hugRequests/{reqId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const request = snap.data();
    const { senderUid, receiverUid } = request;

    // Get sender name
    const senderDoc = await db.collection("users").doc(senderUid).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().displayName
      : "Someone";

    // Get receiver FCM token
    const receiverDoc = await db.collection("users").doc(receiverUid).get();
    if (!receiverDoc.exists) return;

    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return;

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
      await getMessaging().send(message);
    } catch (error) {
      console.error("Error sending hug request notification:", error);
    }
  }
);
