const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const MAX_TOKENS_PER_BATCH = 500;

exports.sendNotificationRequest = onDocumentCreated(
  "notificationRequests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    const requestId = event.params.requestId;

    if (!snapshot) {
      console.log("No notification request snapshot found", { requestId });
      return;
    }

    const request = snapshot.data();
    console.log("Notification request created", { requestId, request });

    if (request.status !== "pending") {
      console.log("Skipping notification request because status is not pending", {
        requestId,
        status: request.status,
      });
      return;
    }

    try {
      const title = asNonEmptyString(request.title, "KitaConnect");
      const body = asNonEmptyString(
        request.body,
        "Es gibt neue Informationen in KitaConnect.",
      );
      const type = asNonEmptyString(request.type, "notification");
      const createdBy = asNonEmptyString(request.createdBy, "");

      const tokens = await collectFcmTokens(createdBy);
      console.log("Collected FCM tokens", {
        requestId,
        tokenCount: tokens.length,
        skippedCreatedBy: Boolean(createdBy),
      });

      const result = await sendPushNotifications({
        tokens,
        title,
        body,
        type,
        requestId,
      });

      await snapshot.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        sentCount: result.successCount,
        failureCount: result.failureCount,
      });

      console.log("Notification request processed", {
        requestId,
        sentCount: result.successCount,
        failureCount: result.failureCount,
      });
    } catch (error) {
      console.error("Notification request failed", { requestId, error });

      await snapshot.ref.update({
        status: "error",
        errorMessage: error.message || String(error),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  },
);

async function collectFcmTokens(createdBy) {
  const tokens = new Set();
  const usersSnapshot = await db.collection("users").get();

  for (const userDoc of usersSnapshot.docs) {
    if (createdBy && userDoc.id === createdBy) {
      console.log("Skipping tokens for notification creator", {
        uid: userDoc.id,
      });
      continue;
    }

    const tokenSnapshot = await userDoc.ref.collection("fcmTokens").get();

    for (const tokenDoc of tokenSnapshot.docs) {
      const tokenData = tokenDoc.data();
      const token = asNonEmptyString(tokenData.token, tokenDoc.id);

      if (!token) {
        console.log("Skipping empty FCM token", {
          uid: userDoc.id,
          tokenDocumentId: tokenDoc.id,
        });
        continue;
      }

      tokens.add(token);
    }
  }

  return [...tokens];
}

async function sendPushNotifications({ tokens, title, body, type, requestId }) {
  if (tokens.length === 0) {
    console.log("No FCM tokens found for notification request", { requestId });
    return { successCount: 0, failureCount: 0 };
  }

  let successCount = 0;
  let failureCount = 0;

  for (const tokenBatch of chunk(tokens, MAX_TOKENS_PER_BATCH)) {
    console.log("Sending notification batch", {
      requestId,
      batchSize: tokenBatch.length,
    });

    const response = await messaging.sendEachForMulticast({
      tokens: tokenBatch,
      notification: {
        title,
        body,
      },
      data: {
        type,
        requestId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    if (response.failureCount > 0) {
      response.responses.forEach((sendResponse, index) => {
        if (!sendResponse.success) {
          console.log("FCM send failed", {
            requestId,
            token: tokenBatch[index],
            errorCode: sendResponse.error && sendResponse.error.code,
            errorMessage: sendResponse.error && sendResponse.error.message,
          });
        }
      });
    }
  }

  return { successCount, failureCount };
}

function chunk(items, size) {
  const chunks = [];

  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }

  return chunks;
}

function asNonEmptyString(value, fallback) {
  if (typeof value !== "string") {
    return fallback;
  }

  const trimmed = value.trim();
  return trimmed || fallback;
}
