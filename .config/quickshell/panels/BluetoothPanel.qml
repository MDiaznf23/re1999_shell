import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import Quickshell.Bluetooth
import "../services"
import ".."

PanelWindow {
  id: root

  implicitWidth: 280
  implicitHeight: 320

  property bool isShowing: false
  property string toastMsg: ""
  property bool isToastError: false
  property bool showToast: false

  function displayToast(msg, isError) {
    root.toastMsg = msg
    root.isToastError = isError
    root.showToast = true
    toastTimer.restart()
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

  anchors {
    top: true
    right: true
  }

  margins {
    top: 70
    right: 10
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  signal requestClose()

  Rectangle {
    id: mainRect
    anchors.fill: parent
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
      radius: 10
      border.color: Colors.outline_variant
      border.width: 2

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Bluetooth"
            color: Colors.header_title 
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
          }

          Rectangle {
            width: 32; height: 16
            radius: 8
            color: BluetoothService.enabled ? Colors.bt_toggle_active_bg : Colors.bt_toggle_inactive_bg

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              width: 12; height: 12
              radius: 8
              color: Colors.bt_toggle_knob
              anchors.verticalCenter: parent.verticalCenter
              x: BluetoothService.enabled ? 18 : 3

              Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: BluetoothService.toggle()
            }
          }

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

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Colors.divider
        }

        Text {
          visible: !BluetoothService.available
          text: "No adapter Bluetooth"
          color: Colors.text_variant1
          font.pixelSize: 12
          Layout.alignment: Qt.AlignHCenter
        }

        Text {
          visible: BluetoothService.available && !BluetoothService.enabled
          text: "Bluetooth is off"
          color: Colors.text_variant1
          font.pixelSize: 12
          Layout.alignment: Qt.AlignHCenter
        }

        ListView {
          id: deviceList
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          spacing: 6
          visible: BluetoothService.enabled
          model: BluetoothService.allDevices

          Text {
            anchors.centerIn: parent
            text: "No devices"
            color: Colors.text_variant1
            font.pixelSize: 12
            visible: deviceList.count === 0
          }

          delegate: Rectangle {
            id: deviceItem
            required property var modelData

            // Identitas unik pakai address, BUKAN name
            readonly property string deviceAddress: modelData.address
            readonly property bool isConnected: modelData.connected

            // isProcessing dicomputasi dari singleton — tidak bisa ada dua device processing
            readonly property bool isProcessing: BluetoothService.connectingAddress === deviceAddress

            // Ketika koneksi selesai (connected berubah), beritahu service untuk clear
            onIsConnectedChanged: {
                BluetoothService.clearConnecting(deviceAddress)
            }

            width: deviceList.width
            height: 55
            color: deviceArea.containsMouse
                ? Colors.isDark ? Colors.bt_device_item_hovered : Qt.alpha(Colors.bt_device_item_hovered, 0.3)
                : Colors.bt_device_item_bg
            radius: 6

            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: -2
                    text: {
                        var ic = deviceItem.modelData.icon
                        if (ic.includes("headset") || ic.includes("headphone") || ic.includes("audio")) return "󰋋"
                        if (ic.includes("phone"))    return "󰄜"
                        if (ic.includes("keyboard")) return "󰌌"
                        if (ic.includes("mouse"))    return "󰍽"
                        if (ic.includes("computer")) return "󰇄"
                        return "󰂯"
                    }
                    color: deviceItem.isConnected ? Colors.bt_device_icon_connected : Colors.bt_device_icon_disconnected
                    font.pixelSize: 32
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: deviceItem.modelData.name
                        color: Colors.bt_device_name
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: deviceItem.isProcessing || deviceItem.isConnected || deviceItem.modelData.paired
                        text: {
                            if (deviceItem.isProcessing) return deviceItem.isConnected ? "Disconnecting..." : "Connecting..."
                            if (deviceItem.isConnected) return "Connected"
                            if (deviceItem.modelData.paired) return "Paired"
                            return ""
                        }
                        color: deviceItem.isProcessing
                            ? Colors.bt_device_status_processing
                            : deviceItem.isConnected
                                ? Colors.bt_device_status_connected
                                : Colors.bt_device_status_paired
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 40; height: 22
                    radius: 11
                    color: deviceItem.isProcessing
                        ? Colors.bt_device_toggle_loading_bg
                        : deviceItem.isConnected
                            ? Colors.bt_device_toggle_active_bg
                            : Colors.bt_device_toggle_inactive_bg
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: deviceItem.isProcessing ? "..." : (deviceItem.isConnected ? "On" : "Off")
                        color: deviceItem.isProcessing
                            ? Colors.bt_device_toggle_loading_text
                            : deviceItem.isConnected
                                ? Colors.bt_device_toggle_active_text
                                : Colors.bt_device_toggle_inactive_text
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: deviceArea
                anchors.fill: parent
                hoverEnabled: true

                // Disable klik kalau ada device lain yang sedang diproses
                enabled: BluetoothService.connectingAddress === "" || BluetoothService.connectingAddress === deviceItem.deviceAddress

                onClicked: {
                    // Panggil lewat service, bukan langsung ke modelData
                    BluetoothService.connectDevice(deviceItem.deviceAddress)

                    var actionMsg = deviceItem.isConnected
                        ? "Disconnecting from " + deviceItem.modelData.name + "..."
                        : "Connecting to " + deviceItem.modelData.name + "..."
                    root.displayToast(actionMsg, false)
                }
            }
        }
        }

        Item {
          Layout.fillHeight: true
          visible: !BluetoothService.enabled
        } 
      }

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
          width: Math.min(implicitWidth, parent.width - 32)
          elide: Text.ElideRight
          text: root.toastMsg
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
  }
}
