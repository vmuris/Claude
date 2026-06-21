# google-drive-mcp

Plugin de Claude Code que provee un **servidor MCP con todas las funciones de Google Drive**.

## Funciones (herramientas MCP)

| Herramienta | Descripción |
|---|---|
| `drive_list_files` | Listar archivos/carpetas con query de Drive |
| `drive_search_files` | Buscar por nombre, texto completo o tipo MIME |
| `drive_list_recent_files` | Archivos modificados recientemente |
| `drive_get_file_metadata` | Metadatos de un archivo |
| `drive_read_file_content` | Leer contenido como texto (exporta Google Docs) |
| `drive_download_file` | Descargar binario en base64 |
| `drive_export_file` | Exportar Docs/Sheets/Slides a un MIME concreto |
| `drive_create_file` | Crear archivo con contenido |
| `drive_create_folder` | Crear carpeta |
| `drive_update_file` | Actualizar nombre/contenido |
| `drive_rename_file` | Renombrar |
| `drive_copy_file` | Copiar |
| `drive_move_file` | Mover entre carpetas |
| `drive_trash_file` | Enviar a la papelera |
| `drive_restore_file` | Restaurar de la papelera |
| `drive_delete_file` | Eliminar permanentemente |
| `drive_empty_trash` | Vaciar papelera |
| `drive_list_permissions` | Listar permisos |
| `drive_create_permission` | Compartir / dar acceso |
| `drive_update_permission` | Cambiar rol de un permiso |
| `drive_delete_permission` | Revocar acceso |
| `drive_get_share_link` | Obtener enlace para compartir |
| `drive_get_storage_quota` | Uso y cuota de almacenamiento |

## Instalación

```bash
cd plugins/google-drive-mcp/server
npm install
```

## Autenticación

El servidor elige el modo automáticamente según las variables de entorno.

### Opción A — Cuenta de servicio (recomendado para automatización)

1. En [Google Cloud Console](https://console.cloud.google.com/) crea una cuenta de servicio y habilita la **Google Drive API**.
2. Descarga el JSON de la clave.
3. Define la variable:

```bash
export GOOGLE_DRIVE_SERVICE_ACCOUNT_PATH=/ruta/service-account.json
# Opcional (Google Workspace con delegación de dominio):
export GOOGLE_DRIVE_SUBJECT=usuario@tu-dominio.com
```

> Una cuenta de servicio tiene su propio Drive. Para acceder a archivos de un
> usuario real necesitas compartir esos archivos con el email de la cuenta de
> servicio, o usar delegación de dominio (`GOOGLE_DRIVE_SUBJECT`).

### Opción B — OAuth2 de usuario

1. Crea credenciales OAuth de tipo **Aplicación de escritorio** y descarga `credentials.json`.
2. Define las rutas y ejecuta el flujo una vez:

```bash
export GOOGLE_DRIVE_CREDENTIALS_PATH=/ruta/credentials.json
export GOOGLE_DRIVE_TOKEN_PATH=/ruta/token.json
npm run authorize
```

Si no defines las rutas, se usan por defecto en `~/.config/google-drive-mcp/`.

## Uso desde Claude Code

El plugin incluye `.mcp.json`, así que al instalar el plugin desde el
marketplace el servidor `google-drive` queda disponible automáticamente.
Comprueba las herramientas con `/mcp`.

## Prueba rápida

```bash
cd server
node src/index.js   # debe imprimir "Servidor MCP de Google Drive iniciado (stdio)."
```
