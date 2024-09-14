
import { Hono } from "hono";
import { handle } from "hono/aws-lambda";

// ** import middlewares
import { cors } from "hono/cors";
import { logger } from "hono/logger";

// ** import routes
import { getChrome } from "./config/chrome-script";


// Initialize Hono app
const app = new Hono({ strict: false });

/**
 * Middlewares
 * https://hono.dev/middleware/builtin/cors
 */
app.use("*", logger());
app.use("*", cors());


app.get("/", async (c) => {
  return c.json({ message: "Hello World" });
});

app.get("/screenshot", async (c) => {
  const url = c.req.query("url");

  if (!url) {
    return c.json({ error: "No URL provided" }, 400);
  }

  let page, browser;

  try {
    // Use the getChrome function to launch the browser and get the page object
    const chrome = await getChrome(url);

    browser = chrome.browser;
    page = chrome.page;
    // chromeInstance = chrome.instance; // Only for serverless Chrome

    // Take a screenshot of the page
    const screenshot = await page.screenshot({ encoding: 'base64' });

    console.log("Screenshot captured successfully");

    // Return the screenshot as an image with appropriate headers
    return c.html(`<img src="data:image/png;base64,${screenshot}">`, 200);
  } catch (error) {
    console.error("Error capturing screenshot: ", error);
    return c.json({ error: "Failed to capture screenshot" }, 500);
  } finally {
    // Clean up the browser and page instances
    if (page) await page.close();
    if (browser) await browser.close();
  }
});


// Start the server (Local or AWS Lambda)
export const handler = handle(app);
