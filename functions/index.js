const functions = require("firebase-functions");
const admin = require("firebase-admin");
const apn = require("apn");
const express = require("express");
const bodyParser = require("body-parser");
const axios = require("axios");
const base64 = require("base-64");
const { event } = require("firebase-functions/v1/analytics");
const { log } = require("firebase-functions/logger");
const { format } = require("date-fns");
const fetch = require("node-fetch");
const AWS = require("aws-sdk");
const algoliasearch = require("algoliasearch");

const fs = require("fs");
const vision = require("@google-cloud/vision");
const videoIntelligence = require("@google-cloud/video-intelligence").v1;
const { Storage } = require("@google-cloud/storage");
const { PassThrough } = require("stream");
const { v4: uuidv4 } = require("uuid");
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

admin.initializeApp({
  credential: admin.credential.cert({
    type: "service_account",
    project_id: "my-mink",
    private_key_id: "5d3da3147f7c5748507cfba726cb2024641adaee",
    private_key:
      "-----BEGIN PRIVATE KEY-----\nMIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQDRSOfcP7HyNtGK\ncW6h+Nhywj0DK6zQBXbdkmZBTOlfXoYndpBGGArxdWKP11bxssG1atdwQL7lgYFa\nCXUhl+d7ZDBG1hGUcOFpKhaTMidzUhLD7RO8XRdOlycSvAwt0I8dhv+peGQQnQTk\n115oihzm8988kXbuQruy0pg2dVg4I+Mm1A5KL3ijykRDiv3GO+LUsOrxkHg0R2eW\n5PqT2MdM+74GFFKujEaB22xy3hagSvrgT4kKd60OiU+DpkRymOgUw4H1hyc6SmRB\nEBZ8wuquwHUMcttUbdSOBRzg/ygPtCgvLa7ryQN0nWZsLYqhUU48pijR4kjfc3LV\na3YRfRFVAgMBAAECgf8lhgZyw8Wj9MnQVYYzt4PkQrwUIkCNC6D3f5UJIEEd8e5O\n8dmF6vzYGucRFnFmsVlwRze/zw834+bNV35cB5OTDBbPAvkj8RlGDpKXOBoN3/YW\n97erwWuF+JPvR/tNbsqgmkcJaHLu7gUMNfedxr80qYUQPWr75sfzyAG1we31vCZS\n43UiWQikdh/mc9+U2JLoV25YHEz9U0Dp3Qxvn2gJU1aAIBoI7gljXDPspiJcPzMa\ni7p7FwLIPSSC0bxP8g+zA4zMRKHXlKJb1/WwSlbJWpd0HPy2F3vOl1IFoh0eRMPR\nCk5ido5FWtGZm+XAK0tsg1z28WcwASJzqSWj22sCgYEA2UWoinM2NNtSr3oiC1CP\n12MhJ8kXBKVSpDoO+HK3tTnOPl5bNCuytMqftqBpugmoF91+/WPNDhQl3O2yOBMt\nOiUzgdlrqiRE9fC+vpzg9GItglOjT7xmY6lBTyoZDlBo2eugwbYt2AIlwqXW/KPd\nFq7PdcAQRHgXRiyOBcls9k8CgYEA9pbHOhekHD0Pd/+jGU+jXs4PRKHUHI0jX0/p\nvYfpnktUrurbIPauyEYH5DM2IE0e7VNuw0aiTSWdUEkyz/YdL6NKkQ4QKnwD48au\nYbvogDArVNd1heE1wuM7kEpmLhihSnFBgW2NAE/USAAwFb6dy2SF5oFVQ9C63bSa\nhFsAuRsCgYB10HjowjqFhNwcPPzS59dnsuAao8bwhPkABl9xxzrocTTtytpnur5H\nnIvoSqmp8GyOrFOc8Q4S8UfquZVnJLbkjaGVaqEf/FTMi8PStlyhB8+nmNS4eu+G\nYRQB6lD12xJQAJ4GDFRlihyRpL2j9vL+xsHGFuR7TCdKrQRCDQwhrwKBgQCQk9zh\noaTV7bMZH2hoWbomxthK3Ds6NkJMCtW4C20dI3vWRtsN27SktfLAiIourCj66xUh\nJ1PXubsfrJs/NUTtfmck30L5NdcuAHqT0RHDvvpY9y7vvRjBWGu+8PAyDLzcocTP\ndwTZ7vQ+9uU6ipWIADtF6ASvCz3U6aRC//xPiwKBgCFHIwB00Y09rXUqJWYb+YUh\ne15A6XVIWkqAo6R/KGbQx4mQorMKe5DvvPHVRmMLu3jUvuSu5nYC3JpFfms1LK59\nNHUjoYBBm1FFKwUhEjZUpZiFbVT0493/1Sgt0J1ILWB9ro2tHxHsQ9lwDeyU0oNJ\nb3a6zAvOIgrlI6Ouhzp1\n-----END PRIVATE KEY-----\n",
    client_email: "firebase-adminsdk-2gw0a@my-mink.iam.gserviceaccount.com",
    client_id: "114778509096057276776",
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url:
      "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-2gw0a%40my-mink.iam.gserviceaccount.com",
    universe_domain: "googleapis.com",
  }),
});

admin.firestore().settings({ ignoreUndefinedProperties: true });
const db = admin.firestore();
const storage = new Storage();
// Initialize Algolia, replace with your own credentials
const client = algoliasearch("9XQY8DOXRV", "0904fb732ab2992c81a3129991bb5100");

const s3 = new AWS.S3({
  accessKeyId: "AKIAVRLFHTFV2Y7OUZPD",
  secretAccessKey: "IbRXcyR1uNGOuZDfFa77MISVur0p5YLLAOpPM4Qx",
  region: "us-east-1", // Specify your region if necessary
});

// Initialize Google Cloud Vision client with service account
const visionClient = new vision.ImageAnnotatorClient();
const videoIntelligenceClient =
  new videoIntelligence.VideoIntelligenceServiceClient();

exports.sendUnifiedNotification = functions.https.onCall(
  async (data, context) => {
    const {
      title,
      body,
      agoraToken,
      channelName,
      callerName,
      callId,
      fcmToken, // alias
    } = data;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing deviceToken or fcmToken"
      );
    }

    let message;

    if (agoraToken && channelName && callerName && callId) {
      // Call-type notification
      message = {
        token: fcmToken,
        android: {
          priority: "high",
        },
        data: {
          id: callId,
          nameCaller: callerName,
          handle: "1234567890",
          type: "0",
          avatar: "https://i.pravatar.cc/100",
          notificationtype: "incoming_call",
          agoraToken: agoraToken,
          channelName: channelName,
        },
      };
    } else if (title || body) {
      // Simple push
      message = {
        token: fcmToken,
        notification: {
          title: title || "Default Title",
          body: body || "Default Body",
        },
      };
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing notification data"
      );
    }

    try {
      console.log("Sending FCM message:", message);
      const response = await admin.messaging().send(message);
      console.log("FCM send response:", response);
      return { success: true, message: "Notification sent", response };
    } catch (error) {
      console.error("Notification send error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

exports.pingGenerateAgoraToken = require("./ping").pingGenerateAgoraToken;

// Replace with your Agora App ID and App Certificate
const APP_ID = "107d8337cdc34ecca9be641fed1809da";
const APP_CERTIFICATE = "87dcefa31ae9482fbe4fe6f610fadb4b";

exports.generateAgoraToken = functions.https.onCall((data, context) => {
  const channelName = data.channelName;

  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing channelName in request data"
    );
  }

  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpireTs = currentTimestamp + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    0, // UID = 0 (will be set by Agora)
    role,
    privilegeExpireTs
  );

  return { token };
});

exports.searchByAlgolia = functions.https.onCall((data, context) => {
  // Check user authentication
  if (!context.auth) {
    return { error: "The function must be called while authenticated." };
  }

  // Validate inputs
  const searchText = data.searchText;
  const indexName = data.indexName;
  if (!searchText || !indexName) {
    return {
      error: 'The function must be called with "searchText" and "indexName".',
    };
  }
  // Initialize the appropriate index
  const index = client.initIndex(indexName);

  // Perform the search
  return index
    .search(searchText, {
      filters: data.filters || "", // Optional filters can be passed in data
    })
    .then((response) => {
      return JSON.stringify(response.hits);
    })
    .catch((error) => {
      return { error: error.message };
    });
});

exports.deleteProduct = functions.https.onCall(async (data, context) => {
  const id = data.id;
  const images = data.images || [];

  try {
    await admin.firestore().collection("Marketplace").doc(id).delete();

    deleteImageItem(images); // Call without await

    deleteDeepLink(`product/${id}`);

    // Return success message immediately to the user
    return { success: true, message: "Product deleted." };
  } catch (error) {
    return { error: error.message };
  }
});

exports.deleteAWSFile = functions.https.onCall(async (data, context) => {
  const type = data.type;
  const key = data.key;

  if (!type || !key) {
    return { error: "The function must be called with File key and type" };
  }

  try {
    // Delete the post document

    if (type == "image") {
      deleteImageItem([key]);
    } else if (type == "video") {
      deleteVideoItem(key);
    }

    return { success: true, message: "File Deleted." };
  } catch (error) {
    return { error: error.message };
  }
});

