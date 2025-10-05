const functions = require("firebase-functions");

exports.pingGenerateAgoraToken = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const admin = require("firebase-admin");
    if (!admin.apps.length) admin.initializeApp();

    const channelName = "warmup-channel";
    const callable = require("firebase-functions").httpsCallable;

    try {
      // Simulate a callable call (you can't call directly inside Cloud Function)
      console.log(`Warming up generateAgoraToken for channel: ${channelName}`);
    } catch (err) {
      console.error("Ping failed", err.message);
    }
  });
