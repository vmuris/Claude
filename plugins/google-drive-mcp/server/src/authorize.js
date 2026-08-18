#!/usr/bin/env node
/**
 * Flujo de autorización OAuth2 (ejecutar una sola vez).
 *
 *   npm run authorize
 *
 * Abre una URL en el navegador, te pide el código de Google y guarda el token
 * en GOOGLE_DRIVE_TOKEN_PATH (o ~/.config/google-drive-mcp/token.json).
 */

import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import {
  SCOPES,
  DEFAULT_DIR,
  buildOAuthClient,
  resolvePath,
  readJson,
} from "./auth.js";

async function main() {
  const credentialsPath = resolvePath(
    process.env.GOOGLE_DRIVE_CREDENTIALS_PATH,
    "credentials.json"
  );
  const tokenPath = resolvePath(
    process.env.GOOGLE_DRIVE_TOKEN_PATH,
    "token.json"
  );

  if (!fs.existsSync(credentialsPath)) {
    console.error(
      `No se encontró credentials.json en ${credentialsPath}.\n` +
        `Crea credenciales OAuth (tipo "Aplicación de escritorio") en ` +
        `https://console.cloud.google.com/apis/credentials y guárdalas ahí, ` +
        `o define GOOGLE_DRIVE_CREDENTIALS_PATH.`
    );
    process.exit(1);
  }

  const oAuth2Client = buildOAuthClient(readJson(credentialsPath));

  const authUrl = oAuth2Client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: SCOPES,
  });

  console.log("\n1) Abre esta URL en tu navegador y concede acceso:\n");
  console.log(authUrl + "\n");

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const code = await new Promise((resolve) => {
    rl.question("2) Pega aquí el código de autorización: ", (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });

  const { tokens } = await oAuth2Client.getToken(code);

  fs.mkdirSync(path.dirname(tokenPath) || DEFAULT_DIR, { recursive: true });
  fs.writeFileSync(tokenPath, JSON.stringify(tokens, null, 2));

  console.log(`\n✅ Token guardado en ${tokenPath}`);
  console.log("Ya puedes usar el servidor MCP de Google Drive.");
}

main().catch((err) => {
  console.error("Error durante la autorización:", err.message);
  process.exit(1);
});