exports.deletePostById = functions.https.onCall(async (data, context) => {
  const id = data.id;

  const docRef = db.doc(`Posts/${id}`);

  try {
    const doc = await docRef.get();
    if (!doc.exists) {
      return { error: "No post found." };
    }

    const postType = doc.data().postType;
    const images = doc.data().images || [];
    const postVideo = doc.data().postVideo;
    const videoImage = doc.data().videoImage;

    const response = await deletePost(
      id,
      postType,
      images,
      postVideo,
      videoImage
    );
    return response;
  } catch (error) {
    console.error("Error retrieving post:", error);
    return { error: "Failed to retrieve the post." };
  }
});

exports.deletePostByModel = functions.https.onCall(async (data, context) => {
  const id = data.id;
  const postType = data.postType;
  const images = data.images || [];
  const postVideo = data.postVideo;
  const videoImage = data.videoImage;

  const response = await deletePost(
    id,
    postType,
    images,
    postVideo,
    videoImage
  );
  return response;
});

async function deletePost(id, postType, images, postVideo, videoImage) {
  try {
    // Delete the post document
    await admin.firestore().collection("Posts").doc(id).delete();
    await admin
      .firestore()
      .collection("DeletePost")
      .doc("last")
      .set({ postId: id });

    // Delete subcollections: likes, comments, and shares
    await Promise.all([
      deleteSubcollection(`Posts/${id}/Likes`),
      deleteSubcollection(`Posts/${id}/Comments`),
      deleteSubcollection(`Posts/${id}/Shares`),
      deleteSubcollection(`Posts/${id}/SavePosts`),
    ]);

    // Handle video or image deletion
    if (postType === "video") {
      deleteDeepLink(`video/${id}`);

      deleteVideoItem(postVideo);
      deleteImageItem([videoImage]);
    } else if (postType === "image") {
      deleteImageItem(images);

      deleteDeepLink(`image/${id}`);
    }

    return { success: true, message: "Post and all related data deleted." };
  } catch (error) {
    return { error: error.message };
  }
}

// Trigger on FeedFollowChange
exports.updateFeedOnFollowChange = functions.firestore
  .document("Users/{userId}/Following/{followingId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;

    try {
      // Get the list of followed users
      const followingsSnapshot = await admin
        .firestore()
        .collection("Users")
        .doc(userId)
        .collection("Following")
        .get();

      const followedUserIds = followingsSnapshot.docs.map((doc) => doc.id);
      followedUserIds.push(userId);

      const batchSize = 10;
      const batches = [];

      for (let i = 0; i < followedUserIds.length; i += batchSize) {
        batches.push(followedUserIds.slice(i, i + batchSize));
      }

      let allPosts = [];

      for (const batch of batches) {
        const postsSnapshot = await admin
          .firestore()
          .collection("Posts")
          .where("uid", "in", batch)
          .orderBy("postCreateDate", "desc")
          .get();

        if (!postsSnapshot || postsSnapshot.empty) {
          console.warn(`No posts found for batch: ${batch}`);
        }

        allPosts.push(
          ...postsSnapshot.docs.map((doc) => ({
            id: doc.id,
            data: doc.data(),
            readTime: doc.readTime || new Date().toISOString(), // Ensuring readTime is captured
          }))
        );
      }

      // Update the user's feed with the list of post IDs
      const feedRef = admin
        .firestore()
        .collection("Feeds")
        .doc(userId)
        .collection("postIds");
      const feedBatch = admin.firestore().batch();
      allPosts.forEach((post) => {
        if (!post.data.bid || post.data.bid.trim() === "") {
          feedBatch.set(feedRef.doc(post.id), {
            postCreateDate: post.data.postCreateDate,
          });
        }
      });

      // Clear any existing feed items not in the new list
      const existingFeedSnapshot = await feedRef.get();

      if (!existingFeedSnapshot || existingFeedSnapshot.empty) {
        console.warn(`No existing feed documents found for user ${userId}`);
      }

      existingFeedSnapshot.docs.forEach((doc) => {
        if (!allPosts.some((post) => post.id === doc.id)) {
          feedBatch.delete(doc.ref);
        }
      });

      await feedBatch.commit();

      console.log(
        `Updated feed for user ${userId} with ${allPosts.length} posts.`
      );
      return null;
    } catch (error) {
      console.error(`Error updating feed for user ${userId}:`, error);
      return { error: error.message };
    }
  });

exports.updateFeedsOnNewPost = functions
  .runWith({
    timeoutSeconds: 540, // Set timeout to 9 minutes (maximum is 9 minutes)
    memory: "512MB", // Options: '128MB', '256MB', '512MB', '1GB', '2GB', '4GB'
  })
  .firestore.document("Posts/{postId}")
  .onCreate(async (snapshot, context) => {
    const postData = snapshot.data();
    const userId = postData.uid;
    const postType = postData.postType;
    const postId = postData.postID;
    const images = postData.postImages || [];
    const postVideo = postData.postVideo;
    const videoImage = postData.videoImage;
    const image_base_url = "https://d34hi5x7melm0j.cloudfront.net/";
    const video_base_url =
      "https://mymink-storagea113e-dev.s3.ap-southeast-2.amazonaws.com/";

    try {
      // Update the feed for the user who created the post
      const feedRef = admin
        .firestore()
        .collection("Feeds")
        .doc(userId)
        .collection("postIds")
        .doc(postId);
      if (!postData.bid || postData.bid.trim() === "") {
        await feedRef.set({ postCreateDate: postData.postCreateDate });

        // Get all users who follow the user who created the post
        const followersSnapshot = await admin
          .firestore()
          .collectionGroup("Following")
          .where("uid", "==", userId)
          .get();

        const followerUpdates = followersSnapshot.docs.map(async (doc) => {
          const followerId = doc.ref.parent.parent.id;
          const followerFeedRef = admin
            .firestore()
            .collection("Feeds")
            .doc(followerId)
            .collection("postIds")
            .doc(postId);

          if (!postData.bid || postData.bid.trim() === "") {
            await followerFeedRef.set({
              postCreateDate: postData.postCreateDate,
            });
          }
        });

        await Promise.all(followerUpdates);
      }

      if (postType === "image") {
        let explicitContentDetected = false;
        let aggregatedLabels = [];

        const checkImages = async () => {
          for (const imageUrl of images) {
            await detectExplicitContent(image_base_url + imageUrl)
              .then((isExplicit) => {
                if (isExplicit) {
                  explicitContentDetected = true;
                  return Promise.reject("Explicit content detected");
                }
              })
              .catch((error) => {
                if (error !== "Explicit content detected") {
                  console.error(
                    "Error during explicit content detection:",
                    error
                  );
                }
              });

            if (explicitContentDetected) {
              break;
            }
            // Generate metadata for the image
            const labels = await generateImageMetadata(
              image_base_url + imageUrl
            );
            aggregatedLabels = aggregatedLabels.concat(labels);
          }

          if (explicitContentDetected) {
            await deletePost(postId, postType, images, postVideo, videoImage);
          } else {
            // Store aggregated metadata in Firestore
            const metadataRef = admin
              .firestore()
              .collection("Posts")
              .doc(postId);
            await metadataRef.set(
              { metadata: aggregatedLabels },
              { merge: true }
            );
            console.log("All images are clean.");
          }
        };

        await checkImages();
      } else if (postType === "video") {
        // Example usage
        const s3Bucket = "myminkbucket190931-myminkapp";
        const s3Key = `public/${postVideo}`;
        const gcsBucket = "mymink-bucket-video-intelligent";
        const gcsDestination = `${uuidv4()}.mp4`;
        const gcsUri = `gs://${gcsBucket}/${gcsDestination}`;

        const checkVideo = async () => {
          try {
            await downloadVideoFromS3ToGCS(
              s3Bucket,
              s3Key,
              gcsBucket,
              gcsDestination
            );
            console.log(`Video uploaded to ${gcsUri}`);

            const isExplicit = await detectExplicitContentInVideo(gcsUri);
            // Delete the file from GCS after processing
            deleteFileFromGCS(gcsBucket, gcsDestination);
            if (isExplicit) {
              console.log("Explicit content detected");
              await deletePost(postId, postType, images, postVideo, videoImage);
            } else {
              console.log("Video is clean.");
            }
          } catch (error) {
            console.error("Error during explicit content detection:", error);
          }
        };

        await checkVideo();
      }

      return null;
    } catch (error) {
      console.error(`Error updating feeds with new post ${postId}:`, error);
      return { error: error.message };
    }
  });

// Trigger to update Feeds when a post is deleted
exports.updateFeedsOnPostDeletion = functions.firestore
  .document("Posts/{postId}")
  .onDelete(async (snapshot, context) => {
    const postData = snapshot.data();
    const postId = postData.postID;
    const userId = postData.uid;

    try {
      if (userId == context.params.userId) {
        const feedRef = admin
          .firestore()
          .collection("Feeds")
          .doc(userId)
          .collection("postIds")
          .doc(postId);

        // Remove the post ID from the follower's feed
        await feedRef.delete();
      } else {
        // Get all users who follow the user who created the post
        const followersSnapshot = await admin
          .firestore()
          .collectionGroup("Following")
          .where("uid", "==", userId)
          .get();

        const followerUpdates = followersSnapshot.docs.map(async (doc) => {
          const followerId = doc.ref.parent.parent.id;
          const feedRef = admin
            .firestore()
            .collection("Feeds")
            .doc(followerId)
            .collection("postIds")
            .doc(postId);

          // Remove the post ID from the follower's feed
          await feedRef.delete();
        });

        await Promise.all(followerUpdates);
      }

      return null;
    } catch (error) {
      console.error(`Error updating feeds on post deletion ${postId}:`, error);
      return { error: error.message };
    }
  });

