/**
 * Autenticación con Google Drive.
 *
 * Soporta dos modos (se elige automáticamente según las variables de entorno):
 *
 *  1) Cuenta de servicio (recomendado para automatización):
 *       GOOGLE_DRIVE_SERVICE_ACCOUNT_PATH = ruta al JSON de la cuenta de servicio
 *       GOOGLE_DRIVE_SUBJECT (opcional) = email a suplantar (delegación de dominio)
 *
 *  2) OAuth2 de usuario:
 *       GOOGLE_DRIVE_CREDENTIALS_PATH = ruta al credentials.json (OAuth client)
 *       GOOGLE_DRIVE_TOKEN_PATH       = ruta donde se guarda/lee el token
 *     El token se genera una vez con `npm run authorize`.
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { google } from "googleapis";

// Alcance completo: lectura, escritura, borrado, permisos, etc.
export const SCOPES = ["https://www.googleapis.com/auth/drive"];

const DEFAULT_DIR = path.join(os.homedir(), ".config", "google-drive-mcp");

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function resolvePath(envValue, fallbackFile) {
  if (envValue && envValue.trim() && !envValue.startsWith("${")) {
    return envValue.trim();
  }
  return path.join(DEFAULT_DIR, fallbackFile);
}

/**
 * Construye un cliente OAuth2 de googleapis a partir del credentials.json.
 */
function buildOAuthClient(credentials) {
  const conf = credentials.installed || credentials.web;
  if (!conf) {
    throw new Error(
      "credentials.json no válido: se esperaba la clave 'installed' o 'web'."
    );
  }
  const redirectUri =
    (conf.redirect_uris && conf.redirect_uris[0]) ||
    "http://localhost:3000/oauth2callback";
  return new google.auth.OAuth2(conf.client_id, conf.client_secret, redirectUri);
}

/**
 * Devuelve un cliente autenticado listo para usar con la API de Drive.
 */
export async function getAuthClient() {
  const serviceAccountPath = resolvePath(
    process.env.GOOGLE_DRIVE_SERVICE_ACCOUNT_PATH,
    "service-account.json"
  );

  // Modo 1: cuenta de servicio
  if (fs.existsSync(serviceAccountPath)) {
    const key = readJson(serviceAccountPath);
    const subject =
      process.env.GOOGLE_DRIVE_SUBJECT &&
      !process.env.GOOGLE_DRIVE_SUBJECT.startsWith("${")
        ? process.env.GOOGLE_DRIVE_SUBJECT
        : undefined;

    const auth = new google.auth.JWT({
      email: key.client_email,
      key: key.private_key,
      scopes: SCOPES,
      subject,
    });
    await auth.authorize();
    return auth;
  }

  // Modo 2: OAuth2 de usuario
  const credentialsPath = resolvePath(
    process.env.GOOGLE_DRIVE_CREDENTIALS_PATH,
    "credentials.json"
  );
  const tokenPath = resolvePath(
    process.env.GOOGLE_DRIVE_TOKEN_PATH,
    "token.json"
  );

  if (!fs.existsSync(credentialsPath)) {
    throw new Error(
      `No se encontraron credenciales. Define GOOGLE_DRIVE_SERVICE_ACCOUNT_PATH ` +
        `(cuenta de servicio) o GOOGLE_DRIVE_CREDENTIALS_PATH (OAuth). ` +
        `Buscado en: ${serviceAccountPath} y ${credentialsPath}`
    );
  }

  const oAuth2Client = buildOAuthClient(readJson(credentialsPath));

  if (!fs.existsSync(tokenPath)) {
    throw new Error(
      `No existe el token de OAuth en ${tokenPath}. ` +
        `Ejecuta primero: npm run authorize`
    );
  }

  oAuth2Client.setCredentials(readJson(tokenPath));

  // Persistir tokens renovados automáticamente.
  oAuth2Client.on("tokens", (tokens) => {
    try {
      const current = fs.existsSync(tokenPath) ? readJson(tokenPath) : {};
      fs.mkdirSync(path.dirname(tokenPath), { recursive: true });
      fs.writeFileSync(
        tokenPath,
        JSON.stringify({ ...current, ...tokens }, null, 2)
      );
    } catch {
      /* no bloquear si falla la escritura del token */
    }
  });

  return oAuth2Client;
}

/**
 * Devuelve una instancia del cliente de la API de Drive (v3).
 */
export async function getDrive() {
  const auth = await getAuthClient();
  return google.drive({ version: "v3", auth });
}

export { DEFAULT_DIR, buildOAuthClient, resolvePath, readJson };
