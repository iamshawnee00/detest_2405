/**
 * Dyme Eat: The Legacy Engine - Cloud Functions (v2 SDK)
 *
 * This file contains the backend logic for aggregating reviews, awarding Influence Points (IP),
 * and managing other server-side tasks for the application, updated to use the Firebase Functions v2 SDK.
 */

// v2 Imports
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * ==========================================================================================
 * TASTE DIAL & REVIEW FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered whenever a new review is written. It performs three main actions:
 * 1. Awards +25 IP to the author of the review.
 * 2. Triggers the aggregation of taste data for the associated restaurant.
 * 3. Checks if the user has met the criteria for the Revelation Event.
 */

export const onreviewcreated = onDocumentCreated("reviews/{reviewId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the review event.");
        return;
    }
    const reviewData = snap.data();

    const { authorId, restaurantId } = reviewData;

    if (!authorId || !restaurantId) {
        logger.error("Review is missing authorId or restaurantId.");
        return;
    }

    // --- 1. Award Influence Points (IP) for the review ---
    const userRef = db.collection("users").doc(authorId);
    await userRef.update({
      influencePoints: admin.firestore.FieldValue.increment(25),
    });
    logger.log(`Awarded +25 IP to user ${authorId} for new review.`);

    // --- 2. Recalculate and update the restaurant's Taste Signature ---
    await recalculateTasteSignature(restaurantId);

    // --- 3. Check for Foodie Personality Revelation Event ---
    await checkForRevelationEvent(authorId);
});

/**
 * Recalculates the `overallTasteSignature` for a given restaurant.
 * This function reads all reviews for the restaurant, computes the average for each
 * taste dial metric, and saves the result to the restaurant's document.
 *
 * @param {string} restaurantId The ID of the restaurant to update.
 */
async function recalculateTasteSignature(restaurantId: string) {
  const restaurantRef = db.collection("restaurants").doc(restaurantId);

  // Get all reviews for this restaurant
  const reviewsSnapshot = await db
    .collection("reviews")
    .where("restaurantId", "==", restaurantId)
    .get();

  if (reviewsSnapshot.empty) {
    console.log(`No reviews found for restaurant ${restaurantId}. Resetting signature.`);
    await restaurantRef.update({ overallTasteSignature: {} });
    return;
  }

  // --- Aggregate all taste dial data from reviews ---
  const signature: { [key: string]: number } = {};
  const counts: { [key: string]: number } = {};
  let totalReviews = 0;

  reviewsSnapshot.forEach((doc) => {
    const reviewData = doc.data();
    const tasteDialData = reviewData.tasteDialData as { [key: string]: number };

    if (tasteDialData) {
      totalReviews++;
      for (const key in tasteDialData) {
        if (Object.prototype.hasOwnProperty.call(tasteDialData, key)) {
          const value = tasteDialData[key];
          signature[key] = (signature[key] || 0) + value;
          counts[key] = (counts[key] || 0) + 1;
        }
      }
    }
  });

  // --- Calculate the average for each metric ---
  const newTasteSignature: { [key: string]: number } = {};
  for (const key in signature) {
    if (Object.prototype.hasOwnProperty.call(signature, key)) {
      newTasteSignature[key] = signature[key] / counts[key];
    }
  }

  // Add metadata about the number of reviews
  newTasteSignature._reviewCount = totalReviews;

  // --- Update the restaurant document in Firestore ---
  await restaurantRef.update({
    overallTasteSignature: newTasteSignature,
  });

  console.log(
    `Successfully updated taste signature for restaurant ${restaurantId}`,
  );
}


/**
 * ==========================================================================================
 * PATHFINDER TIP FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered when a pathfinderTip document is updated (e.g., upvoted).
 * Checks if a tip has reached the verification threshold and awards IP if it has.
 */
