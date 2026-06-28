const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function previewText(s) {
  const t = (s || "").toString().trim().replace(/\s+/g, " ");
  if (!t) return "";
  return t.length > 80 ? t.slice(0, 80) + "…" : t;
}

async function notifyForMessage({ snap, roomPath, roomId, messageId, roomKindDefault }) {
  const msg = snap.data() || {};

  const type = (msg.type || "").toString();
  const senderAppUserId = (msg.senderId || "").toString(); // joy/adi/...
  const text = (msg.text || "").toString();

  // ❌ no push for system lines
  if (type === "system") return null;

  // 1) Get room members (appUserIds)
  const roomRef = admin.firestore().doc(`${roomPath}/${roomId}`);
  const roomSnap = await roomRef.get();
  if (!roomSnap.exists) return null;

  const room = roomSnap.data() || {};

  // ✅ support BOTH schemas:
  // - rooms: memberIds
  // - dm_rooms: participants
  const memberIds = Array.isArray(room.memberIds)
    ? room.memberIds
    : (Array.isArray(room.participants) ? room.participants : []);

  if (!memberIds.length) return null;

  // recipients (exclude sender)
  const recipientAppUserIds = memberIds
    .map((x) => (x || "").toString())
    .filter((id) => id && id !== senderAppUserId);

  if (!recipientAppUserIds.length) return null;

  // 2) Query user docs by appUserId to collect tokens
  const usersSnap = await admin
    .firestore()
    .collection("users")
    .where("appUserId", "in", recipientAppUserIds)
    .get();

  const tokens = [];
  usersSnap.forEach((doc) => {
    const u = doc.data() || {};
    const fcmTokens = u.fcmTokens;

    const recipientAppUserId = (u.appUserId || "").toString();
    const activeDmWith = (u.activeDmWith || "").toString();
    const textPushEnabled = u.textPushEnabled !== false;
const chatroomPushEnabled = u.chatroomPushEnabled !== false;

if (roomKindDefault === "dm" && !textPushEnabled) {
  console.log(`Skipping DM push for ${recipientAppUserId}: textPush disabled`);
  return;
}

if (roomKindDefault === "group" && !chatroomPushEnabled) {
  console.log(`Skipping group push for ${recipientAppUserId}: chatroomPush disabled`);
  return;
}

    // If this is a DM, and the recipient is currently inside
    // the DM with this exact sender, do not send push to this recipient.
    if (
      roomKindDefault === "dm" &&
      activeDmWith &&
      activeDmWith === senderAppUserId
    ) {
      console.log(
        `Skipping DM push for ${recipientAppUserId}: active DM with ${senderAppUserId}`
      );
      return;
    }

    // supports both:
    // 1) map: { token: true, token2: true }
    // 2) array: [token, token2]
    if (Array.isArray(fcmTokens)) {
      fcmTokens.forEach((t) => {
        if (typeof t === "string" && t.trim()) tokens.push(t.trim());
      });
    } else if (fcmTokens && typeof fcmTokens === "object") {
      Object.keys(fcmTokens).forEach((t) => {
        if (typeof t === "string" && t.trim()) tokens.push(t.trim());
      });
    }
  });
  const uniqueTokens = Array.from(new Set(tokens)).filter(Boolean);
  if (!uniqueTokens.length) return null;

  // 3) Build body
  let body = "New message";
  if (type === "text") body = previewText(text) || "New message";
  if (type === "voice") body = "🎤 Voice message";
  if (type === "image") body = "🖼️ Image";

  // Decide kind for app-side routing
  const roomKind =
    (room.kind || "").toString() ||
    (String(roomId).startsWith("dm_") ? "dm" : roomKindDefault);

    // 4) Visible push notification + data
    const title =
      roomKind === "dm"
        ? String(senderAppUserId || "New message")
        : "New group message";

    const multicast = {
      tokens: uniqueTokens,

      notification: {
        title: title,
        body: String(body || "New message"),
      },

      data: {
        kind: String(roomKind),
        sender: String(senderAppUserId || "New message"),
        body: String(body || ""),
        roomId: String(roomId),
        messageId: String(messageId),
        type: String(type),
        senderId: String(senderAppUserId || ""),
      },

      android: {
        priority: "high",
        notification: {
          sound: "default",
        },
      },

      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: String(body || "New message"),
            },
            sound: "default",
          },
        },
      },
    };

  const res = await admin.messaging().sendEachForMulticast(multicast);

  // 5) Clean up dead tokens
  const deadTokens = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error && r.error.code ? r.error.code : "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        deadTokens.push(uniqueTokens[i]);
      }
    }
  });

  if (deadTokens.length) {
    const batch = admin.firestore().batch();
    usersSnap.forEach((doc) => {
      batch.update(doc.ref, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(deadTokens),
      });
    });
    await batch.commit();
  }

  return null;
}

// ✅ GROUP CHAT (existing path)
exports.notifyOnNewRoomMessage = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate((snap, context) => {
    const { roomId, messageId } = context.params;
    return notifyForMessage({
      snap,
      roomPath: "rooms",
      roomId,
      messageId,
      roomKindDefault: "group",
    });
  });

// ✅ DMS (new path)
exports.notifyOnNewDmMessage = functions.firestore
  .document("dm_rooms/{roomId}/messages/{messageId}")
  .onCreate((snap, context) => {
    const { roomId, messageId } = context.params;
    return notifyForMessage({
      snap,
      roomPath: "dm_rooms",
      roomId,
      messageId,
      roomKindDefault: "dm",
    });
  });