exports.checkExplicitImage = functions.https.onCall(async (data, context) => {
  const imageName = data.image;
  const image_base_url = "https://d34hi5x7melm0j.cloudfront.net/";

  try {
    // Wait for the explicit content detection
    const isExplicit = await detectExplicitContent(image_base_url + imageName);

    if (isExplicit) {
      // Call the delete function and await its completion
      await deleteImageItem([imageName]);
      return { isExplicit: true, message: "EXPLICIT DETECTED" };
    } else {
      return { isExplicit: false, message: "All Good" };
    }
  } catch (error) {
    console.error("Error occurred:", error);
    return { isExplicit: false, message: error.message || "Unexpected Error" };
  }
});

// Function to detect explicit content using Google Cloud Vision
async function detectExplicitContent(imageUrl) {
  try {
    const [result] = await visionClient.safeSearchDetection(imageUrl);
    const detections = result.safeSearchAnnotation;

    const explicitContentDetected =
      detections.adult === "VERY_LIKELY" ||
      detections.violence === "VERY_LIKELY";

    return explicitContentDetected;
  } catch (error) {
    console.error("Error detecting explicit content: ", error);
    throw error;
  }
}

// Function to detect explicit content using Video intelligent
const detectExplicitContentInVideo = async (videoURL) => {
  const request = {
    inputUri: videoURL,
    features: ["EXPLICIT_CONTENT_DETECTION"],
  };

  console.log("Waiting for operation to complete...");
  const [operation] = await videoIntelligenceClient.annotateVideo(request);
  const [operationResult] = await operation.promise();

  const explicitContentResults =
    operationResult.annotationResults[0].explicitAnnotation;

  let isExplicit = false;

  explicitContentResults.frames.forEach((result) => {
    const timeOffsetSeconds = result.timeOffset?.seconds || 0;
    const timeOffsetNanos = result.timeOffset?.nanos || 0;

    console.log(
      `Time: ${timeOffsetSeconds}.${(timeOffsetNanos / 1e6).toFixed(0)}s`
    );
    console.log(`Pornography likelihood: ${result.pornographyLikelihood}`);

    // Adjusted threshold to ONLY VERY_LIKELY to reduce false positives
    if (result.pornographyLikelihood === 5) {
      isExplicit = true;
    }
  });

  console.log(`Overall video explicitness: ${isExplicit}`);
  return isExplicit;
};

const downloadVideoFromS3ToGCS = async (
  s3Bucket,
  s3Key,
  gcsBucket,
  gcsDestination
) => {
  const passThroughStream = new PassThrough();
  const s3Params = { Bucket: s3Bucket, Key: s3Key };

  // Create a stream from S3
  const s3Stream = s3.getObject(s3Params).createReadStream();

  // Pipe the S3 stream to the pass-through stream
  s3Stream.pipe(passThroughStream);

  // Pipe the pass-through stream to GCS
  const gcsStream = storage
    .bucket(gcsBucket)
    .file(gcsDestination)
    .createWriteStream({
      resumable: false,
      validation: false,
    });

  return new Promise((resolve, reject) => {
    passThroughStream.pipe(gcsStream).on("finish", resolve).on("error", reject);
  });
};

const deleteFileFromGCS = async (bucketName, fileName) => {
  storage.bucket(bucketName).file(fileName).delete();
  console.log(`gs://${bucketName}/${fileName} deleted.`);
};

const generateImageMetadata = async (imageUrl) => {
  const [result] = await visionClient.annotateImage({
    image: { source: { imageUri: imageUrl } },
    features: [
      { type: "LABEL_DETECTION", maxResults: 10 },
      { type: "OBJECT_LOCALIZATION", maxResults: 10 },
      { type: "WEB_DETECTION", maxResults: 10 },
    ],
  });

  // Combine labels, objects, and web detections
  const labels = (result.labelAnnotations || []).map((label) => ({
    description: label.description,
    score: label.score,
  }));

  const objects = (result.localizedObjectAnnotations || []).map((object) => ({
    description: object.name,
    score: object.score,
  }));

  const webEntities = (result.webDetection.webEntities || []).map((entity) => ({
    description: entity.description,
    score: entity.score,
  }));

  const combinedAnnotations = [...labels, ...objects, ...webEntities];

  // Sort by score in descending order
  combinedAnnotations.sort((a, b) => b.score - a.score);

  // Filter out any undefined descriptions and remove duplicates
  const uniqueAnnotations = [];
  const seenDescriptions = new Set();

  for (const annotation of combinedAnnotations) {
    if (
      annotation.description &&
      !seenDescriptions.has(annotation.description)
    ) {
      uniqueAnnotations.push(annotation);
      seenDescriptions.add(annotation.description);
    }
  }

  // Return only the top 5 results
  return uniqueAnnotations.slice(0, 5);
};

async function deleteSubcollection(collectionPath) {
  try {
    const snapshot = await admin.firestore().collection(collectionPath).get();
    const batch = admin.firestore().batch();

    // Check if there are documents to delete
    if (snapshot.empty) {
      console.log(
        "No documents to delete in the subcollection:",
        collectionPath
      );
      return null;
    }

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(
      "All documents in the subcollection have been deleted successfully."
    );
  } catch (error) {
    console.error(
      "Failed to delete subcollection:",
      collectionPath,
      "Error:",
      error
    );
    throw new Error(
      "Failed to delete subcollection due to an error: " + error.message
    );
  }
}

async function deleteVideoItem(postVideo) {
  try {
    const params = {
      Bucket: "myminkbucket190931-myminkapp",
      Prefix: `public/${postVideo}`,
    };
    const data = await s3.listObjectsV2(params).promise();

    const deleteParams = {
      Bucket: "myminkbucket190931-myminkapp",
      Delete: { Objects: data.Contents.map(({ Key }) => ({ Key })) },
    };

    await s3.deleteObjects(deleteParams).promise();

    return { error: null, response: "success" };
  } catch (error) {
    return { error: error, response: "failed" };
  }
}

async function deleteImageItem(images) {
  const deletePromises = [];

  images.forEach((item) => {
    const params = {
      Bucket: "myminkbucket190931-myminkapp",
      Key: `public/${item}`,
    };
    deletePromises.push(s3.deleteObject(params).promise());
  });

  try {
    await Promise.all(deletePromises);
    return { error: null, response: "success" };
  } catch (error) {
    return { error: error, response: "failed" };
  }
}

// Define the Cloud Function to delete a Like
exports.deleteLike = functions.https.onCall(async (data, context) => {
  const postID = data.postID;
  const userID = context.auth.uid; // Assumes userID comes from authenticated user context

  // Check if the request is authenticated
  if (!context.auth) {
    return { error: "Authentication required to remove likes." };
  }

  try {
    // Deleting the Like document from the Likes subcollection
    admin
      .firestore()
      .collection("Posts")
      .doc(postID)
      .collection("Likes")
      .doc(userID)
      .delete();

    return { success: true, message: "Like Removed" };
  } catch (error) {
    console.error("Error removing like:", error);
    return { error: error.message };
  }
});

// Define the Cloud Function to delete a Notification
exports.deleteUsersNotification = functions.https.onCall(
  async (data, context) => {
    const notificationId = data.notificationId;
    const userID = context.auth.uid;

    // Check if the request is authenticated
    if (!context.auth) {
      console.log("Authentication required to remove notifications.");
      return { error: "Authentication required to remove notifications." };
    }

    try {
      // Deleting the Notification document from the Notifications subcollection
      const result = await admin
        .firestore()
        .collection("Users")
        .doc(userID)
        .collection("Notifications")
        .doc(notificationId)
        .delete();

      console.log("Notification deleted successfully:", result); // result is usually undefined for successful deletions

      return { success: true, message: "Notification Deleted" };
    } catch (error) {
      console.error("Error removing notification:", error);
      return { error: error.message };
    }
  }
);

// Define the Cloud Function to delete a Subscribe
exports.deleteSubscribe = functions.https.onCall(async (data, context) => {
  const bID = data.bid;
  const userID = context.auth.uid; // Assumes userID comes from authenticated user context

  // Check if the request is authenticated
  if (!context.auth) {
    return { error: "Authentication required to remove Subscribe." };
  }

  try {
    // Deleting the Subscribe document from the Likes subcollection
    admin
      .firestore()
      .collection("Businesses")
      .doc(bID)
      .collection("Subscribers")
      .doc(userID)
      .delete();

    return { success: true, message: "Subscriber Removed" };
  } catch (error) {
    console.error("Error removing Subscribe:", error);
    return { error: error.message };
  }
});

// Define the Cloud Function to delete a Save
exports.deleteSave = functions.https.onCall(async (data, context) => {
  const postID = data.postID;
  const userID = context.auth.uid; // Assumes userID comes from authenticated user context

  // Check if the request is authenticated
  if (!context.auth) {
    return { error: "Authentication required to remove save posts." };
  }

  try {
    // Deleting the Like document from the Likes subcollection
    admin
      .firestore()
      .collection("Users")
      .doc(userID)
      .collection("SavePosts")
      .doc(postID)
      .delete();

    admin
      .firestore()
      .collection("Posts")
      .doc(postID)
      .collection("SavePosts")
      .doc(userID)
      .delete();

    return { success: true, message: "Save Post Removed" };
  } catch (error) {
    console.error("Error removing save:", error);
    return { error: error.message };
  }
});