export const onpathfindertipupdate = onDocumentUpdated("pathfinderTips/{tipId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the tip update event.");
        return;
    }
    const newData = snap.after.data();
    const oldData = snap.before.data();
    
    if (newData.upvotes === oldData.upvotes || newData.isVerified) {
        return;
    }

    const VERIFICATION_THRESHOLD = 3;

    if (newData.upvotes >= VERIFICATION_THRESHOLD) {
        const tipId = snap.after.id;
        const authorId = newData.authorId;
        if (!authorId) {
            logger.error(`Tip ${tipId} has no authorId.`);
            return;
        }
        const tipRef = db.collection("pathfinderTips").doc(tipId);
        await tipRef.update({ isVerified: true });
        const userRef = db.collection("users").doc(authorId);
        await userRef.update({
            influencePoints: admin.firestore.FieldValue.increment(15),
        });
        logger.log(`Tip ${tipId} verified. Awarded +15 IP to user ${authorId}.`);
    }
});


/**
 * ==========================================================================================
 * FOODIE PERSONALITY & REVELATION EVENT (NEW)
 * ==========================================================================================
 */

const REVELATION_THRESHOLD = 15; // Number of reviews needed to trigger the event

/**
 * Checks if a user has met the conditions for the Foodie Personality Revelation Event.
 * @param {string} userId The ID of the user to check.
 */
async function checkForRevelationEvent(userId: string) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  // Stop if the user doesn't exist or their crest has already been revealed.
  if (!userData || userData.foodieCrestRevealed) {
    return;
  }

  // Count the number of reviews the user has submitted.
  const reviewsSnapshot = await db
    .collection("reviews")
    .where("authorId", "==", userId)
    .get();
  const reviewCount = reviewsSnapshot.size;

  console.log(`User ${userId} has ${reviewCount} reviews.`);

  // If the user meets the threshold, trigger the analysis.
  if (reviewCount >= REVELATION_THRESHOLD) {
    console.log(`User ${userId} has met the revelation threshold. Analyzing...`);
    await analyzeAndAssignFoodiePersonality(userId, reviewsSnapshot);
  }
}

/**
 * Analyzes a user's review history to determine their 4-letter Foodie Personality,
 * awards them IP, and sets the `foodieCrestRevealed` flag.
 * @param {string} userId The user to analyze.
 * @param {FirebaseFirestore.QuerySnapshot} reviewsSnapshot The user's reviews.
 */
async function analyzeAndAssignFoodiePersonality(
  userId: string,
  reviewsSnapshot: FirebaseFirestore.QuerySnapshot,
) {
  const totals: { [key: string]: number } = {};
  const counts: { [key: string]: number } = {};

  // Aggregate all taste dial data from the user's reviews
  reviewsSnapshot.forEach((doc) => {
    const review = doc.data();
    if (review.tasteDialData) {
        const tasteData = review.tasteDialData as { [key: string]: number };
        for (const key in tasteData) {
          totals[key] = (totals[key] || 0) + tasteData[key];
          counts[key] = (counts[key] || 0) + 1;
        }
    }
  });

  // Calculate averages
  const averages: { [key: string]: number } = {};
  for (const key in totals) {
    averages[key] = totals[key] / counts[key];
  }

  // --- Determine the 4-Letter Personality Type (Simplified Logic) ---
  let personality = "";

  // 1st Letter: Primary Flavor Profile (R-Richness vs S-Spiciness)
  personality += (averages["Richness"] || 0) > (averages["Spiciness"] || 0) ? "R" : "S";

  // 2nd Letter: Intensity (I-Intense, M-Moderate)
  const overallAverage =
    Object.values(averages).reduce((sum, val) => sum + val, 0) /
    (Object.keys(averages).length || 1);
  personality += overallAverage > 3.5 ? "I" : "M";

  // 3rd Letter: Sweet or Savory (S-Sweet, V-Savory)
  personality += (averages["Sweetness"] || 0) > 3.0 ? "S" : "V";

  // 4th Letter: Nuance (N-Nuanced, B-Bold) - based on variance of ratings
  const allValues = reviewsSnapshot.docs
    .flatMap(
      (doc) => Object.values(doc.data().tasteDialData || {}) as number[],
    );
  const variance = getVariance(allValues);
  personality += variance > 2.0 ? "B" : "N"; // High variance = Bold, Low = Nuanced


  // --- Update User Document in Firestore ---
  const userRef = db.collection("users").doc(userId);
  await userRef.update({
    foodiePersonality: personality,
    foodieCrestRevealed: true,
    influencePoints: admin.firestore.FieldValue.increment(500), // The grand prize!
  });

  console.log(
    `Revelation for user ${userId}! Personality: ${personality}. Awarded +500 IP.`,
  );
}

