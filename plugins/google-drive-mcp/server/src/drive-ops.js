/**
 * Operaciones de Google Drive (capa de lógica sobre la API v3).
 * Cada función devuelve datos planos listos para serializar a JSON.
 */

import { Readable } from "node:stream";
import { getDrive } from "./auth.js";

// Campos por defecto que pedimos para los archivos.
const FILE_FIELDS =
  "id, name, mimeType, size, parents, webViewLink, webContentLink, " +
  "createdTime, modifiedTime, owners(displayName,emailAddress), " +
  "shared, trashed, starred, iconLink, fileExtension, md5Checksum";

// Exportación de documentos nativos de Google a formatos descargables.
const GOOGLE_EXPORT_DEFAULTS = {
  "application/vnd.google-apps.document":
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.google-apps.spreadsheet":
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.google-apps.presentation":
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  "application/vnd.google-apps.drawing": "image/png",
  "application/vnd.google-apps.script": "application/vnd.google-apps.script+json",
};

const GOOGLE_EXPORT_TEXT = {
  "application/vnd.google-apps.document": "text/plain",
  "application/vnd.google-apps.spreadsheet": "text/csv",
  "application/vnd.google-apps.presentation": "text/plain",
};

function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (c) => chunks.push(c));
    stream.on("end", () => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });
}

function isGoogleDoc(mimeType) {
  return typeof mimeType === "string" && mimeType.startsWith("application/vnd.google-apps");
}

/* ------------------------------------------------------------------ */
/* Listado y búsqueda                                                  */
/* ------------------------------------------------------------------ */

export async function listFiles({
  query,
  pageSize = 50,
  pageToken,
  orderBy,
  includeTrashed = false,
} = {}) {
  const drive = await getDrive();
  let q = query || "";
  if (!includeTrashed) {
    q = q ? `(${q}) and trashed = false` : "trashed = false";
  }
  const res = await drive.files.list({
    q: q || undefined,
    pageSize: Math.min(pageSize, 1000),
    pageToken,
    orderBy,
    fields: `nextPageToken, files(${FILE_FIELDS})`,
    supportsAllDrives: true,
    includeItemsFromAllDrives: true,
  });
  return { files: res.data.files || [], nextPageToken: res.data.nextPageToken || null };
}

export async function searchFiles({ name, fullText, mimeType, pageSize = 50 } = {}) {
  const clauses = [];
  if (name) clauses.push(`name contains '${name.replace(/'/g, "\\'")}'`);
  if (fullText) clauses.push(`fullText contains '${fullText.replace(/'/g, "\\'")}'`);
  if (mimeType) clauses.push(`mimeType = '${mimeType}'`);
  if (!clauses.length) {
    throw new Error("Indica al menos uno de: name, fullText o mimeType.");
  }
  return listFiles({ query: clauses.join(" and "), pageSize });
}

export async function listRecentFiles({ pageSize = 20 } = {}) {
  return listFiles({ orderBy: "modifiedTime desc", pageSize });
}

/* ------------------------------------------------------------------ */
/* Metadatos                                                           */
/* ------------------------------------------------------------------ */

