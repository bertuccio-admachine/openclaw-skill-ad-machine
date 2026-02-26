#!/usr/bin/env node
/**
 * extract-cookie.js — Extract Ad Machine session cookie via CDP.
 * Requires Chrome running with --remote-debugging-port=9222
 * and an active admachine.xyz session in that browser.
 *
 * Usage:
 *   node --experimental-websocket extract-cookie.js [--port 9222] [--host localhost]
 *
 * Stdout: cookie value (one line)
 * Stderr: progress/error messages
 * Exit 0 = success, 1 = error
 */
"use strict";
const COOKIE_NAME = "__Secure-authjs.session-token";
const DEFAULT_PORT = 9222;
const DEFAULT_HOST = "localhost";

async function main() {
  const args = process.argv.slice(2);
  let port = DEFAULT_PORT, host = DEFAULT_HOST;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--port" && args[i+1]) port = parseInt(args[++i], 10);
    if (args[i] === "--host" && args[i+1]) host = args[++i];
  }

  const listUrl = `http://${host}:${port}/json`;
  let targets;
  try {
    const resp = await fetch(listUrl);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    targets = await resp.json();
  } catch(e) {
    process.stderr.write(`[extract-cookie] Cannot reach CDP at ${listUrl}: ${e.message}\n`);
    process.exit(1);
  }

  const target = targets.find(t => t.type === "page" && t.webSocketDebuggerUrl);
  if (!target) {
    process.stderr.write("[extract-cookie] No page target found.\n");
    process.exit(1);
  }

  const wsUrl = target.webSocketDebuggerUrl;
  process.stderr.write(`[extract-cookie] Connecting: ${wsUrl}\n`);

  await new Promise((resolve, reject) => {
    const { WebSocket } = globalThis;
    if (!WebSocket) { reject(new Error("WebSocket not available — use node >= 21 or --experimental-websocket")); return; }
    const ws = new WebSocket(wsUrl);
    let id = 1;
    ws.onopen = () => ws.send(JSON.stringify({id: id++, method: "Storage.getCookies", params: {}}));
    ws.onmessage = (event) => {
      let data;
      try { data = JSON.parse(event.data); } catch { return; }
      if (!data.result || !Array.isArray(data.result.cookies)) return;
      ws.close();
      const cookie = data.result.cookies.find(c => c.name === COOKIE_NAME);
      if (!cookie) {
        process.stderr.write(`[extract-cookie] Cookie '${COOKIE_NAME}' not found. Are you logged in?\n`);
        reject(new Error("Cookie not found")); return;
      }
      process.stdout.write(cookie.value + "\n");
      resolve();
    };
    ws.onerror = (err) => reject(new Error(`WebSocket error: ${err.message || err}`));
    setTimeout(() => reject(new Error("Timeout")), 10000);
  }).catch(e => { process.stderr.write(`[extract-cookie] ${e.message}\n`); process.exit(1); });
}
main();
