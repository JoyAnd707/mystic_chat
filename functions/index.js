const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function previewText(s) {
  const t = (s || "").toString().trim().replace(/\s+/g, " ");
  if (!t) return "";
  return t.length > 80 ? t.slice(0, 80) + "…" : t;
}

exports.notifyOnNewRoomMessage = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { roomId, messageId } = context.params;
    const msg = snap.data() || {};

    const type = (msg.type || "").toString();
    const senderAppUserId = (msg.senderId || "").toString(); // joy/adi/...
    const text = (msg.text || "").toString();

    // ❌ no push for system lines
    if (type === "system") return null;

    // 1) Get room members (appUserIds)
    const roomRef = admin.firestore().doc(`rooms/${roomId}`);
    const roomSnap = await roomRef.get();
    if (!roomSnap.exists) return null;

    const room = roomSnap.data() || {};
    const memberIds = Array.isArray(room.memberIds) ? room.memberIds : [];

    if (!memberIds.length) return null;

    // recipients (exclude sender)
    const recipientAppUserIds = memberIds
      .map((x) => (x || "").toString())
      .filter((id) => id && id !== senderAppUserId);

    if (!recipientAppUserIds.length) return null;

    // 2) Query user docs by appUserId to collect tokens
    // (whereIn supports up to 10 per query; you have 7 -> OK)
    const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("appUserId", "in", recipientAppUserIds)
      .get();

const tokens = [];
usersSnap.forEach((doc) => {
  const u = doc.data() || {};
  const fcmTokens = u.fcmTokens;

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

    // 3) Build notification title/body
    const title = senderAppUserId || "New message";

    let body = "New message";
    if (type === "text") body = previewText(text) || "New message";
    if (type === "voice") body = "🎤 Voice message";
    if (type === "image") body = "🖼️ Image";

    // 4) Visible push + data for deep link
    const multicast = {
      tokens: uniqueTokens,
      notification: { title, body },
      data: {
        roomId: String(roomId),
        messageId: String(messageId),
        type: String(type),
        senderId: String(senderAppUserId || ""),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_high",
        },
      },
      apns: {
        payload: {
          aps: {
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
  });