exports.checkFollow = functions.https.onCall(async (data, context) => {
  const currentUserID = context.auth.uid;
  const userID = data.userID;

  if (!currentUserID) {
    return {
      success: false,
      error: "User not authenticated",
    };
  }

  try {
    const followDoc = await admin
      .firestore()
      .collection("Users")
      .doc(currentUserID)
      .collection("Followings")
      .doc(userID)
      .get();

    if (followDoc.exists) {
      return { success: true, isFollowing: true };
    } else {
      return { success: true, isFollowing: false };
    }
  } catch (error) {
    return {
      success: false,
      error: error.message,
    };
  }
});

exports.getCount = functions.https.onCall(async (data, context) => {
  const id = data.id;
  const countType = data.countType;

  if (!id || !countType) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid postID and countType."
    );
  }

  try {
    let collectionRef;
    switch (countType) {
      case "Likes":
        collectionRef = db.collection("Posts").doc(id).collection("Likes");
        break;
      case "Shares":
        collectionRef = db.collection("Posts").doc(id).collection("Shares");
        break;
      case "SavePosts":
        collectionRef = db.collection("Posts").doc(id).collection("SavePosts");
        break;
      case "UserSavePosts":
        collectionRef = db.collection("Users").doc(id).collection("SavePosts");
        break;
      case "Comments":
        collectionRef = db.collection("Posts").doc(id).collection("Comments");
        break;
      case "Subscribers":
        collectionRef = db
          .collection("Businesses")
          .doc(id)
          .collection("Subscribers");
        break;
      case "ProfileViews":
        collectionRef = db
          .collection("Users")
          .doc(id)
          .collection("ProfileViews");
        break;
      case "Following":
        collectionRef = db.collection("Users").doc(id).collection("Following");
        break;
      case "Follow":
        collectionRef = db.collection("Users").doc(id).collection("Follow");
        break;
      default:
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid countType provided."
        );
    }

    const countSnapshot = await collectionRef.count().get();
    const count = countSnapshot.data().count;

    return { count };
  } catch (error) {
    console.error("Error fetching count: ", error);
    throw new functions.https.HttpsError("internal", "Unable to fetch count.");
  }
});

exports.deleteDeepLinkByEndPath = functions.https.onCall(
  async (data, context) => {
    const endPath = data.endPath;
    const result = await deleteDeepLink(endPath);
    return result;
  }
);

async function deleteDeepLink(endPath) {
  console.log("Start deleteDeepLink", endPath);

  if (!endPath) {
    console.error("Invalid URL end path");
    return { error: "Invalid URL end path" };
  }

  // Construct the URL
  const baseUrl = "https://app.mymink.com.au"; // Replace this with your actual Branch base URL
  let encodedPath = encodeURIComponent(endPath).replace(/%2E/g, ".");
  const branchUrl = `${baseUrl}/${encodedPath}`;

  const apiUrl = `https://api2.branch.io/v1/url`;
  const appId = "1266419875924955837"; // Ensure this is correctly configured
  const accessToken = "api_app_58c2c124e3084c20900eb076eaa3fa3b"; // Ensure this is securely managed

  // Create the request URL with query parameters
  const requestUrl = new URL(apiUrl);
  requestUrl.searchParams.append("url", branchUrl);
  requestUrl.searchParams.append("app_id", appId);

  const options = {
    method: "DELETE",
    headers: {
      Accept: "application/json",
      "Access-Token": accessToken,
    },
  };

  try {
    const response = await fetch(requestUrl, options);
    if (response.ok) {
      console.log("Deep Link Deleted Successfully");
      return { success: true, message: "Deep Link deleted successfully" };
    } else {
      console.error("Failed to delete Deep Link", response.statusText);
      return { error: "Failed to delete Deep Link" };
    }
  } catch (error) {
    console.error("Delete Deep Link Error:", error);
    return { error: error.message };
  }
}

exports.deleteFollow = functions.https.onCall(async (data, context) => {
  const mUid = data.mUid; // UID of the main user
  const fUid = data.fUid; // UID of the follower user

  if (!context.auth) {
    return { error: "Authentication required" };
  }

  const userRef = admin.firestore().collection("Users");
  try {
    await Promise.all([
      // Delete the following document
      userRef.doc(mUid).collection("Following").doc(fUid).delete(),
      // Delete the follower document
      userRef.doc(fUid).collection("Follow").doc(mUid).delete(),
    ]);
    return { success: true };
  } catch (error) {
    console.error("Error deleting follow relationship:", error);
    return { error: error.message };
  }
});

exports.deleteLiveRecording = functions.https.onCall(async (data, context) => {
  const uid = data.uid; // UID to identify the recording to delete

  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure user is authenticated
  }

  try {
    await admin.firestore().collection("LiveRecordings").doc(uid).delete();
    return { success: true, message: "Live recording deleted." };
  } catch (error) {
    console.error("Error deleting live recording:", error);
    return { error: error.message };
  }
});

exports.deleteLastMessage = functions.https.onCall(async (data, context) => {
  const uid = data.uid; // UID of the user
  const otherUid = data.otherUid; // UID of the other user involved in the chat

  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure the user is authenticated
  }

  try {
    await admin
      .firestore()
      .collection("Chats")
      .doc(uid)
      .collection("LastMessage")
      .doc(otherUid)
      .delete();
    return { success: true, message: "Last message deleted successfully." };
  } catch (error) {
    console.error("Error deleting last message:", error);
    return { error: error.message };
  }
});
exports.deleteComment = functions.https.onCall(async (data, context) => {
  const postId = data.postId; // ID of the post from which to delete the comment
  const commentId = data.commentId; // ID of the comment to delete

  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure the user is authenticated
  }

  try {
    await admin
      .firestore()
      .collection("Posts")
      .doc(postId)
      .collection("Comments")
      .doc(commentId)
      .delete();
    return { success: true, message: "Comment deleted successfully." };
  } catch (error) {
    console.error("Error deleting comment:", error);
    return { error: error.message };
  }
});

exports.deleteEvent = functions.https.onCall(async (data, context) => {
  const eventId = data.eventId;

  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure the user is authenticated
  }

  try {
    await admin.firestore().collection("Events").doc(eventId).delete();
    return { success: true, message: "Event deleted successfully." };
  } catch (error) {
    console.error("Error deleting Event:", error);
    return { error: error.message };
  }
});

exports.deleteCoupon = functions.https.onCall(async (data, context) => {
  const sCode = data.sCode; // Code of the coupon to delete

  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure the user is authenticated
  }

  if (!sCode) {
    return { error: "Coupon code is required" }; // Validate that the coupon code is provided
  }

  try {
    await admin.firestore().collection("Coupons").doc(sCode).delete();
    return { success: true, message: "Coupon deleted successfully." };
  } catch (error) {
    console.error("Error deleting coupon:", error);
    return { error: error.message };
  }
});

exports.deleteLivestreamingAllAudiences = functions.https.onCall(
  async (data, context) => {
    const uid = data.uid; // UID of the livestreaming session

    if (!context.auth) {
      return { error: "Authentication required" }; // Ensure the user is authenticated
    }

    const audiencesPath = `LiveStreamings/${uid}/Audiences`;

    try {
      // Use the utility function to delete all documents in the subcollection
      await deleteSubcollection(audiencesPath);

      return {
        success: true,
        message: "All audience members deleted successfully.",
      };
    } catch (error) {
      console.error("Error deleting all audiences:", error);
      return { error: error.message };
    }
  }
);

exports.deleteNotification = functions.https.onCall(async (data, context) => {
  // Check if the user is authenticated
  if (!context.auth) {
    return { error: "Authentication required" }; // Ensure the user is authenticated
  }

  try {
    const notificationId = data.id;

    const docRef = admin.firestore().doc(`PushNotifications/${notificationId}`);
    await docRef.delete();
    return {
      result: `Notification with ID: ${notificationId} deleted successfully.`,
    };
  } catch (error) {
    console.error("Error deleting document:", error);
    return { error: error.message };
  }
});

//send notification

exports.sendNotificationToTopic = functions.https.onCall(
  async (data, context) => {
    const { title, message, topic } = data;

    // Ensure required fields are provided
    if (!title || !message || !topic) {
      console.error("Missing required fields: title, message, or topic.");
      return { error: "Missing required fields: title, message, or topic." };
    }

    // Ensure the user is authenticated
    if (!context.auth) {
      console.error("Authentication required.");
      return { error: "Authentication required." };
    }
    const message1 = {
      notification: {
        title: title,
        body: message,
      },
      topic: "all",
    };
    // Minimal payload with topic correctly placed

    try {
      // Send notification using the v1 API
      const response = await admin.messaging().send(message1);

      // Log the notification in Firestore
      const docRef = db.collection("PushNotifications").doc();
      await docRef.set({
        id: docRef.id,
        title: title,
        message: message,
        topic: topic,
        createDate: admin.firestore.FieldValue.serverTimestamp(),
        sentBy: context.auth.uid, // Log who sent the notification
      });
      console.error("Notification sent successfully.");
      return { result: "Notification sent successfully.", response };
    } catch (error) {
      console.error("Error sending notification:", error);
      return { error: `Error sending notification: ${error.message}` };
    }
  }
);

