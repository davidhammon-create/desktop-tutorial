const { app, BrowserWindow, shell, Menu } = require("electron");
const path = require("path");
// Packaged builds always load dist. Unpackaged: ELECTRON_DEV=1 (electron:dev)
// or ATMOS_DEV_URL forces Vite; otherwise prefer dist/index.html when present.
const DEV_URL = process.env.ATMOS_DEV_URL || "http://127.0.0.1:8080";
const distIndex = path.join(__dirname, "..", "dist", "index.html");
const forceDev = process.env.ELECTRON_DEV === "1" || Boolean(process.env.ATMOS_DEV_URL);
const forceProd = process.env.ELECTRON_DEV === "0";
const isDev =
  !forceProd &&
  (forceDev || (!app.isPackaged && !require("fs").existsSync(distIndex)));
/** @type {BrowserWindow | null} */
let mainWindow = null;
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 960,
    minHeight: 640,
    title: "AtmOS",
    backgroundColor: "#0a0a0c",
    show: false,
    autoHideMenuBar: true,
    titleBarStyle: process.platform === "darwin" ? "hiddenInset" : "default",
    trafficLightPosition: process.platform === "darwin" ? { x: 16, y: 16 } : undefined,
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      spellcheck: false,
    },
  });
  mainWindow.once("ready-to-show", () => {
    mainWindow?.show();
  });
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
  if (isDev) {
    mainWindow.loadURL(DEV_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, "..", "dist", "index.html"));
  }
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}
app.whenReady().then(() => {
  if (process.platform !== "darwin") {
    Menu.setApplicationMenu(null);
  } else {
    Menu.setApplicationMenu(
      Menu.buildFromTemplate([
        {
          label: app.name,
          submenu: [
            { role: "about" },
            { type: "separator" },
            { role: "services" },
            { type: "separator" },
            { role: "hide" },
            { role: "hideOthers" },
            { role: "unhide" },
            { type: "separator" },
            { role: "quit" },
          ],
        },
        { role: "editMenu" },
        { role: "viewMenu" },
        { role: "windowMenu" },
      ]),
    );
  }
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