/**
 * Helper function to calculate variance for an array of numbers.
 * @param {number[]} numbers The array of numbers.
 * @return {number} The variance.
 */
function getVariance(numbers: number[]): number {
  if (numbers.length < 2) return 0;
  const mean = numbers.reduce((a, b) => a + b, 0) / numbers.length;
  const squareDiffs = numbers.map((value) => (value - mean) ** 2);
  return squareDiffs.reduce((a, b) => a + b, 0) / numbers.length;
  return 0;
}  


/**
 * ==========================================================================================
 * RESTAURANT SUBMISSION FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * Triggered when a new restaurant suggestion is created.
 * This function currently serves as a placeholder for logging. The IP award
 * will happen when an admin approves the submission.
 */
export const onRestaurantSuggestionCreated = onDocumentCreated("submittedRestaurants/{submissionId}", (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the restaurant suggestion event.");
        return;
    }
    const submissionData = snap.data();
    logger.log("New restaurant suggestion received:", submissionData.name);
    logger.log("Awaiting admin approval.");
    });

/**
 * Triggered when a submitted restaurant's status changes.
 * If an admin changes the status to 'approved', this function moves the data
 * to the public 'restaurants' collection and awards +100 IP to the submitter.
 */
export const onRestaurantSuggestionUpdate = functions.firestore
    .document("submittedRestaurants/{submissionId}")
    .onUpdate(async (change) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Check if the status has changed to 'approved'
        if (newData.status === "approved" && oldData.status !== "approved") {
            const { name, address, location, city, state, submittedBy, cuisineTags } = newData;
            
            if (!submittedBy) {
                console.error("Approved submission is missing a 'submittedBy' UID.");
                return null;
            }

            // 1. Create a new document in the public 'restaurants' collection
            await db.collection("restaurants").add({
                name,
                address,
                location, // This is already a GeoPoint
                city: city || "",
                state: state || "",
                cuisineTags: cuisineTags || [],
                overallTasteSignature: {}, // Initialize with empty signature
                createdBy: submittedBy,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 2. Award +100 IP to the user who submitted it
            const userRef = db.collection("users").doc(submittedBy);
            await userRef.update({
                influencePoints: admin.firestore.FieldValue.increment(100),
            });
            
            console.log(`Approved restaurant '${name}'. Awarded +100 IP to user ${submittedBy}.`);
        }
        
        return null;
    });


/**
 * ==========================================================================================
 * GROUP MODULE FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * A callable function that allows a user to create a new group.
 * It ensures the user is authenticated and adds them as the first member and creator.
 */
export const createGroup = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    const groupName = data.name;

    if (!uid) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to create a group."
        );
    }

    if (!groupName || typeof groupName !== "string" || groupName.length > 50) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Group name must be a string up to 50 characters."
        );
    }

    const groupRef = db.collection("groups").doc();

    await groupRef.set({
        name: groupName,
        createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        members: [uid], // Add the creator as the first member
        tasteSignature: {},
        allergies: {},
    });

    return { groupId: groupRef.id };
});    


/**
 * ==========================================================================================
 * FOODIE CARD FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * A callable function that generates the data payload for a user's Foodie Card.
 * This data can be used to generate a QR code on the client.
 */
export const generateFoodieCardData = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;

    if (!uid) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to generate a Foodie Card."
        );
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found.");
    }
    const userData = userDoc.data()!;

    // --- Analyze reviews to find top flavors and restaurants ---
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", uid).get();
    
    // Find Top 3 Flavors
    const flavorCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            Object.keys(review.tasteDialData).forEach((key) => {
                flavorCounts[key] = (flavorCounts[key] || 0) + 1;
            });
        }
    });
    const topFlavors = Object.entries(flavorCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([key]) => key);

    // Find Top 3 Reviewed Restaurants (as a proxy for top restaurants)
    const restaurantCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const restaurantId = doc.data().restaurantId;
        restaurantCounts[restaurantId] = (restaurantCounts[restaurantId] || 0) + 1;
    });
    const topRestaurantIds = Object.entries(restaurantCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([key]) => key);
    
    // We would typically fetch restaurant names here, but for QR data, IDs are sufficient.

    // --- Construct the data payload ---
    const cardData = {
        userId: uid,
        name: userData.displayName,
        crest: userData.foodiePersonality,
        ip: userData.influencePoints,
        topFlavors: topFlavors,
        topRestaurants: topRestaurantIds, // Using IDs for data efficiency
    };

    // The client will stringify this JSON for the QR code
    return cardData;
});


