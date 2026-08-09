import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import ".."

PanelWindow {
  id: root

  implicitWidth: 280
  implicitHeight: 320

  property bool isShowing: false
  property var networks: []
  property bool showPasswordForm: false
  property string pendingSSID: ""
  property bool isKnownNetwork: false
  property bool isScanning: false

  property string toastMsg: ""
  property bool isToastError: false
  property bool showToast: false

  function displayToast(msg, isError) {
    root.toastMsg = msg
    root.isToastError = isError
    root.showToast = true
    toastTimer.restart()
  }

  function doConnect() {
    connectProcess.ssid = root.pendingSSID 
    connectProcess.isDisconnecting = false
    connectProcess.command = [
      Quickshell.shellDir + "/scripts/connect_wifi.sh",
      root.pendingSSID,
      passwordField.text
    ]
    connectProcess.running = true
    root.showPasswordForm = false
    passwordField.text = ""
  }

  Process {
    id: checkKnownProcess
    property string ssid: ""
    command: ["bash", "-c", "nmcli -t -f NAME connection show 2>/dev/null | grep -cx '^" + ssid + "$'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var isKnown = parseInt(text.trim()) > 0
        root.isKnownNetwork = isKnown
        if (isKnown) {
          root.pendingSSID = checkKnownProcess.ssid
          doConnect()
        } else {
          root.pendingSSID = checkKnownProcess.ssid
          root.showPasswordForm = true
        }
      }
    }
  }

  Timer {
    id: showTimer
    interval: 16
    onTriggered: root.isShowing = true
  }

  onVisibleChanged: {
    if (visible) {
      isShowing = false
      showTimer.start()
    } else {
      isShowing = false
    }
  }

  Process {
    id: scanProcess
    command: ["python3", "-u", Quickshell.shellDir + "/scripts/scan_wifi.py"]
    running: false

    stdout: SplitParser {
      onRead: (data) => {
        try {
          var parsed = JSON.parse(data)
          if (parsed.length > 0) {
            root.networks = parsed
          }
        } catch(e) {
          console.log("parse error:", e, data)
        }
      }
    }

    onRunningChanged: {
      if (!running) {
        // Script mati/crash → jadwalkan restart, stop animasi
        root.isScanning = false
        scanRestartTimer.start()
      }
      // isScanning TIDAK diset true di sini
      // animasi hanya dari tombol scan manual
    }
  }

  Timer {
    id: scanRestartTimer
    interval: 8000
    repeat: false
    onTriggered: {
      if (!connectProcess.running) {
        scanProcess.running = true
      }
    }
  }

  Timer {
    id: scanTimer
    interval: 5000
    onTriggered: root.isScanning = false
  }

  Component.onCompleted: {
    scanProcess.running = true
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  signal requestClose()

  MouseArea {
    anchors.fill: parent
    onClicked: root.requestClose()
  }

  Rectangle {
    id: mainRect
    width: root.implicitWidth
    height: root.implicitHeight
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 70
    anchors.rightMargin: 10
    color: "transparent"

    opacity: root.isShowing ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    transform: Translate {
      y: root.isShowing ? 0 : -(root.implicitHeight + 50)
      Behavior on y {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.bottomMargin: 12
      gradient: Gradient {
        orientation: Gradient.Horizontal 
        GradientStop { position: 0.1; color: Colors.topbar_gradient5 }
        GradientStop { position: 0.8; color: Colors.topbar_gradient6 }
      }
      radius: 12
      border.color: Colors.outline_variant
      border.width: 2

      MouseArea {              
        anchors.fill: parent
        onClicked: {}
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Wifi"
            color: Colors.text_variant1
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
          }

          // Scan button
          Rectangle {
            width: 20; height: 20
            color: scanArea.containsMouse ? Colors.action_btn_hovered : "transparent"
            radius: 4

            Text {
              id: scanIcon
              anchors.centerIn: parent
              text: "󰑐"
              color: root.isScanning ? Colors.action_btn_running : Colors.action_btn_icon
              font.pixelSize: 14

              RotationAnimation on rotation {
                running: root.isScanning
                from: 0; to: 360
                duration: 1000
                loops: Animation.Infinite
              }
            }

            MouseArea {
              id: scanArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                root.isScanning = true
                scanTimer.restart()
                scanProcess.running = false
                Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"])
                scanRestartTimer.interval = 2000
                scanRestartTimer.restart()
              }
            }
          }

          // Close button
          Rectangle {
            width: 20; height: 20
            color: closeArea.containsMouse ? Colors.close_btn_hovered : "transparent"
            radius: 4
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: Colors.close_btn_icon
              font.pixelSize: 12
            }
            MouseArea {
              id: closeArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.requestClose()
            }
          }
        }

        // Divider
        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Colors.divider
        }

        // Network list
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          // ── List WiFi ──
          ListView {
            id: networkList
            anchors.fill: parent
            visible: !root.showPasswordForm
            clip: true
            spacing: 6
            model: root.networks

            Text {
              anchors.centerIn: parent
              text: root.networks.length === 0 ? "No Networks" : ""
              color: Colors.text
              font.pixelSize: 12
              visible: networkList.count === 0
            }

            delegate: Rectangle {
              id: netItem
              required property var modelData

              width: networkList.width
              height: 55
              color: netArea.containsMouse 
              ? Colors.isDark ? Colors.net_item_hovered : Qt.alpha(Colors.net_item_hovered, 0.3) 
              : Colors.net_item_bg
              radius: 6

              Behavior on color { ColorAnimation { duration: 100 } }

              MouseArea {
                id: netArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  var isConnected = netItem.modelData.connected
                  var isSecured = netItem.modelData.secured
                  
                  if (isConnected) {
                    connectProcess.ssid = netItem.modelData.ssid
                    connectProcess.isDisconnecting = true
                    connectProcess.command = ["bash", "-c", "nmcli connection down '" + netItem.modelData.ssid + "'"]
                    connectProcess.running = true
                  } else {
                    root.pendingSSID = netItem.modelData.ssid
                    
                    if (!isSecured) {
                      root.showPasswordForm = false
                      passwordField.text = ""
                      doConnect()
                    } else {
                      checkKnownProcess.ssid = netItem.modelData.ssid
                      checkKnownProcess.running = true
                    }
                  }
                }
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                  Layout.alignment: Qt.AlignVCenter
                  topPadding: -2
                  text: {
                    var s = netItem.modelData.signal
                    if (s >= 75) return "󰤨"
                    if (s >= 50) return "󰤥"
                    if (s >= 25) return "󰤢"
                    return "󰤯"
                  }
                  color: modelData.connected ? Colors.net_icon_connected : Colors.net_icon_disconnected
                  font.pixelSize: modelData.connected ? 36 : 32
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0

                  Text {
                    text: netItem.modelData.ssid
                    color: Colors.net_ssid_text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Text {
                    visible: netItem.modelData.connected
                    text: "Connected"
                    color: Colors.net_connected_text
                    font.pixelSize: 10
                  }
                }

                Text {
                  visible: netItem.modelData.secured
                  text: "󰌾"
                  color: Colors.net_lock_icon
                  font.pixelSize: 12
                }

                Rectangle {
                  width: 40; height: 22
                  radius: 11
                  color: modelData.connected ? Colors.net_toggle_active_bg : Colors.net_toggle_inactive_bg
                  Behavior on color { ColorAnimation { duration: 150 } }

                  Text {
                    anchors.centerIn: parent
                    text: netItem.modelData.connected ? "On" : "Off"
                    color: modelData.connected ? Colors.net_toggle_active_text : Colors.net_toggle_inactive_text
                    font.pixelSize: 10
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var isConnected = netItem.modelData.connected === true || netItem.modelData.connected === "true"
                      if (isConnected) {
                        connectProcess.ssid = netItem.modelData.ssid
                        connectProcess.isDisconnecting = true
                        connectProcess.command = ["bash", "-c", "nmcli connection down '" + netItem.modelData.ssid + "'"]
                        connectProcess.running = true
                      } else {
                        checkKnownProcess.ssid = netItem.modelData.ssid
                        checkKnownProcess.running = true
                      }
                    }
                  }
                }
              }
            }
          }

          // ── Password Form ──
          ColumnLayout {
            anchors.fill: parent
            visible: root.showPasswordForm
            spacing: 12

            RowLayout {
              Layout.fillWidth: true

              Rectangle {
                width: 24; height: 24
                color: backHover.containsMouse ? Colors.pwd_back_btn_hovered : "transparent"
                radius: 4

                Text {
                  anchors.centerIn: parent
                  text: "󰁍"
                  font.pixelSize: 14
                  font.family: "JetBrainsMono Nerd Font"
                  color: Colors.pwd_back_btn_icon
                }

                MouseArea {
                  id: backHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.showPasswordForm = false
                }
              }

              Text {
                text: root.pendingSSID
                color: Colors.pwd_ssid_text
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.divider }

            Rectangle {
              Layout.fillWidth: true
              height: 36
              radius: 8
              color: Colors.pwd_input_bg
              border.color: passwordField.activeFocus ? Colors.pwd_input_border : Colors.outline_variant
              border.width: 1
              Behavior on border.color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                TextInput {
                  id: passwordField
                  Layout.fillWidth: true
                  echoMode: showPasswordToggle.checked ? TextInput.Normal : TextInput.Password
                  color: Colors.pwd_input_text
                  font.pixelSize: 12
                  font.family: "JetBrainsMono Nerd Font"
                  selectedTextColor: Colors.pwd_input_selected
                  selectionColor: Colors.pwd_input_selection
                  Keys.onReturnPressed: doConnect()
                  Keys.onEscapePressed: root.showPasswordForm = false
                }

                Rectangle {
                  width: 20; height: 20
                  color: "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: showPasswordToggle.checked ? "󰈈" : "󰈉"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.pwd_eye_icon
                  }

                  MouseArea {
                    id: showPasswordToggle
                    anchors.fill: parent
                    property bool checked: false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: checked = !checked
                  }
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 36
              radius: 8
              color: connectBtnHover.containsMouse ? Colors.pwd_connect_hovered : Colors.pwd_connect_bg
              Behavior on color { ColorAnimation { duration: 100 } }

              Text {
                anchors.centerIn: parent
                text: "Connect"
                color: connectBtnHover.containsMouse
                ? Colors.pwd_connect_text_hovered
                : Colors.pwd_connect_text
                font.pixelSize: 12
                font.bold: true
              }

              MouseArea {
                id: connectBtnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: doConnect()
              }
            }

            Item { Layout.fillHeight: true }
          }
        }
      }  
    } 

    // ── Toast Notification ──
    Rectangle {
      id: toastContainer
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 24
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(toastLabel.implicitWidth + 32, parent.width - 48)
      height: 32
      radius: 16
      
      color: Colors.toast_bg
      border.color: root.isToastError ? "#FF5252" : Colors.toast_border
      border.width: 1
      
      opacity: root.showToast ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

      Text {
        id: toastLabel
        anchors.centerIn: parent
        text: root.toastMsg
        width: Math.min(implicitWidth, parent.width - 32) 
        elide: Text.ElideRight
        color: Colors.toast_text
        font.pixelSize: 11
        font.bold: true
      }

      Timer {
        id: toastTimer
        interval: 3500 
        onTriggered: root.showToast = false
      }
    }
  }

  // Connect process 
  Process {
    id: connectProcess
    property string ssid: ""
    property bool isDisconnecting: false
    command: []

    stdout: StdioCollector {
      onStreamFinished: {
        if (connectProcess.isDisconnecting) return;

        var output = text.trim()
        
        if (output === "AUTH_FAILED") {
          root.displayToast("Incorrect password for " + connectProcess.ssid + "!", true)
          root.pendingSSID = connectProcess.ssid
          root.showPasswordForm = true
        } else if (output === "CONNECT_FAILED") {
          root.displayToast("Failed to connect to " + connectProcess.ssid, true)
        } else if (output === "SUCCESS") {
          root.displayToast("Successfully connected to " + connectProcess.ssid, false)
          root.showPasswordForm = false
        } else if (output === "ERROR_NO_SSID") {
          root.displayToast("Invalid SSID", true)
        }
      }
    }

    onRunningChanged: {
      if (running) {
        if (isDisconnecting) {
          root.displayToast("Disconnecting...", false)
        } else {
          root.displayToast("Connecting to " + connectProcess.ssid + "...", false)
        }
      } else {
        // Restart scan setelah connect/disconnect selesai
        scanProcess.running = false
        scanRestartTimer.interval = 1500
        scanRestartTimer.restart()
      }
    }
  }
}
