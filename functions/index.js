/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// تأكد إن الـ admin متاح لمرة واحدة
if (!admin.apps.length) {
  admin.initializeApp();
}

// Function to sync Firestore data to Realtime Database
exports.syncToRealtime = functions.firestore
  .document("rooms/{roomId}/devices/{deviceId}")
  .onWrite((change, context) => {
    const roomId = context.params.roomId;
    const deviceId = context.params.deviceId;
    const afterData = change.after.exists ? change.after.data() : null;

    if (afterData) {
      const status = afterData.status || "off";
      return admin.database().ref(`/rooms/${roomId}/${deviceId}`).set({
        status: status,
        updated_at: new Date().toISOString(),
      });
    } else {
      // If document is deleted, remove from Realtime DB
      return admin.database().ref(`/rooms/${roomId}/${deviceId}`).remove();
    }
  });
