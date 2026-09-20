#!/usr/bin/env node
// Servidor de datos falso para desarrollar el reloj sin tocar Darwin.
// Sirve exactamente el contrato que decodifica RyRCore.
// Uso: node tools/mock-server/server.js   (puerto 8787, token "demo-token")

const http = require('http');
const { URL } = require('url');

const PUERTO = Number(process.env.PUERTO || 8787);
const TOKEN = process.env.TOKEN || 'demo-token';

const iso = (d) => new Date(d).toISOString().replace(/\.\d{3}Z$/, 'Z');
const hace = (horas) => iso(Date.now() - horas * 3600 * 1000);

const PEDIMENTOS = [
  {
    id: '5000123', numero: '264037215000123', patente: '3721', aduana: '400', clave: 'A1',
    cliente: 'POCHTECA MATERIAS PRIMAS', cliente_id: 29, estatus: 'cruzado',
    valor_usd: 184320.55, fecha_pago: hace(7), modulado_en: hace(2),
    doda: 'DODA-8821-4417', facturado: false
  },
  {
    id: '5000124', numero: '264037215000124', patente: '3721', aduana: '400', clave: 'IN',
    cliente: 'TRANS-PACKAGING DE MEXICO', cliente_id: 437, estatus: 'modulado',
    valor_usd: 42780.0, fecha_pago: hace(4), modulado_en: hace(0.7),
    doda: null, facturado: false
  },
  {
    id: '5000125', numero: '264037215000125', patente: '3721', aduana: '400', clave: 'V1',
    cliente: 'TRANSPAKING CRATES', cliente_id: 936, estatus: 'pagado',
    valor_usd: 9410.2, fecha_pago: hace(1.5), modulado_en: null,
    doda: null, facturado: false
  },
  {
    id: '5000126', numero: '264037215000126', patente: '3721', aduana: '400', clave: 'A1',
    cliente: 'UNIVAR SOLUTIONS MEXICO', cliente_id: 883, estatus: 'detenido',
    valor_usd: 311500.0, fecha_pago: hace(26), modulado_en: hace(22),
    doda: null, facturado: false
  },
  {
    id: '4100987', numero: '262219414100987', patente: '1941', aduana: '220', clave: 'A1',
    cliente: 'POCHTECA MATERIAS PRIMAS', cliente_id: 29, estatus: 'facturado',
    valor_usd: 76050.1, fecha_pago: hace(52), modulado_en: hace(48),
    doda: 'DODA-7719-2203', facturado: true
  }
];

const CARTERA = [
  { id: 883, cliente: 'UNIVAR SOLUTIONS MEXICO', saldo_mxn: 1842300.0, vencido_mxn: 940100.0, documentos: 14, dias_promedio: 96 },
  { id: 29, cliente: 'POCHTECA MATERIAS PRIMAS', saldo_mxn: 612450.0, vencido_mxn: 128900.0, documentos: 9, dias_promedio: 51 },
  { id: 437, cliente: 'TRANS-PACKAGING DE MEXICO', saldo_mxn: 288770.0, vencido_mxn: 0.0, documentos: 6, dias_promedio: 22 }
];

const resumen = () => {
  const total = CARTERA.reduce((a, c) => a + c.saldo_mxn, 0);
  const vencido = CARTERA.reduce((a, c) => a + c.vencido_mxn, 0);
  return {
    fecha: iso(Date.now()),
    pedimentos_del_dia: PEDIMENTOS.length + 7,
    cruces_doda: PEDIMENTOS.filter((p) => p.doda).length + 5,
    pendientes_facturar: PEDIMENTOS.filter((p) => !p.facturado).length,
    cartera_total_mxn: Number(total.toFixed(2)),
    cartera_vencida_mxn: Number(vencido.toFixed(2)),
    alertas: [
      { id: 'a1', titulo: 'Pedimento detenido', detalle: '26 40 3721 5000126 lleva 22 h en reconocimiento.', severidad: 'critica' },
      { id: 'a2', titulo: 'Cruzados sin facturar', detalle: '4 pedimentos modularon y no se han facturado.', severidad: 'alta' }
    ]
  };
};

const responder = (res, codigo, cuerpo) => {
  const datos = JSON.stringify(cuerpo);
  res.writeHead(codigo, { 'Content-Type': 'application/json; charset=utf-8', 'Content-Length': Buffer.byteLength(datos) });
  res.end(datos);
};

const servidor = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const ruta = url.pathname.replace(/\/+$/, '');

  if (ruta === '/v1/salud') return responder(res, 200, { ok: true, version: '1.0' });

  const auth = req.headers.authorization || '';
  if (auth !== `Bearer ${TOKEN}`) return responder(res, 401, { error: 'token invalido' });

  if (ruta === '/v1/resumen') return responder(res, 200, resumen());

  if (ruta === '/v1/pedimentos') {
    const limite = Number(url.searchParams.get('limite') || 40);
    return responder(res, 200, PEDIMENTOS.slice(0, limite));
  }

  const detalle = ruta.match(/^\/v1\/pedimentos\/(.+)$/);
  if (detalle) {
    const p = PEDIMENTOS.find((x) => x.id === detalle[1]);
    return p ? responder(res, 200, p) : responder(res, 404, { error: 'no existe' });
  }

  if (ruta === '/v1/cartera') return responder(res, 200, CARTERA);

  return responder(res, 404, { error: 'ruta desconocida' });
});

servidor.listen(PUERTO, () => {
  console.log(`mock RyR escuchando en http://localhost:${PUERTO} (token: ${TOKEN})`);
});
