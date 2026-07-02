const { app, BrowserWindow } = require("electron");
const path = require("node:path");
const { fork } = require("node:child_process");

const PORT = 8787;
const HOST = "127.0.0.1";

let serverProcess = null;
let mainWindow = null;

function serverEntryPath() {
  // Dev: run straight from the repo. Packaged: server/ is copied into
  // resources/ by electron-builder (see package.json "build.extraResources").
  return app.isPackaged
    ? path.join(process.resourcesPath, "server", "index.js")
    : path.join(__dirname, "..", "server", "index.js");
}

function staticDirPath() {
  return app.isPackaged
    ? path.join(process.resourcesPath, "dist")
    : path.join(__dirname, "..", "dist");
}

function startServer() {
  const dataDir = path.join(app.getPath("userData"), "data");

  // `fork` with execPath: process.execPath + ELECTRON_RUN_AS_NODE runs the
  // server using Electron's own bundled Node — end users don't need Node.js
  // installed separately for the packaged app to work.
  serverProcess = fork(serverEntryPath(), [], {
    execPath: process.execPath,
    env: {
      ...process.env,
      ELECTRON_RUN_AS_NODE: "1",
      PORT: String(PORT),
      HOST,
      ABOWANDLER_DATA_DIR: dataDir,
      ABOWANDLER_STATIC_DIR: staticDirPath(),
    },
    stdio: ["ignore", "pipe", "pipe", "ipc"],
  });

  serverProcess.stdout?.on("data", (d) => process.stdout.write(`[server] ${d}`));
  serverProcess.stderr?.on("data", (d) => process.stderr.write(`[server] ${d}`));
  serverProcess.on("exit", (code) => {
    if (code !== 0 && code !== null) console.error(`Backend beendet mit Code ${code}`);
  });
}

async function waitForServer(timeoutMs = 20000) {
  const url = `http://${HOST}:${PORT}/api/health`;
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
    } catch {
      // not up yet
    }
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error("Backend ist nicht rechtzeitig gestartet.");
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1320,
    height: 880,
    minWidth: 900,
    minHeight: 600,
    backgroundColor: "#050508",
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  const startUrl = process.env.ELECTRON_START_URL || `http://${HOST}:${PORT}`;
  mainWindow.loadURL(startUrl);
}

app.whenReady().then(async () => {
  startServer();
  try {
    await waitForServer();
  } catch (err) {
    console.error(err.message);
  }
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

function stopServer() {
  if (serverProcess) {
    serverProcess.kill();
    serverProcess = null;
  }
}

app.on("window-all-closed", () => {
  stopServer();
  if (process.platform !== "darwin") app.quit();
});

app.on("before-quit", stopServer);
