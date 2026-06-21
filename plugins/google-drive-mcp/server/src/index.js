#!/usr/bin/env node
/**
 * Servidor MCP de Google Drive.
 * Expone todas las funciones de Drive como herramientas (tools) MCP.
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import * as drive from "./drive-ops.js";

const server = new McpServer({
  name: "google-drive",
  version: "1.0.0",
});

// Envuelve una operación y devuelve el resultado como JSON formateado.
function tool(name, config, handler) {
  server.registerTool(name, config, async (args) => {
    try {
      const result = await handler(args || {});
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (err) {
      const detail =
        err?.response?.data?.error?.message || err?.message || String(err);
      return {
        isError: true,
        content: [{ type: "text", text: `Error de Drive: ${detail}` }],
      };
    }
  });
}

/* -------------------- Listado y búsqueda -------------------- */

tool(
  "drive_list_files",
  {
    title: "Listar archivos",
    description:
      "Lista archivos y carpetas de Drive. Acepta una query con la sintaxis de búsqueda de Drive (ej: \"name contains 'informe'\").",
    inputSchema: {
      query: z.string().optional().describe("Query de búsqueda de Drive (opcional)."),
      pageSize: z.number().int().min(1).max(1000).optional(),
      pageToken: z.string().optional(),
      orderBy: z.string().optional().describe("Ej: 'modifiedTime desc', 'name'."),
      includeTrashed: z.boolean().optional(),
    },
  },
  drive.listFiles
);

tool(
  "drive_search_files",
  {
    title: "Buscar archivos",
    description:
      "Busca archivos por nombre, texto completo y/o tipo MIME. Indica al menos un criterio.",
    inputSchema: {
      name: z.string().optional().describe("Coincidencia parcial en el nombre."),
      fullText: z.string().optional().describe("Búsqueda en el contenido."),
      mimeType: z.string().optional(),
      pageSize: z.number().int().min(1).max(1000).optional(),
    },
  },
  drive.searchFiles
);

tool(
  "drive_list_recent_files",
  {
    title: "Archivos recientes",
    description: "Lista los archivos modificados más recientemente.",
    inputSchema: {
      pageSize: z.number().int().min(1).max(1000).optional(),
    },
  },
  drive.listRecentFiles
);

/* -------------------- Metadatos -------------------- */

tool(
  "drive_get_file_metadata",
  {
    title: "Metadatos de archivo",
    description: "Obtiene los metadatos de un archivo o carpeta por su ID.",
    inputSchema: { fileId: z.string().describe("ID del archivo.") },
  },
  drive.getFileMetadata
);

/* -------------------- Lectura / descarga -------------------- */

tool(
  "drive_read_file_content",
  {
    title: "Leer contenido (texto)",
    description:
      "Lee el contenido textual de un archivo. Los documentos de Google se exportan automáticamente a texto/CSV.",
    inputSchema: {
      fileId: z.string(),
      exportMimeType: z
        .string()
        .optional()
        .describe("Tipo MIME de exportación para documentos de Google."),
    },
  },
  drive.readFileContent
);

tool(
  "drive_download_file",
  {
    title: "Descargar archivo (base64)",
    description:
      "Descarga un archivo binario y lo devuelve en base64. Los documentos de Google se exportan (Office/PDF por defecto).",
    inputSchema: {
      fileId: z.string(),
      exportMimeType: z.string().optional(),
    },
  },
  drive.downloadFile
);

tool(
  "drive_export_file",
  {
    title: "Exportar documento de Google",
    description:
      "Exporta un documento nativo de Google (Docs/Sheets/Slides) a un tipo MIME concreto y lo devuelve en base64.",
    inputSchema: {
      fileId: z.string(),
      mimeType: z.string().describe("Tipo MIME destino, ej: 'application/pdf'."),
    },
  },
  drive.exportFile
);

/* -------------------- Creación / actualización -------------------- */

tool(
  "drive_create_file",
  {
    title: "Crear archivo",
    description:
      "Crea un archivo nuevo con contenido opcional. Usa base64=true si 'content' viene codificado en base64.",
    inputSchema: {
      name: z.string(),
      content: z.string().optional(),
      mimeType: z.string().optional(),
      parents: z.array(z.string()).optional().describe("IDs de carpetas padre."),
      base64: z.boolean().optional(),
    },
  },
  drive.createFile
);

tool(
  "drive_create_folder",
  {
    title: "Crear carpeta",
    description: "Crea una carpeta nueva.",
    inputSchema: {
      name: z.string(),
      parents: z.array(z.string()).optional(),
    },
  },
  drive.createFolder
);