/**
 * ==========================================================================================
 * RITUALS & STORIES FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * Triggered when a new story/ritual is created.
 * This is a high-value contribution that requires manual admin approval.
 * The IP reward (+100 to +500) will be granted by an admin.
 */
export const onStoryCreated = functions.firestore
    .document("stories/{storyId}")
    .onCreate((snap) => {
        const storyData = snap.data();
        console.log(`New story/ritual submitted for restaurant ${storyData.restaurantId} by user ${storyData.authorId}.`);
        console.log("Awaiting admin approval for IP reward.");
        return null;
    });


/**
 * ==========================================================================================
 * WALLET INTEGRATION (PKPASS) FUNCTIONS (CORRECTED)
 * ==========================================================================================
 */

/**
 * Prepares the data payload required to generate a .pkpass file for Apple Wallet.
 *
 * NOTE: This function *prepares* the data. A separate, dedicated service with access
 * to Apple's signing certificates is required to perform the actual .pkpass
 * file creation and signing. This function returns the JSON that service would need.
 *
 * @returns {object} An object containing the pass data and a placeholder URL.
 */
export const generatePkpassData = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;

    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User data not found.");
    }
    const userData = userDoc.data()!;

    // --- (FIXED) Analyze reviews to find top flavors and restaurants ---
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", uid).get();
    
    // Find Top 3 Flavors by frequency of rating
    const flavorCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            Object.keys(review.tasteDialData).forEach((key) => {
                flavorCounts[key] = (flavorCounts[key] || 0) + 1;
            });
        }
    });
    const topFlavors = Object.entries(flavorCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([key]) => key);


    // This data structure mirrors the fields you would define in a pass.json file.
    const passJson = {
        formatVersion: 1,
        passTypeIdentifier: "pass.com.dyme.eat.foodie-card", // Your Pass Type ID from Apple
        serialNumber: `DYME-${uid.substring(0, 10)}`,
        teamIdentifier: "YOUR_TEAM_ID", // Your Apple Developer Team ID
        organizationName: "Dyme Eat",
        description: "Dyme Eat Foodie Card",
        logoText: "Dyme Eat",
        foregroundColor: "rgb(255, 255, 255)",
        backgroundColor: "rgb(30, 30, 30)",
        labelColor: "rgb(180, 180, 180)",
        storeCard: {
            primaryFields: [
                {
                    key: "name",
                    label: "FOODIE",
                    value: userData.displayName || "N/A",
                },
            ],
            secondaryFields: [
                {
                    key: "crest",
                    label: "FOODIE CREST",
                    value: userData.foodiePersonality || "Not Revealed",
                },
            ],
            auxiliaryFields: [
                {
                    key: "ip",
                    label: "INFLUENCE",
                    value: `${userData.influencePoints || 0} IP`,
                },
            ],
            backFields: [
                {
                    key: "userId",
                    label: "User ID",
                    value: uid,
                },
                // (FIXED) Added Top Flavors to the back of the pass
                {
                    key: "topFlavors",
                    label: "TOP FLAVORS",
                    value: topFlavors.join(", ") || "Not yet rated",
                },
                {
                    key: "info",
                    label: "About",
                    value: "This card represents your unique taste profile in the Dyme Eat ecosystem. Share it to connect with other foodies!",
                },
            ],
        },
        barcode: {
            message: JSON.stringify({ userId: uid }),
            format: "PKBarcodeFormatQR",
            messageEncoding: "iso-8859-1",
        },
    };

    // In a real implementation, you would send this `passJson` to your signing service.
    // Here, we return a success message and a placeholder for the download URL.
    return {
        success: true,
        message: "Pass data generated successfully.",
        // This URL would point to your signing service which returns the .pkpass file.
        downloadUrl: `https://your-pkpass-service.com/generate?data=${encodeURIComponent(JSON.stringify(passJson))}`,
    };
});

