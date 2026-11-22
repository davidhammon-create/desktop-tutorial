const { contextBridge } = require("electron");
contextBridge.exposeInMainWorld("atmosDesktop", {
  platform: process.platform,
  isDesktop: true,
});
