// @ts-ignore
import chromium from "@sparticuz/chromium";
import puppeteer from "puppeteer-core";
import os from "os";
import path from "path";

export const getChrome = async (url: string) => {
  let browser = null;

  try {
    let executablePath: string;
    let userDataDir: string | undefined;

    if (process.env.IS_OFFLINE === 'true') {
      // Local development: Use locally installed Chrome
      const localChromePath = "C:/Program Files/Google/Chrome/Application/chrome.exe";
      executablePath = localChromePath;
      console.log("Launching local Chrome...");

      // Define the temporary directory for local development
      userDataDir = path.join(os.tmpdir(), 'puppeteer_dev_profile');
    } else {
      // Set the executable path to the chromium binary inside the bin directory
      const lambdaPath = "/opt/nodejs/node_modules/@sparticuz/chromium/bin";

      console.log("Launching Chromium in serverless environment...");
      executablePath = await chromium.executablePath(lambdaPath);
    }


    browser = await puppeteer.launch({
      executablePath,
      headless: true,
      args: [
        ...chromium.args,
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--window-size=1920,1080',
      ],
      userDataDir, // Only applied in local development
    });

    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle0' });

    return { browser, page };
  } catch (error) {
    console.error("Error launching Chrome:", error);
    throw error;
  }
};
