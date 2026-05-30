import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  IpcHandler {
      target: "plugin:simple-notes"

      function toggle() {
          if (!pluginApi) return;
          pluginApi.withCurrentScreen(screen => {
              pluginApi.togglePanel(screen);
          });
      }
  }

  Component.onCompleted: {
    if (pluginApi) {
      // Initialize settings if they don't exist
      if (!pluginApi.pluginSettings.notes) {
        pluginApi.pluginSettings.notes = [];
        pluginApi.saveSettings();
      }
      if (pluginApi.pluginSettings.showCountInBar === undefined) {
        pluginApi.pluginSettings.showCountInBar = true;
        pluginApi.saveSettings();
      }
      if (pluginApi.pluginSettings.count === undefined) {
        pluginApi.pluginSettings.count = 0;
        pluginApi.saveSettings();
      }
    }
  }
}
