import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ? path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS)
  : path.join(__dirname, '../serviceAccountKey.json');

if (!fs.existsSync(credentialsPath)) {
  throw new Error(
    `Firebase service account key not found at ${credentialsPath}. ` +
    `Download it from Firebase Console → Project Settings → Service Accounts`
  );
}

const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const firebaseAuth = admin.auth();
export const firebaseApp = admin;
export default admin;
