const { BasePlugin } = require('appium/plugin');
const { exec } = require('child_process');
const util = require('util');

class AdbConnectPlugin extends BasePlugin {

  static async updateServer(expressApp, httpServer, cliArgs) {
    expressApp.post('/adb/connect', async (req, res) => {
      const { host, port } = req.body;
      try {
        AdbConnectPlugin.#validateParams(host, port);
        await AdbConnectPlugin.#executeAdbCommand(host, port);
        return res.status(204).send();
      } catch (error) {
        return res.status(500).send(error.message); 
      }
    });
  }

  static #validateParams(host, port) {
    if (!host || !port) {
      throw new Error('Missing required parameters: host and port');
    }
  }

  static async #executeAdbCommand(host, port) {
    await AdbConnectPlugin.#adbDisconnect();
    await AdbConnectPlugin.#adbKillServer();
    const result = await AdbConnectPlugin.#adbConnect(host, port);
    if (!result.includes(`connected to ${host}:${port}`)) {
      throw new Error(result);
    }
  }

  static async #adbDisconnect() {
    await AdbConnectPlugin.#runCommand(`adb disconnect`, 'Disconnecting existing ADB connections');
  }

  static async #adbKillServer() {
    await AdbConnectPlugin.#runCommand(`adb kill-server`, 'Killing ADB server');
  }

  static async #adbConnect(host, port) {
    return await AdbConnectPlugin.#runCommand(`adb connect ${host}:${port}`, `Connecting to ${host}:${port}`);
  }

  static async #runCommand(command, logMessage) {
    console.log(logMessage)
    const execPromise = util.promisify(exec);
    try {
      const result = await execPromise(command);
      return result.stdout.trim();
    } catch (error) {
       throw new Error(error.message);
    }
  }
}

module.exports = { AdbConnectPlugin };