//Create Coupon
exports.createCoupon = functions.https.onCall(async (data, context) => {
  // Verify if the function call is authenticated
  if (!context.auth) {
    return { error: "Not authenticated." };
  }

  const length = data.length || 6; // Default length is 6 if not specified
  const expiryDate = data.expiryDate;

  // Generate a random coupon code
  const newCoupon = generateRandomCoupon(length);

  const docRef = db.doc(`Coupons/${newCoupon}`);

  try {
    await docRef.set({
      id: newCoupon,
      expiryDate: new Date(expiryDate),
      createDate: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { couponCode: newCoupon, message: "Coupon created successfully." };
  } catch (error) {
    console.error("Error creating coupon:", error);
    return { error: error.message };
  }
});

function generateRandomCoupon(length) {
  const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let coupon = "";
  for (let i = 0; i < length; i++) {
    coupon += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return coupon;
}

//Post Report No Issue
exports.deletePostReport = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  if (!context.auth) {
    return { error: "Not authenticated." };
  }

  const reportId = data.reportId;

  const docRef = db.doc(`Reports/${reportId}`);

  try {
    // Check if the document exists before attempting to delete
    const doc = await docRef.get();
    if (!doc.exists) {
      return { error: "No report found." };
    }

    await docRef.delete();
    return {
      message: `Report with ID: ${reportId} has been successfully deleted.`,
    };
  } catch (error) {
    console.error("Error deleting report:", error);
    return { error: error.message };
  }
});

//Comment Post Report No Issue
exports.deleteCommentReport = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  if (!context.auth) {
    return { error: "Not authenticated." };
  }

  const reportId = data.reportId;

  const docRef = db.doc(`CommentReports/${reportId}`);

  try {
    // Check if the document exists before attempting to delete
    const doc = await docRef.get();
    if (!doc.exists) {
      return { error: "No report found." };
    }

    await docRef.delete();
    return {
      message: `Report with ID: ${reportId} has been successfully deleted.`,
    };
  } catch (error) {
    console.error("Error deleting report:", error);
    return { error: error.message };
  }
});

//Delete Coupon
exports.deleteCoupon = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  if (!context.auth) {
    return { error: "Not authenticated." };
  }

  const couponId = data.couponId;

  const docRef = db.doc(`Coupons/${couponId}`);

  try {
    // Check if the document exists before attempting to delete
    const doc = await docRef.get();
    if (!doc.exists) {
      return { error: "No Coupon Found." };
    }

    await docRef.delete();
    return {
      message: `Coupon with ID: ${couponId} has been successfully deleted.`,
    };
  } catch (error) {
    console.error("Error deleting coupon:", error);
    return { error: error.message };
  }
});

exports.toggleUserBlockStatus = functions.https.onCall(
  async (data, context) => {
    // Verify user authentication
    if (!context.auth) {
      return { error: "Not authenticated" };
    }

    const userId = data.userId;

    try {
      const userDocRef = db.doc(`Users/${userId}`);
      // Get current user data
      const userDoc = await userDocRef.get();
      const userData = userDoc.data();

      if (!userData) {
        return { error: "User not found" };
      }

      // Toggle the isBlocked status
      const newBlockStatus = !userData.isBlocked;
      await userDocRef.update({ isBlocked: newBlockStatus });

      // Query all posts by this user
      const postsQuery = db.collection("Posts").where("uid", "==", userId);
      const postsSnapshot = await postsQuery.get();

      // Update all posts isActive status based on the new block status
      const updatePromises = postsSnapshot.docs.map((doc) =>
        doc.ref.set({ isActive: !newBlockStatus }, { merge: true })
      );

      // Wait for all post updates to complete
      await Promise.all(updatePromises);

      return {
        message: `User ${
          newBlockStatus ? "blocked" : "unblocked"
        } successfully.`,
      };
    } catch (error) {
      console.error("Error processing request:", error);
      return { error: error.message };
    }
  }
);

exports.deactivateUserAccount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const userId = data.userId;

    try {
      const userRef = admin.firestore().collection("Users").doc(userId);
      setIsActive({ userId, isActive: false });
      await userRef.set(
        { isAccountActive: false, isAccountDeactivate: true },
        { merge: true }
      );
      return {
        success: true,
        message:
          "User account and all associated data deactivate successfully.",
      };
    } catch (error) {
      console.error("Error deactivating user account:", error);
      return { error: error.message };
    }
  }
);

exports.reactivateUserAccount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const userId = data.userId;

    try {
      const userRef = admin.firestore().collection("Users").doc(userId);
      setIsActive({ userId, isActive: true });
      await userRef.set(
        { isAccountActive: true, isAccountDeactivate: false },
        { merge: true }
      );
      return {
        success: true,
        message:
          "User account and all associated data reactivate successfully.",
      };
    } catch (error) {
      console.error("Error reactivating user account:", error);
      return { error: error.message };
    }
  }
);

exports.deleteBusiness = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    // Get the business ID from the data
    const businessId = data.bid;

    // Check if businessId is provided
    if (!businessId) {
      return { error: "Business ID is required." };
    }

    // Proceed with deletion
    await deleteBusinessContinue(businessId);

    return { success: true, message: "Business successfully deleted." };
  } catch (error) {
    console.error("Error deleting business:", error);
    return { success: false, message: "Internal Server Error" };
  }
});

async function proceedOtherBusinessDataDeletion(businessId) {
  // Step 1: Delete all posts by the user
  const postsRef = admin.firestore().collection("Posts");
  const userPostsSnapshot = await postsRef.where("bid", "==", businessId).get();
  userPostsSnapshot.forEach((doc) => {
    const postID = doc.data().postID;

    const postType = doc.data().postType;
    const images = doc.data().postImages || [];
    const postVideo = doc.data().postVideo;
    const videoImage = doc.data().videoImage;

    deletePost(postID, postType, images, postVideo, videoImage);
  });

  // Step 2: Delete subscribers
  deleteSubcollection(`Businesses/${businessId}/Subscribers`);
}

async function deleteBusinessContinue(businessId) {
  // Reference to the business document
  const businessRef = admin
    .firestore()
    .collection("Businesses")
    .doc(businessId);

  // Check if the business exists
  const doc = await businessRef.get();
  if (!doc.exists) {
    return { error: "Business not found." };
  }

  // Delete the business document
  await businessRef.delete();

  console.log("Business Deleted Successfully.");
  proceedOtherBusinessDataDeletion(businessId);
}

exports.deleteUserAccount = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const userId = data.userId;
    const userName = data.username;

    try {
      // Step 1: Delete Firebase Auth user
      admin.auth().deleteUser(userId);

      // Step 2: Delete User
      await deleteUser(userId);

      proceedOtherUserDeletionFunction(userId, userName);

      return {
        success: true,
        message: "User account and all associated data deleted successfully.",
      };
    } catch (error) {
      console.error("Error deleting user account:", error);
      return { error: error.message };
    }
  });
async function deleteUser(userId) {
  try {
    const userDocRef = admin.firestore().collection("Users").doc(userId);
    await userDocRef.delete();
  } catch (err) {
    console.log("Delete user ", e);
  }
}
async function deleteUserPosts(userId) {
  console.log("Start delete user posts");
  const postsRef = admin.firestore().collection("Posts");
  const userPostsSnapshot = await postsRef.where("uid", "==", userId).get();
  userPostsSnapshot.forEach((doc) => {
    const postID = doc.data().postID;
    const postType = doc.data().postType;
    const images = doc.data().postImages || [];
    const postVideo = doc.data().postVideo;
    const videoImage = doc.data().videoImage;
    deletePost(postID, postType, images, postVideo, videoImage);
  });
}

async function handleFollowersAndFollowing(userId) {
  console.log("Start handleFollowersAndFollowingtart");
  const followersRef = admin
    .firestore()
    .collection("Users")
    .doc(userId)
    .collection("Follow");
  const followersSnapshot = await followersRef.get();
  followersSnapshot.forEach(async (doc) => {
    const followerId = doc.id;
    const followingRef = admin
      .firestore()
      .collection("Users")
      .doc(followerId)
      .collection("Following")
      .doc(userId);
    const followRef = admin
      .firestore()
      .collection("Users")
      .doc(userId)
      .collection("Following")
      .doc(followerId);
    await followingRef.delete();
    await followRef.delete();
  });
}

async function deleteUserTasks(userId) {
  console.log("Start deleteUserTasks");
  const taskRef = admin.firestore().collection("Tasks");
  const userTasksSnapshot = await taskRef.where("uid", "==", userId).get();
  userTasksSnapshot.forEach((doc) => {
    doc.ref.delete();
  });
}
async function deleteUserMarketplace(userId) {
  const marketRef = admin.firestore().collection("Marketplace");
  const userMarketSnapshot = await marketRef.where("uid", "==", userId).get();
  userMarketSnapshot.forEach((doc) => {
    doc.ref.delete();
  });
}

async function removeFromFollowingsFollowers(userId) {
  console.log("Start removeFromFollowingsFollowers");
  const followingRef = admin
    .firestore()
    .collection("Users")
    .doc(userId)
    .collection("Following");
  const followingSnapshot = await followingRef.get();
  followingSnapshot.forEach(async (doc) => {
    const followingId = doc.id;
    const followersRef = admin
      .firestore()
      .collection("Users")
      .doc(followingId)
      .collection("Follow")
      .doc(userId);
    const followingRef = admin
      .firestore()
      .collection("Users")
      .doc(userId)
      .collection("Following")
      .doc(followingId);
    await followersRef.delete();
    await followingRef.delete();
  });
}