export async function getFileMetadata({ fileId }) {
  const drive = await getDrive();
  const res = await drive.files.get({
    fileId,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

/* ------------------------------------------------------------------ */
/* Lectura / descarga / exportación                                   */
/* ------------------------------------------------------------------ */

export async function readFileContent({ fileId, exportMimeType }) {
  const drive = await getDrive();
  const meta = await drive.files.get({ fileId, fields: "mimeType, name" });
  const mimeType = meta.data.mimeType;

  if (isGoogleDoc(mimeType)) {
    const target =
      exportMimeType || GOOGLE_EXPORT_TEXT[mimeType] || "text/plain";
    const res = await drive.files.export(
      { fileId, mimeType: target },
      { responseType: "stream" }
    );
    const buf = await streamToBuffer(res.data);
    return { name: meta.data.name, mimeType: target, content: buf.toString("utf8") };
  }

  const res = await drive.files.get(
    { fileId, alt: "media", supportsAllDrives: true },
    { responseType: "stream" }
  );
  const buf = await streamToBuffer(res.data);
  return { name: meta.data.name, mimeType, content: buf.toString("utf8") };
}

export async function downloadFile({ fileId, exportMimeType }) {
  const drive = await getDrive();
  const meta = await drive.files.get({ fileId, fields: "mimeType, name" });
  const mimeType = meta.data.mimeType;

  let buf;
  let outMime = mimeType;
  if (isGoogleDoc(mimeType)) {
    outMime = exportMimeType || GOOGLE_EXPORT_DEFAULTS[mimeType] || "application/pdf";
    const res = await drive.files.export(
      { fileId, mimeType: outMime },
      { responseType: "stream" }
    );
    buf = await streamToBuffer(res.data);
  } else {
    const res = await drive.files.get(
      { fileId, alt: "media", supportsAllDrives: true },
      { responseType: "stream" }
    );
    buf = await streamToBuffer(res.data);
  }
  return {
    name: meta.data.name,
    mimeType: outMime,
    base64: buf.toString("base64"),
    bytes: buf.length,
  };
}

export async function exportFile({ fileId, mimeType }) {
  const drive = await getDrive();
  const res = await drive.files.export(
    { fileId, mimeType },
    { responseType: "stream" }
  );
  const buf = await streamToBuffer(res.data);
  return { mimeType, base64: buf.toString("base64"), bytes: buf.length };
}

/* ------------------------------------------------------------------ */
/* Creación / actualización                                            */
/* ------------------------------------------------------------------ */

export async function createFile({
  name,
  content,
  mimeType = "text/plain",
  parents,
  base64 = false,
} = {}) {
  const drive = await getDrive();
  const requestBody = { name };
  if (parents && parents.length) requestBody.parents = parents;

  const media =
    content != null
      ? {
          mimeType,
          body: Readable.from(
            base64 ? Buffer.from(content, "base64") : Buffer.from(content, "utf8")
          ),
        }
      : undefined;

  const res = await drive.files.create({
    requestBody,
    media,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

export async function createFolder({ name, parents } = {}) {
  const drive = await getDrive();
  const requestBody = {
    name,
    mimeType: "application/vnd.google-apps.folder",
  };
  if (parents && parents.length) requestBody.parents = parents;
  const res = await drive.files.create({
    requestBody,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

export async function updateFile({
  fileId,
  name,
  content,
  mimeType,
  base64 = false,
} = {}) {
  const drive = await getDrive();
  const requestBody = {};
  if (name) requestBody.name = name;

  const media =
    content != null
      ? {
          mimeType: mimeType || "text/plain",
          body: Readable.from(
            base64 ? Buffer.from(content, "base64") : Buffer.from(content, "utf8")
          ),
        }
      : undefined;

  const res = await drive.files.update({
    fileId,
    requestBody,
    media,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

export async function renameFile({ fileId, name }) {
  const drive = await getDrive();
  const res = await drive.files.update({
    fileId,
    requestBody: { name },
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

export async function copyFile({ fileId, name, parents } = {}) {
  const drive = await getDrive();
  const requestBody = {};
  if (name) requestBody.name = name;
  if (parents && parents.length) requestBody.parents = parents;
  const res = await drive.files.copy({
    fileId,
    requestBody,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

export async function moveFile({ fileId, addParents, removeParents } = {}) {
  const drive = await getDrive();
  // Si no se indica removeParents, quitamos todos los padres actuales.
  let remove = removeParents;
  if (!remove) {
    const cur = await drive.files.get({ fileId, fields: "parents" });
    remove = (cur.data.parents || []).join(",");
  } else if (Array.isArray(remove)) {
    remove = remove.join(",");
  }
  const add = Array.isArray(addParents) ? addParents.join(",") : addParents;
  const res = await drive.files.update({
    fileId,
    addParents: add,
    removeParents: remove || undefined,
    fields: FILE_FIELDS,
    supportsAllDrives: true,
  });
  return res.data;
}

/* ------------------------------------------------------------------ */
/* Papelera y borrado                                                  */
/* ------------------------------------------------------------------ */

export async function trashFile({ fileId }) {
  const drive = await getDrive();
  const res = await drive.files.update({
    fileId,
    requestBody: { trashed: true },
    fields: "id, name, trashed",
    supportsAllDrives: true,
  });
  return res.data;
}

export async function restoreFile({ fileId }) {
  const drive = await getDrive();
  const res = await drive.files.update({
    fileId,
    requestBody: { trashed: false },
    fields: "id, name, trashed",
    supportsAllDrives: true,
  });
  return res.data;
}

export async function deleteFile({ fileId }) {
  const drive = await getDrive();
  await drive.files.delete({ fileId, supportsAllDrives: true });
  return { fileId, deleted: true };
}

export async function emptyTrash() {
  const drive = await getDrive();
  await drive.files.emptyTrash();
  return { emptied: true };
}

/* ------------------------------------------------------------------ */
/* Permisos / compartir                                                */
/* ------------------------------------------------------------------ */

export async function listPermissions({ fileId }) {
  const drive = await getDrive();
  const res = await drive.permissions.list({
    fileId,
    fields:
      "permissions(id, type, role, emailAddress, domain, displayName, deleted)",
    supportsAllDrives: true,
  });
  return res.data.permissions || [];
}

export async function createPermission({
  fileId,
  role = "reader",
  type = "user",
  emailAddress,
  domain,
  sendNotificationEmail = false,
  message,
} = {}) {
  const drive = await getDrive();
  const requestBody = { role, type };
  if (emailAddress) requestBody.emailAddress = emailAddress;
  if (domain) requestBody.domain = domain;
  const res = await drive.permissions.create({
    fileId,
    requestBody,
    sendNotificationEmail,
    emailMessage: message,
    fields: "id, type, role, emailAddress, domain",
    supportsAllDrives: true,
  });
  return res.data;
}

export async function updatePermission({ fileId, permissionId, role }) {
  const drive = await getDrive();
  const res = await drive.permissions.update({
    fileId,
    permissionId,
    requestBody: { role },
    fields: "id, type, role, emailAddress",
    supportsAllDrives: true,
  });
  return res.data;
}

export async function deletePermission({ fileId, permissionId }) {
  const drive = await getDrive();
  await drive.permissions.delete({
    fileId,
    permissionId,
    supportsAllDrives: true,
  });
  return { fileId, permissionId, deleted: true };
}

export async function getShareLink({ fileId, role = "reader", anyone = true } = {}) {
  const drive = await getDrive();
  if (anyone) {
    await drive.permissions.create({
      fileId,
      requestBody: { type: "anyone", role },
      supportsAllDrives: true,
    });
  }
  const res = await drive.files.get({
    fileId,
    fields: "id, name, webViewLink, webContentLink",
    supportsAllDrives: true,
  });
  return res.data;
}

/* ------------------------------------------------------------------ */
/* Cuenta / almacenamiento                                             */
/* ------------------------------------------------------------------ */

export async function getStorageQuota() {
  const drive = await getDrive();
  const res = await drive.about.get({
    fields: "storageQuota, user(displayName,emailAddress)",
  });
  return res.data;
}
