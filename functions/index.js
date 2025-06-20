/**
 * You would deploy this code to your Firebase project.
 * Ensure you have initialized Firebase Functions in your project.
 * From your project root, you'd typically run:
 * `firebase init functions` (if you haven't already)
 * Then, place this code in `functions/index.js`
 * and run `firebase deploy --only functions`
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * A callable Cloud Function to generate restaurant suggestions for a group.
 * @param {object} data The data passed to the function.
 * @param {string} data.groupId The ID of the group to get suggestions for.
 * @param {functions.https.CallableContext} context The context of the call.
 */
exports.suggestForGroup = functions
    .region("asia-southeast1")
    .https.onCall(async (data, context) => {
    // Check if the user is authenticated.
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
      }

      const groupId = data.groupId;
      if (!groupId || typeof groupId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a valid 'groupId' string.",
        );
      }

      try {
      // 1. Get the group's data
        const groupDoc = await db.collection("groups").doc(groupId).get();
        if (!groupDoc.exists) {
          throw new functions.https.HttpsError(
              "not-found",
              `Group with ID ${groupId} not found.`,
          );
        }
        const groupData = groupDoc.data();
        const preferences = groupData.groupPreferences || [];

        if (preferences.length === 0) {
          return {
            success: true,
            suggestions: [],
            reasoning: "Group has no preferences set. Add some to get suggestions!",
          };
        }

        // 2. Query for restaurants based on group preferences
        const restaurantsSnapshot = await db
            .collection("restaurants")
            .where("cuisineTypes", "array-contains-any", preferences)
            .limit(50)
            .get();

        if (restaurantsSnapshot.empty) {
          return {
            success: true,
            suggestions: [],
            reasoning: `Couldn't find any restaurants matching your group's ` +
            `preferences: ${preferences.join(", ")}.`,
          };
        }

        const potentialRestaurants = [];
        restaurantsSnapshot.forEach((doc) => {
          potentialRestaurants.push(doc.data());
        });

        // 3. Rank the results (simulated AI ranking)
        potentialRestaurants.sort((a, b) => {
          const ratingA = a.ratingGoogle || 0;
          const ratingB = b.ratingGoogle || 0;
          return ratingB - ratingA; // Sort descending
        });

        // 4. Select the top N suggestions
        const topSuggestions = potentialRestaurants.slice(0, 3);

        // 5. Format the response to match RestaurantModel in Flutter
        const formattedSuggestions = topSuggestions.map((resto) => ({
          id: resto.id || "",
          name: resto.name || "",
          images: (resto.images && resto.images.length > 0) ? resto.images : [],
          ratingGoogle: resto.ratingGoogle || 0,
          cuisineTypes: resto.cuisineTypes || [],
          address: resto.address || "",
          description: resto.description || "",
          latitude: resto.latitude || 0.0,
          longitude: resto.longitude || 0.0,
          openingHours: resto.openingHours || "Not available",
          phoneNumber: resto.phoneNumber || null,
          website: resto.website || null,
        }));

        return {
          success: true,
          suggestions: formattedSuggestions,
          reasoning: `Based on your group's love for ` +
          `${preferences.join(" & ")}, here are some top-rated options!`,
        };
      } catch (error) {
        console.error("Error in suggestForGroup function:", error);
        throw new functions.https.HttpsError(
            "internal",
            "An error occurred while generating suggestions.",
            error,
        );
      }
    });