async function deleteLiveRecording(userId) {
  console.log("Start deleteLiveRecording");
  const liveRecordingDocRef = admin
    .firestore()
    .collection("LiveRecordings")
    .doc(userId);
  await liveRecordingDocRef.delete();
}

async function deleteBusiness(userId) {
  console.log("Start deleteBusiness");
  try {
    const businessRef = admin
      .firestore()
      .collection("Businesses")
      .where("uid", "==", userId);
    const snapshot = await businessRef.get();
    if (!snapshot.empty) {
      const businessDoc = snapshot.docs[0];
      const businessData = businessDoc.data();
      const businessId = businessData.businessId;
      await deleteBusinessContinue(businessId);
    } else {
      console.error("Business not found for userid");
    }
  } catch (error) {
    console.error("Error deleting business:", error);
  }
}

async function deleteProfileViews(userId) {
  console.log("Start deleteProfileViews");
  await deleteSubcollection(`Users/${userId}/ProfileViews`);
}

function proceedOtherUserDeletionFunction(userId, userName) {
  // Step 3: Delete all posts by the user
  deleteUserPosts(userId);

  // Step 4: Handle followers and following
  handleFollowersAndFollowing(userId);

  // Step 5: Delete all Tasks by the user
  deleteUserTasks(userId);

  // Step 6: Delete all Marketplace by the user
  deleteUserMarketplace(userId);

  // Step 7: Remove user from followings' followers list
  removeFromFollowingsFollowers(userId);

  // Step 8: Delete LiveRecording
  deleteLiveRecording(userId);

  // Step 9: Delete User Deeplink
  deleteDeepLink(`username/${userName}`);

  // Step 10: Delete Livestream Deeplink
  deleteDeepLink(`livestream/${userName}`);

  // Step 11: Remove Profile Views
  deleteProfileViews(userId);

  // Step 12: Delete Business
  deleteBusiness(userId);
}

// Helper function to fetch horoscope
async function fetchHoroscope(token, sign, time) {
  const url = `https://api.prokerala.com/v2/horoscope/daily?datetime=${time}&sign=${sign}`;
  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  if (!response.ok) {
    throw new Error(
      `Failed to fetch horoscope for ${sign}: ${response.statusText}`
    );
  }
  return response.json();
}

// Function to get the token
async function getHoroscopeToken() {
  const url = "https://api.prokerala.com/token";
  const params = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: "cb2d4c2f-59ae-47fc-99c1-51c34f086348", // Replace with your actual client_id
    client_secret: "kdoRXLIBhuda4O6nsF8fjKn361TWjFtabQAYxZa4", // Replace with your actual client_secret
  });

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
  });

  if (!response.ok) {
    throw new Error(`Failed to get token: ${response.statusText}`);
  }

  const data = await response.json();
  return data.access_token;
}

// Helper function to delay execution
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

exports.dailyHoroscopeUpdate = functions
  .runWith({
    timeoutSeconds: 540, // Set the function timeout to 9 minutes
    memory: "256MB", // Adjust memory as needed
  })
  .pubsub.schedule("every 24 hours")
  .timeZone("Australia/Sydney")
  .onRun(async (context) => {
    const signs = [
      ["aries", "taurus", "gemini", "cancer"],
      ["leo", "virgo", "libra", "scorpio"],
      ["sagittarius", "capricorn", "aquarius", "pisces"],
    ];

    const now = new Date();
    const formattedDate = format(now, "yyyy-MM-dd'T'HH:mm:ssxxx");
    const encodedString = encodeURIComponent(formattedDate);

    try {
      const token = await getHoroscopeToken();

      const horoscopes = {};

      for (let batch of signs) {
        for (let sign of batch) {
          try {
            const horoscope = await fetchHoroscope(token, sign, encodedString);
            horoscopes[sign] = horoscope.data.daily_prediction.prediction;
          } catch (error) {
            console.error(`Error fetching horoscope for ${sign}:`, error);
          }
        }
        // Wait for 70 seconds before proceeding to the next batch to respect the API rate limit
        await delay(70000); // 70,000 milliseconds = 1 minute and 10 seconds
      }

      await admin
        .firestore()
        .collection("Horoscopes")
        .doc("daily")
        .set(horoscopes, { merge: true });
      console.log("Updated daily horoscopes successfully");
    } catch (error) {
      console.error("Failed to update daily horoscopes:", error);
    }
  });

// Retrieve API key from Firebase Functions config (recommended for security)
const REVENUECAT_SECRET_KEY = "sk_TlwmRkfvnUpsFYXlxuegBgzLHFXrv"; // Your RevenueCat secret key
const REVENUECAT_PROJECT_ID = "5f6b8f04"; // Your RevenueCat Project ID

