import QtQuick
import Quickshell.Io
import QtQuick.Shapes
import QtQuick.Layouts 
import Quickshell
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../services"
import ".."

PanelWindow {
  id: topBar
  signal menuClicked()
  signal panelClicked()
  signal clipboardClicked()
  property bool isOpen: false
  property bool isMenuOpen: false
  property bool anyPanelOpen: false
  property bool shellHidden: false
  signal requestShellSettings()
  anchors { top: true; left: true; right: true }
  implicitHeight: 100

  color: "transparent"
  property int borderHeight: 2

  Timer {
    id: batteryHideTimer
    interval: 200
    onTriggered: batteryPopup.visible = false
  }

  Timer {
    id: btHideTimer
    interval: 200
    onTriggered: btPopup.visible = false
  }

  Timer {
    id: wifiHideTimer
    interval: 200
    onTriggered: wifiPopup.visible = false
  }

  // Background 
  Rectangle {
    id: topPanel
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    color: "transparent"
        
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 15 
      anchors.rightMargin: 15
      spacing: 11
      transform: Translate { y: -1 }
      visible: !topBar.shellHidden
      opacity: topBar.shellHidden ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 200 } }

      Item {
        width: 80
        height: parent.height

        ColumnLayout {
          anchors.centerIn: parent
          spacing: -14

          Item {
            width: 80
            height: 80
            Layout.alignment: Qt.AlignHCenter

            // Oval 1 — horizontal
            Item {
              id: orbitContainer
              anchors.centerIn: parent
              width: 80
              height: 80
              z: 1

              // Orbit shape (sama seperti punyamu)
              Shape {
                  id: orbitShape
                  anchors.centerIn: parent
                  width: 80
                  height: 80
                  z: 1
                  ShapePath {
                      strokeColor: Colors.text_variant2
                      strokeWidth: 1.5
                      fillColor: "transparent"
                      PathAngleArc {
                          centerX: 40; centerY: 40
                          radiusX: 40
                          radiusY: 20
                          startAngle: 0
                          sweepAngle: 360
                      }
                  }
                  transform: Rotation {
                      origin.x: 40; origin.y: 40
                      angle: +25
                  }
              }

              // Bola yang berjalan di orbit
              Rectangle {
                  id: orbitBall
                  width: 8
                  height: 8
                  radius: 4
                  color: Colors.text_variant2
                  z: 2

                  property real angleDeg: 0

                  // posisi dihitung dari ellipse, lalu diputar +25 derajat sesuai rotasi orbit
                  x: {
                      var rad = angleDeg * Math.PI / 180
                      var ex = 40 + 40 * Math.cos(rad)
                      var ey = 40 + 20 * Math.sin(rad)
                      var rot = 25 * Math.PI / 180
                      var rx = 40 + (ex - 40) * Math.cos(rot) - (ey - 40) * Math.sin(rot)
                      return rx - width / 2
                  }
                  y: {
                      var rad = angleDeg * Math.PI / 180
                      var ex = 40 + 40 * Math.cos(rad)
                      var ey = 40 + 20 * Math.sin(rad)
                      var rot = 25 * Math.PI / 180
                      var ry = 40 + (ex - 40) * Math.sin(rot) + (ey - 40) * Math.cos(rot)
                      return ry - height / 2
                  }

                  NumberAnimation on angleDeg {
                      from: 0
                      to: 360
                      duration: 4000
                      loops: Animation.Infinite
                      running: true
                  }
              }
            }

            // Oval 2 — dirotasi ~-35 derajat
            Shape {
              anchors.centerIn: parent
              width: 80
              height: 80
              ShapePath {
                  strokeColor: "transparent"
                  strokeWidth: 1.5
                  fillColor: Colors.topbar_gradient4
                  PathAngleArc {
                      centerX: 40; centerY: 40
                      radiusX: 40
                      radiusY: 18
                      startAngle: 0
                      sweepAngle: 360
                  }
              }
              transform: Rotation {
                  origin.x: 40; origin.y: 40
                  angle: -20
              }
            }

              // Ikon di tengah
            Item {
              width: 20
              height: 20
              anchors.centerIn: parent
              Image {
                id: iconImg
                anchors.fill: parent
                source: Qt.resolvedUrl(Quickshell.shellDir + "/assets/CachyOS.svg")
                sourceSize.width: 20
                sourceSize.height: 20
                visible: false
              }
              ColorOverlay {
                anchors.fill: iconImg
                source: iconImg
                color: "#FFFFFF"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: requestShellSettings()
              }
            }
          }

          Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: -2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(StateGlobals.clockDate, "hh:mm")
                color: "#FFFFFF"
                font.pixelSize: 14
                font.family: "Josefin Sans"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(StateGlobals.clockDate, "ddd, dd MMM")
                color: "#FFFFFF"
                font.pixelSize: 12
                font.family: "Playfair Display"
            }
          }
        }
      }

      RowLayout {
        spacing: 4

        Rectangle {
          id: workspaceRect
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredWidth: workspaceLayout.width + 10 
          height: 80
          color: "transparent"
          
          property var workspaceList: []

          Process {
            id: hyprDispatch
            running: false 
            command: []    
          }

          Process {
            id: workProc
            running: true
            command: ["bash", Quickshell.shellDir + "/scripts/get-workspaces.sh"]
            
            stdout: SplitParser {
              onRead: function(data) {
                try {
                  if (data.trim() !== "") {
                    var newList = JSON.parse(data).sort((a, b) => a.id - b.id)
                    if (JSON.stringify(newList) !== JSON.stringify(workspaceRect.workspaceList)) {
                      workspaceRect.workspaceList = newList
                    }
                  }
                } 
                catch(e) {
                  console.log("JSON Error: " + e)
                }
              }
            } 
          }

          RowLayout {
            id: workspaceLayout
            anchors.centerIn: parent
            spacing: 7 

            Repeater {
              id: workspaceRepeater
              model: workspaceRect.workspaceList

              Item {
                id: workspaceItem
                width: hasApp ? (appRow.width+6) : (modelData.focused ? 32 : 24)
                height: 14

                property var workspaceData: modelData 
                property bool isFocused: modelData.focused
                property bool hasApp: modelData.apps && modelData.apps.length > 0

                property int offset: 0
                property int maxVisible: 3
                property var visibleApps: {
                  var all = workspaceData.apps
                  if (!all || all.length <= maxVisible) return all ?? []
                  var result = []
                  for (var i = 0; i < maxVisible; i++) {
                      result.push(all[(offset + i) % all.length])
                  }
                  return result
                }

                Timer {
                  interval: 5000
                  running: workspaceItem.workspaceData.apps && workspaceItem.workspaceData.apps.length > workspaceItem.maxVisible
                  repeat: true
                  onTriggered: workspaceItem.offset = (workspaceItem.offset + 1) % workspaceItem.workspaceData.apps.length
                }

                Rectangle{
                  anchors.fill: appRow
                  anchors.topMargin: -1    
                  anchors.bottomMargin: -1
                  anchors.leftMargin: -5 
                  anchors.rightMargin: -5
                  radius: 12
                  visible: parent.hasApp

                  color: workspaceItem.isFocused 
                  ? Colors.isDark ? Qt.alpha(Colors.container_level_2, 0.8) : Qt.alpha(Colors.container_level_2, 0.9)
                  : Qt.alpha(Colors.container_level_2_variant1, 0.5)
                  Behavior on color { ColorAnimation { duration: 200 } }
                }

                Row {
                  id: appRow
                  anchors.centerIn: parent
                  spacing: 3 
                  visible: parent.hasApp

                  Repeater {
                    model: workspaceItem.visibleApps

                    Image {
                      width: 32
                      height: 32
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                      sourceSize: Qt.size(31, 32)
                      source: {
                        var cls = modelData.class.toLowerCase()

                        var entry = DesktopEntries.heuristicLookup(cls)

                        if (!entry) {
                          var all = DesktopEntries.applications.values
                          for (var i = 0; i < all.length; i++) {
                            if (all[i].name.toLowerCase() === cls || all[i].id.toLowerCase() === cls) {
                              entry = all[i]
                              break
                            }
                          }
                        }

                        if (!entry || !entry.icon) {
                          var steamMatch = cls.match(/^steam_app_(\d+)$/)
                          if (steamMatch) {
                            var appId = steamMatch[1]
                            var all2 = DesktopEntries.applications.values
                            for (var j = 0; j < all2.length; j++) {
                              if (all2[j].execString && all2[j].execString.indexOf("rungameid/" + appId) !== -1) {
                                entry = all2[j]
                                break
                              }
                            }
                          }
                        }

                        if (entry && entry.icon) {
                          if (entry.icon.charAt(0) === "/") {
                            return "file://" + entry.icon
                          }
                          var path = Quickshell.iconPath(entry.icon, true)
                          if (path) return path
                        }

                        var path2 = Quickshell.iconPath(cls, true)
                        if (path2) return path2

                        return Qt.resolvedUrl(Quickshell.shellDir + "/assets/error.png")
                      }
                      opacity: workspaceItem.isFocused ? 1.0 : 0.5
                      Behavior on opacity { NumberAnimation { duration: 300 } }
                    }          
                  }
                }

                Rectangle {
                  anchors.centerIn: parent
                  width: modelData.focused ? 32 : 24
                  height: modelData.focused ? 32 : 24
                  radius: 32
              
                  visible: !parent.hasApp 

                  color: modelData.focused 
                    ? Qt.alpha(Colors.container_level_2, 0.8) 
                    : Qt.alpha(Colors.container_level_2_variant1, 0.7)
              
                  Behavior on width { NumberAnimation { duration: 200 } }
                  Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    hyprDispatch.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + modelData.id.toString() + " })"]
                    hyprDispatch.running = true
                  }
                }
              } 
            }
          }
        }
      }

      Text {
        id: iconText
        text: StateGlobals.weatherIcon
        color: Colors.icon_on_container
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 32
        transform: Translate { y: -4 }
      }

      // Spacer
      Item { 
        Layout.fillWidth: true 
      } 

      Row {
        spacing: 12

        Rectangle {
          id: wifiRect
          width: wifiLayout.width
          height: 32
          color: "transparent"
          radius: 15

          RowLayout {
            id: wifiLayout
            anchors.centerIn: parent
            spacing: -30 

            Text {
              text: StateGlobals.wifiIcon
              color: Colors.text_variant1
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 40
              transform: Translate { y: -2 }
              z: 1
            }

            Rectangle {
              color: Qt.alpha(Colors.topbar_gradient1, 0.8)
              radius: 2
              implicitWidth: wifiDescText.implicitWidth + 40
              implicitHeight: 24
              Text {
                id: wifiDescText
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                text: StateGlobals.wifiSSID
                color: Colors.text_variant1
                font.family: "Playfair Display"
                font.pixelSize: 16
              }
            } 
          }
        }

        // Rectangle 2: Battery
        Rectangle {
          id: batteryRect
          width: batLayout.width
          height: 32
          color: "transparent"
          radius: 15
          RowLayout {
            id: batLayout
            anchors.centerIn: parent
            spacing: -32
            Text {
              text: StateGlobals.batIcon
              color: Colors.text_variant1
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 40
              transform: Translate { y: -2 }
              z: 1
            }
            Rectangle {
              color: Qt.alpha(Colors.topbar_gradient1, 0.8)
              radius: 2
              implicitWidth: batDescText.implicitWidth + 48
              implicitHeight: 24
              Text {
                id: batDescText
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.verticalCenter: parent.verticalCenter
                text: StateGlobals.batDesc
                color: Colors.text_variant1
                font.family: "Josefin Sans"
                font.pixelSize: 16
              }
            }
          }
        }

        Rectangle {
          id: btRect
          width: btLayout.width
          height: 32
          color: "transparent"
          radius: 15
          RowLayout {
            id: btLayout
            anchors.centerIn: parent
            spacing: -32
            Text {
              text: BluetoothService.icon
              color: Colors.text_variant1
              font.pixelSize: 40
              font.family: "JetBrainsMono Nerd Font"
              transform: Translate { y: -3 }
              z: 1
            }
            Rectangle {
              color: Qt.alpha(Colors.topbar_gradient1, 0.8)
              radius: 2
              implicitWidth: btDescText.implicitWidth + 48
              implicitHeight: 24
              Text {
                id: btDescText
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.verticalCenter: parent.verticalCenter
                text: BluetoothService.hasConnected
                ? BluetoothService.connectedDevices[0].name
                : "No device"
                color: Colors.text_variant1
                font.family: "Playfair Display"
                font.pixelSize: 16
              }
            }
          }
        }
      }

      Text {
        text: ""
        color: Colors.text_variant1
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 24
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: topBar.panelClicked()
        }
      }
    } 
  }   
}