tool(
  "drive_update_file",
  {
    title: "Actualizar archivo",
    description:
      "Actualiza el nombre y/o el contenido de un archivo existente.",
    inputSchema: {
      fileId: z.string(),
      name: z.string().optional(),
      content: z.string().optional(),
      mimeType: z.string().optional(),
      base64: z.boolean().optional(),
    },
  },
  drive.updateFile
);

tool(
  "drive_rename_file",
  {
    title: "Renombrar archivo",
    description: "Cambia el nombre de un archivo o carpeta.",
    inputSchema: { fileId: z.string(), name: z.string() },
  },
  drive.renameFile
);

tool(
  "drive_copy_file",
  {
    title: "Copiar archivo",
    description: "Crea una copia de un archivo.",
    inputSchema: {
      fileId: z.string(),
      name: z.string().optional(),
      parents: z.array(z.string()).optional(),
    },
  },
  drive.copyFile
);

tool(
  "drive_move_file",
  {
    title: "Mover archivo",
    description:
      "Mueve un archivo a otra(s) carpeta(s). Si no se indica removeParents, se quitan los padres actuales.",
    inputSchema: {
      fileId: z.string(),
      addParents: z.array(z.string()).describe("IDs de carpetas destino."),
      removeParents: z.array(z.string()).optional(),
    },
  },
  drive.moveFile
);

/* -------------------- Papelera y borrado -------------------- */

tool(
  "drive_trash_file",
  {
    title: "Enviar a papelera",
    description: "Mueve un archivo a la papelera (reversible).",
    inputSchema: { fileId: z.string() },
  },
  drive.trashFile
);

tool(
  "drive_restore_file",
  {
    title: "Restaurar de papelera",
    description: "Restaura un archivo desde la papelera.",
    inputSchema: { fileId: z.string() },
  },
  drive.restoreFile
);

tool(
  "drive_delete_file",
  {
    title: "Eliminar permanentemente",
    description: "Elimina un archivo de forma permanente (no reversible).",
    inputSchema: { fileId: z.string() },
  },
  drive.deleteFile
);

tool(
  "drive_empty_trash",
  {
    title: "Vaciar papelera",
    description: "Vacía la papelera de forma permanente.",
    inputSchema: {},
  },
  drive.emptyTrash
);

/* -------------------- Permisos / compartir -------------------- */

tool(
  "drive_list_permissions",
  {
    title: "Listar permisos",
    description: "Lista los permisos (quién tiene acceso) de un archivo.",
    inputSchema: { fileId: z.string() },
  },
  drive.listPermissions
);

tool(
  "drive_create_permission",
  {
    title: "Compartir / dar permiso",
    description:
      "Concede acceso a un usuario, grupo, dominio o a cualquiera. role: reader|commenter|writer|owner.",
    inputSchema: {
      fileId: z.string(),
      role: z.enum(["reader", "commenter", "writer", "owner"]).optional(),
      type: z.enum(["user", "group", "domain", "anyone"]).optional(),
      emailAddress: z.string().optional(),
      domain: z.string().optional(),
      sendNotificationEmail: z.boolean().optional(),
      message: z.string().optional(),
    },
  },
  drive.createPermission
);

tool(
  "drive_update_permission",
  {
    title: "Actualizar permiso",
    description: "Cambia el rol de un permiso existente.",
    inputSchema: {
      fileId: z.string(),
      permissionId: z.string(),
      role: z.enum(["reader", "commenter", "writer", "owner"]),
    },
  },
  drive.updatePermission
);

tool(
  "drive_delete_permission",
  {
    title: "Quitar permiso",
    description: "Revoca un permiso (deja de compartir) de un archivo.",
    inputSchema: { fileId: z.string(), permissionId: z.string() },
  },
  drive.deletePermission
);

tool(
  "drive_get_share_link",
  {
    title: "Obtener enlace para compartir",
    description:
      "Devuelve el enlace del archivo. Si anyone=true, lo hace accesible por enlace con el rol indicado.",
    inputSchema: {
      fileId: z.string(),
      role: z.enum(["reader", "commenter", "writer"]).optional(),
      anyone: z.boolean().optional(),
    },
  },
  drive.getShareLink
);

/* -------------------- Cuenta -------------------- */

tool(
  "drive_get_storage_quota",
  {
    title: "Cuota de almacenamiento",
    description: "Muestra el uso y la cuota de almacenamiento de la cuenta.",
    inputSchema: {},
  },
  drive.getStorageQuota
);

/* -------------------- Arranque -------------------- */

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // No usar stdout: el transporte stdio lo ocupa. Logs van a stderr.
  console.error("Servidor MCP de Google Drive iniciado (stdio).");
}

main().catch((err) => {
  console.error("Fallo al iniciar el servidor MCP:", err);
  process.exit(1);
});