// Helper function to call RevenueCat v2 API and fetch subscriptions for a customer
async function getSubscriptionInfo(userId) {
  try {
    const url = `https://api.revenuecat.com/v2/projects/${REVENUECAT_PROJECT_ID}/customers/${userId}/subscriptions`;

    const response = await axios.get(url, {
      headers: {
        Authorization: `Bearer ${REVENUECAT_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
    });

    // Return the subscription info from the RevenueCat v2 API response
    return response.data.items; // 'items' array contains subscription information
  } catch (error) {
    console.error(
      `Failed to fetch subscription data for user ${userId}:`,
      error
    );
    throw error;
  }
}

// Scheduled function to run every 24 hours
exports.scheduledSubscriptionUpdate = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("Australia/Sydney")
  .onRun(async (context) => {
    try {
      // Query users with entitlementStatus as 'active' or 'trialing' and activeEntitlement as 'in.softment.monthly' or 'in.softment.yearly'
      const usersSnapshot = await admin
        .firestore()
        .collection("Users")
        .where("entitlementStatus", "in", ["active", "trialing"]) // Fetch users with 'active' or 'trialing' entitlementStatus
        .where("activeEntitlement", "in", [
          "in.softment.monthly",
          "in.softment.yearly",
        ]) // Add filter for 'monthly' and 'yearly' entitlements
        .get();

      const updatePromises = [];

      usersSnapshot.forEach((userDoc) => {
        const userId = userDoc.id;

        const isAccountDeactivate = userDoc.data().isAccountDeactivate || false;
        updatePromises.push(updateSubscription(userId, isAccountDeactivate));
      });

      // Wait for all subscription updates to complete
      await Promise.all(updatePromises);

      console.log(
        "Subscription details updated successfully for users with 'active' or 'trialing' status and 'monthly' or 'yearly' entitlements."
      );
      return null;
    } catch (error) {
      console.error("Error updating subscription details:", error);
      return null;
    }
  });

// Callable function to update subscription for a user from the client (iOS app)
exports.updateSubscriptionFromClient = functions.https.onCall(
  async (data, context) => {
    const { userId } = data; // Get userId from the client

    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be authenticated to call this function."
      );
    }

    try {
      await updateSubscription(userId, false);
      return {
        message: `Subscription updated successfully for user ${userId}`,
      };
    } catch (error) {
      console.error(`Error updating subscription for user ${userId}:`, error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update subscription"
      );
    }
  }
);

// Helper function to update subscription for a single user
// Helper function to update subscription for a single user
async function updateSubscription(userId, isAccountDeactivate) {
  try {
    const subscriptions = await getSubscriptionInfo(userId); // Fetch subscriptions array

    console.log(subscriptions);

    if (!subscriptions || subscriptions.length === 0) {
      throw new Error(`No active subscriptions found for user ${userId}`);
    }

    // Extract relevant subscription information (find an active or trialing subscription)
    const activeSubscription = subscriptions.find(
      (sub) => sub.status === "active" || sub.status === "trialing"
    );

    console.log("Active Subscriptions");

    console.log(subscriptions);

    console.log("Active Subscriptions END HERE");

    if (!activeSubscription) {
      console.log(`No active subscription for user ${userId}`);
      await admin.firestore().collection("Users").doc(userId).set(
        { entitlementStatus: "inactive" }, // Set inactive
        { merge: true }
      );
      return;
    }

    const { product_id, current_period_ends_at, status } = activeSubscription;

    // Check for entitlements with "gives_access: true"
    let activeEntitlement = null;

    // Set activeEntitlement based on the product_id
    if (product_id === "prod4af8e00dac") {
      activeEntitlement = "in.softment.monthly";
    } else if (product_id === "prod9d36d726c8") {
      activeEntitlement = "in.softment.yearly";
    }

    // Calculate expiration date and days left (ensure milliseconds are handled correctly)
    const expirationDate = current_period_ends_at
      ? new Date(current_period_ends_at)
      : null;

    let daysLeft = 0;
    if (expirationDate) {
      const currentDate = new Date();
      const diffTime = expirationDate - currentDate; // Diff in milliseconds
      daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); // Convert to days
    }

    // Check for free trial based on subscription status

    // Ensure no undefined values, use default values if undefined
    const subscriptionData = {
      activeEntitlement: activeEntitlement || null, // Default to null if no entitlement
      entitlementStatus:
        status === "active"
          ? "active"
          : status === "trialing"
          ? "trialing"
          : "inactive", // Active, trialing, or inactive
      daysLeft: daysLeft >= 0 ? daysLeft : 0, // Ensure non-negative days left
      isAccountActive: status === "active" || status === "trialing", // Only active if subscription is active or trialing
    };

    // Firestore reference for the user
    const userRef = admin.firestore().collection("Users").doc(userId);

    // Update Firestore with the subscription information
    await userRef.set(subscriptionData, { merge: true });

    // Handle account deactivation or update `isAccountActive`
    if (isAccountDeactivate) {
      await userRef.set({ isAccountActive: false }, { merge: true });
    } else {
      const isLifetime = activeEntitlement === "in.softment.lifetime";
      const isCurrentlyActive = daysLeft > 0 || isLifetime;
      await userRef.set(
        {
          isAccountActive:
            isCurrentlyActive !== undefined ? isCurrentlyActive : false,
        },
        { merge: true }
      );
    }

    console.log(`Subscription updated for user ${userId}`);
  } catch (error) {
    console.error(`Error updating subscription for user ${userId}:`, error);
  }
}

// Function to set isActive status for all posts by a specific user
async function setIsActive({ userId, isActive }) {
  const postsRef = admin.firestore().collection("Posts");

  try {
    const snapshot = await postsRef.where("uid", "==", userId).get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { isActive: isActive });
    });

    await batch.commit();
    console.log("All posts updated successfully");
  } catch (error) {
    console.error("Error updating posts:", error);
  }

  const eventRef = admin.firestore().collection("Events");

  try {
    const snapshot = await eventRef
      .where("eventOrganizerUid", "==", userId)
      .get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { isActive: isActive });
    });

    await batch.commit();
    console.log("All events updated successfully");
  } catch (error) {
    console.error("Error updating events:", error);
  }

  const marketRef = admin.firestore().collection("Marketplace");

  try {
    const snapshot = await marketRef.where("uid", "==", userId).get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { isActive: isActive });
    });

    await batch.commit();
    console.log("All Marketplace updated successfully");
  } catch (error) {
    console.error("Error updating Marketplace:", error);
  }

  const businessesRef = admin.firestore().collection("Businesses");

  try {
    const snapshot = await businessesRef.where("uid", "==", userId).get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { isActive: isActive });
    });

    await batch.commit();
    console.log("All Businesses updated successfully");
  } catch (error) {
    console.error("Error updating Businesses:", error);
  }
}

function calculateDaysLeft(subscription, currentDate) {
  let endDate = new Date(); // Default to current date as a fallback
  let isDuringTrial =
    subscription.trialPeriod &&
    new Date(subscription.createdAt).getTime() +
      subscription.trialDuration * 24 * 60 * 60 * 1000 >
      currentDate.getTime();

  // If during trial, calculate the trial end date based on the createdAt date and trialDuration
  if (isDuringTrial) {
    const createdAt = new Date(subscription.createdAt);
    const trialDuration = subscription.trialDuration; // Assuming trialDuration is in days
    endDate = new Date(
      createdAt.getTime() + trialDuration * 24 * 60 * 60 * 1000
    );
  } else if (subscription.paidThroughDate) {
    // After trial, use paidThroughDate as the end date
    endDate = new Date(subscription.paidThroughDate);
  } else if (subscription.nextBillingDate) {
    // Alternatively, use nextBillingDate as the endDate if paidThroughDate is not available
    endDate = new Date(subscription.nextBillingDate);
  }

  const daysLeft = Math.ceil((endDate - currentDate) / (1000 * 60 * 60 * 24));
  return { daysLeft, isDuringTrial };
}

exports.getCouponModelBy = functions.https.onCall(async (data, context) => {
  const couponId = data.couponId;

  try {
    const snapshot = await admin
      .firestore()
      .collection("Coupons")
      .doc(couponId)
      .get();
    if (snapshot.exists) {
      const couponModel = snapshot.data();
      return { couponModel };
    } else {
      return { couponModel: null };
    }
  } catch (error) {
    console.error("Error getting document:", error);
    return { couponModel: null };
  }
});

exports.reportComment = functions.https.onCall(async (data, context) => {
  const { reason, commentID, postId } = data;

  if (!context.auth) {
    // Authentication / user information is required.
    return {
      success: false,
      message: "The function must be called while authenticated.",
    };
  }

  const uid = context.auth.uid;
  const id = admin.firestore().collection("CommentReports").doc().id;

  const reportData = {
    id: id,
    reason: reason,
    createDate: admin.firestore.FieldValue.serverTimestamp(),
    uid: uid,
    commentId: commentID,
    postId: postId,
  };

  try {
    await admin
      .firestore()
      .collection("CommentReports")
      .doc(id)
      .set(reportData);
    return {
      success: true,
      message:
        "Your report has been submitted. We will review this comment and take action within 24 hours.",
    };
  } catch (error) {
    console.error("Error reporting comment:", error);
    return {
      success: false,
      message: "An error occurred while submitting your report.",
    };
  }
});

exports.reportPost = functions.https.onCall(async (data, context) => {
  const { reason, postID } = data;

  if (!context.auth) {
    // Authentication / user information is required.
    return {
      success: false,
      message: "The function must be called while authenticated.",
    };
  }

  const uid = context.auth.uid;
  const id = admin.firestore().collection("Reports").doc().id;

  const reportData = {
    id: id,
    reason: reason,
    createDate: admin.firestore.FieldValue.serverTimestamp(),
    uid: uid,
    postId: postID,
  };

  try {
    await admin.firestore().collection("Reports").doc(id).set(reportData);
    return {
      success: true,
      message:
        "Your report has been submitted. We will review this post and take action within 24 hours.",
    };
  } catch (error) {
    console.error("Error reporting post:", error);
    return {
      success: false,
      message: "An error occurred while submitting your report.",
    };
  }
});

exports.sendVOIPNotification = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "1GB",
  })
  .https.onCall(async (data, context) => {
    console.log("Received data: ", data);

    // Validate input
    if (
      !data.deviceToken ||
      !data.name ||
      !data.channelName ||
      !data.token ||
      !data.callUUID
    ) {
      console.error("Missing required parameters");
      return { response: "failed", value: "Missing required parameters" };
    }

    // Configuration for APN (ensure certificates are in correct path)
    const config = {
      cert: "./certificates.pem", // Path to your cert.pem
      key: "./key.pem", // Path to your key.pem
      production: true, // Set to false if using APNs sandbox
    };

    console.log("APN configuration: ", config);

    // Create APN provider
    const apnProvider = new apn.Provider(config);

    // Create a new APN notification
    const notification = new apn.Notification();
    notification.topic = "in.softment.myMink.voip"; // Make sure this is the correct topic
    notification.payload = {
      messageFrom: data.name,
      channelName: data.channelName,
      token: data.token,
      callEnd: data.callEnd,
      callUUID: data.callUUID,
    };

    console.log("APN notification payload: ", notification.payload);

    const recepients = [apn.token(data.deviceToken)];
    console.log("Sending notification to deviceToken: ", recepients);

    try {
      const result = await apnProvider.send(notification, recepients);
      console.log("APN result: ", result);

      if (result.failed.length > 0) {
        console.error("Failed to send notification: ", result.failed);
        return { response: "failed", value: "Failed to send notification" };
      } else {
        console.log("Notification sent successfully");
        return { response: "success", value: "Notification sent successfully" };
      }
    } catch (error) {
      console.error("Error while sending notification: ", error);
      return { response: "failed", value: "Error while sending notification" };
    } finally {
      apnProvider.shutdown(); // Ensure APN provider is shut down properly
    }
  });

exports.startAgoraWebHook = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "1GB",
  })
  .https.onCall(async (data, context) => {
    const channelName = data.channelName;
    const token = data.token;

    let min = 1;
    let max = 999999999;
    let randomInt = (
      Math.floor(Math.random() * (max - min + 1)) + min
    ).toString();

    return handleEvent101(channelName, randomInt, token);
  });

// Create authorization header
const authorizationHeader =
  "Basic Mjk0YjMzNmY4MzM2NGVmY2EzODMyNTM5YjAyMDg0ZTQ6NDA5ZDJhODhmNTY5NDBhZmJiYjVjZGViNTg5YzAxYjk=";

// Cloud Recording
async function startCloudRecording(channelName, uid, resouceId, token) {
  var data = JSON.stringify({
    cname: `${channelName}`,
    uid: `${uid}`,
    clientRequest: {
      token: `${token}`,
      recordingConfig: {
        channelType: 1,
        streamTypes: 2,
        videoStreamType: 0,
        streamMode: "standard",
        maxIdleTime: 0,
        quality: "high",
        subscribeVideoUids: ["#allstream#"],
        subscribeAudioUids: ["#allstream#"],
        subscribeUidGroup: 0,
      },
      snapshotConfig: {
        captureInterval: 3599,
        fileType: ["jpg"],
      },
      recordingFileConfig: {
        avFileType: ["hls"],
      },
      storageConfig: {
        vendor: 1,
        region: 0,
        bucket: "myminkbucket190931-myminkapp",
        accessKey: "AKIAVRLFHTFVWD6EVLV7",
        secretKey: "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",
        fileNamePrefix: ["public", "LiveStream"],
      },
    },
  });

  var config = {
    method: "post",
    maxBodyLength: Infinity,
    url: `https://api.agora.io/v1/apps/107d8337cdc34ecca9be641fed1809da/cloud_recording/resourceid/${resouceId}/mode/mix/start`,
    headers: {
      "Content-Type": "application/json",
      Authorization: authorizationHeader,
    },
    data: data,
  };
  try {
    const response = await axios(config);
    console.log("STARTED ", response.data);
    return response.data.sid;
  } catch (error) {
    console.log("This is ERROR", error);
  }
}

async function stopCloudRecording(channelName, uid, resouceId, sid) {
  var data = `{
    "cname": "${channelName}",
    "uid": "${uid}",
    "clientRequest": {}
}`;

  var config = {
    method: "post",
    maxBodyLength: Infinity,
    url: `https://api.agora.io/v1/apps/107d8337cdc34ecca9be641fed1809da/cloud_recording/resourceid/${resouceId}/sid/${sid}/mode/mix/stop`,
    headers: {
      "Content-Type": "application/json;charset=utf-8",
      Authorization: authorizationHeader,
    },
    data: data,
  };
  console.log("CloudRecording Stop");
  try {
    const response = await axios(config);
    console.log(response);
  } catch {
    console.log(error);
  }
}

async function getCloudResourceId(channelName, uid) {
  var data = JSON.stringify({
    cname: channelName,
    uid: uid,
    clientRequest: {},
  });

  var config = {
    method: "post",
    maxBodyLength: Infinity,
    url: "https://api.agora.io/v1/apps/107d8337cdc34ecca9be641fed1809da/cloud_recording/acquire",
    headers: {
      "Content-Type": "application/json",
      Authorization: authorizationHeader,
    },
    data: data,
  };

  const response = await axios(config);
  return response.data.resourceId;
}

exports.createCustomToken = functions.https.onCall((data, context) => {
  // Extract UID from the data
  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid UID."
    );
  }

  // Create a custom token
  return admin
    .auth()
    .createCustomToken(uid)
    .then((customToken) => {
      return { token: customToken };
    })
    .catch((error) => {
      console.error("Error creating custom token:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Error creating custom token."
      );
    });
});
exports.setEmailVerified = functions.https.onCall((data, context) => {
  // Check if the request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can update email verification status."
    );
  }

  // You can also add additional checks here to restrict who can call this function
  // ...

  const userId = data.userId;
  if (!userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      'The function must be called with one argument "userId".'
    );
  }

  return admin
    .auth()
    .updateUser(userId, {
      emailVerified: true,
    })
    .then(() => {
      return {
        message: "Email verification status set to true for user: " + userId,
      };
    })
    .catch((error) => {
      console.error("Error updating user:", error);
      throw new functions.https.HttpsError("unknown", "Failed to update user");
    });
});

