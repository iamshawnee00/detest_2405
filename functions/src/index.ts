import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

/**
 * A simple "Hello World" HTTP Cloud Function.
 *
 * This function will be accessible via a URL and will respond
 * with a JSON message.
 */
export const helloWorld = onRequest((request, response) => {
  // Use the 'logger' to print a log to the Firebase console
  logger.info("Hello World function was called!", {structuredData: true});

  // Send a response back to the user
  response.status(200).json({
    message: "Hello from your first TypeScript Firebase Function!",
  });
});