exports.sendTaskReminders = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context) => {
    const now = new Date();
    const tasksRef = admin.firestore().collection("Tasks");

    try {
      const tasksSnapshot = await tasksRef
        .where("isFinished", "==", false)
        .where("date", ">", now)
        .get();

      for (const taskDoc of tasksSnapshot.docs) {
        const task = taskDoc.data();
        console.log(task);

        if (!task.date) continue; // Skip if the task has no due date

        const taskDate = task.date.toDate(); // Convert Firestore Timestamp to JavaScript Date object
        const timeDiff = taskDate - now; // Difference in milliseconds

        // Convert differences to more manageable units
        const diffMIN = timeDiff / (1000 * 60); // Difference in minutes
        console.log(diffMIN);

        let shouldNotify = false;
        let notificationBody = "";

        // Determine when to notify based on time difference
        if (diffMIN > 2879 && diffMIN < 2881) {
          notificationBody = `Your task "${task.title}" is due in 2 days.`;
          shouldNotify = true;
        } else if (diffMIN > 1439 && diffMIN < 1441) {
          notificationBody = `Your task "${task.title}" is due in 1 day.`;
          shouldNotify = true;
        } else if (diffMIN > 59 && diffMIN < 61) {
          notificationBody = `Your task "${task.title}" is due in 1 hour.`;
          shouldNotify = true;
        }

        // Only proceed if a notification should be sent
        if (shouldNotify && task.uid) {
          const userRef = admin.firestore().collection("Users").doc(task.uid);
          const userDoc = await userRef.get();

          if (!userDoc.exists) {
            console.log(`User not found for UID: ${task.uid}`);
            continue;
          }

          const user = userDoc.data();

          // Check if user has a notification token
          if (!user.notificationToken) {
            console.log(`No notification token for user UID: ${task.uid}`);
            continue;
          }

          // Create the message payload
          const message = {
            notification: {
              title: "Task Reminder",
              body: notificationBody,
            },
            token: user.notificationToken,
          };

          try {
            // Send the notification
            const response = await admin.messaging().send(message);
            console.log("Successfully sent message:", response);
          } catch (error) {
            console.error("Error sending message:", error);
          }
        }
      }
    } catch (error) {
      console.error("Failed to send task reminders:", error);
      // Handle or log the error appropriately
    }
  });

async function handleEvent101(channelName, randomInt, token) {
  const rId = await getCloudResourceId(channelName, randomInt);
  const sId = await startCloudRecording(channelName, randomInt, rId, token);

  const docRef = db.collection("LiveStreamings").doc(channelName);
  docRef
    .set(
      {
        rId,
        sId,
        randomInt,
        channelName,
      },
      { merge: true }
    )
    .then(() => console.log("CLOUDRECORDING INFO ADDED"))
    .catch((error) => console.error("Error CLOUDRECORDING INFO:", error));

  return { response: "finished!" };
}

// Agora LiveSteaming
const app = express();
app.use(bodyParser.json());

app.post("/agora-webhook", (req, res) => {
  const data = req.body;

  if (data["eventType"] == 104) {
    const channelName = data.payload.channelName;

    const docRef = db.collection("LiveStreamings").doc(channelName);

    console.log("IN EVENT TYPE 105");

    docRef
      .get()
      .then((doc) => {
        if (!doc.exists) {
          console.log("No such document!");
        } else {
          docRef
            .delete()
            .then(() => {
              console.log("Document successfully deleted!");
            })
            .catch((error) => {
              console.error("Error removing document: ", error);
            });

          docRef
            .collection("Chats")
            .get()
            .then((snapshot) => {
              snapshot.forEach((doc) => {
                docRef.collection("Chats").doc(doc.data().id).delete();
              });
            })
            .catch((error) => {
              console.log("Error getting documents", error);
            });

          docRef
            .collection("Audiences")
            .get()
            .then((snapshot) => {
              snapshot.forEach((doc) => {
                docRef.collection("Audiences").doc(doc.data().id).delete();
              });
            })
            .catch((error) => {
              console.log("Error getting documents", error);
            });

          stopCloudRecording(
            channelName,
            doc.data().randomInt,
            doc.data().rId,
            doc.data().sId
          );
        }
      })
      .catch((err) => {
        console.log("Error getting document", err);
      });
  } else if (data["eventType"] == 105) {
    const channelName = data.payload.channelName;
    const uid = data.payload.uid;

    const docRef = db
      .collection("LiveStreamings")
      .doc(channelName)
      .collection("Audiences")
      .doc(uid.toString());

    docRef
      .set(
        {
          uid,
        },
        { merge: true }
      )
      .then(() => console.log("Count incremented successfully"))
      .catch((error) => console.error("Error incrementing count:", error));
  } else if (data["eventType"] == 106) {
    const channelName = data.payload.channelName;
    const uid = data.payload.uid;

    const docRef = db
      .collection("LiveStreamings")
      .doc(channelName)
      .collection("Audiences")
      .doc(uid.toString());
    docRef
      .delete()
      .then(() => {
        console.log("Count successfully deleted!");
      })
      .catch((error) => {
        console.error("Error removing Count: ", error);
      });
  } else if (data["eventType"] == 4) {
    console.log("VIDEO_INFORMATION ", data);
    const sId = data.sid;
    const channelName = data.payload.cname;
    const video = data.payload.details.fileList;

    let step1 = video.replace(/public\//, "");
    let step2 = step1.replace(/_video/, "");
    let finalVideo = step2.replace(/_audio/, "");
    db.collection("LiveRecordings")
      .doc(channelName)
      .set(
        { channelName, video: finalVideo, time: new Date(), sId },
        { merge: true }
      );
  } else if (data["eventType"] == 45) {
    const channelName = data.payload.cname;
    const mThumbnail = data.payload.details.fileName;
    let final = mThumbnail.replace(/public\//, "");
    db.collection("LiveRecordings")
      .doc(channelName)
      .set({ thumbnail: final }, { merge: true });
  }
  return res.status(200).send("GREAT");
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

exports.myWebhook = functions.https.onRequest(app);

const firestore = require("@google-cloud/firestore");
const { de } = require("date-fns/locale");
const e = require("express");
const firebaseclient = new firestore.v1.FirestoreAdminClient();
// Replace BUCKET_NAME
const bucket = "gs://mymink-backup";

exports.scheduledFirestoreExport = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const projectId = process.env.GCP_PROJECT || "my-mink";
    const databaseName = firebaseclient.databasePath(projectId, "(default)");

    try {
      const responses = await firebaseclient.exportDocuments({
        name: databaseName,
        outputUriPrefix: bucket,
        // Leave collectionIds empty to export all collections
        // or set to a list of collection IDs to export,
        // collectionIds: ['users', 'posts']
        collectionIds: [],
      });
      const response = responses[0];
      console.log(`Operation Name: ${response["name"]}`);
      return;
    } catch (err) {
      console.error(err);
      throw new Error("Export operation failed");
    }
  });
