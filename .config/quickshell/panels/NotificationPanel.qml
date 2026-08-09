import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

PanelWindow {
  id: root

  implicitWidth: 300
  implicitHeight: 360

  property bool isShowing: false
  property var notifServer
  property string activeTab: "Recent"

  property var groupedList: {
    if (!notifServer || !notifServer.history) return []
    var now = Date.now()
    var oneHour = 60 * 60 * 1000
    var groups = {}
    var order = []

    for (var i = 0; i < notifServer.history.length; i++) {
      var item = notifServer.history[i]
      var app = item.appName || "Unknown"
      if (!groups[app]) {
        groups[app] = { appName: app, items: [], latestTimestamp: 0 }
        order.push(app)
      }
      groups[app].items.push({ originalIndex: i, data: item })
      if ((item.timestamp || 0) > groups[app].latestTimestamp)
        groups[app].latestTimestamp = item.timestamp || 0
    }

    var result = []
    for (var j = 0; j < order.length; j++) {
      var g = groups[order[j]]
      var isRecent = (now - g.latestTimestamp) < oneHour
      result.push({
        type: "group",
        appName: g.appName,
        items: g.items,
        section: isRecent ? "Recent" : "Earlier",
        count: g.items.length
      })
    }
    return result
  }

  property var filteredList: root.groupedList.filter(g => g.section === root.activeTab)

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
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
        GradientStop { position: 0.99; color: Colors.topbar_gradient6 }
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
        spacing: 8

        // Header
        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Notifications"
            color: Colors.header_title
            font.pixelSize: 14
            font.bold: true
            font.family: "Playfair Display"
            Layout.fillWidth: true
          }

          Rectangle {
            width: 20; height: 20
            color: clearArea.containsMouse ? Colors.action_btn_hovered : "transparent"
            radius: 4
            Text {
              anchors.centerIn: parent
              text: "󰃢"
              color: Colors.action_btn_icon
              font.pixelSize: 14
            }
            MouseArea {
              id: clearArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: notifServer.clearHistory()
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
          height: 2 
          color: Colors.divider
        }

        // Tab buttons
        RowLayout {
          Layout.fillWidth: true
          spacing: 4

          Repeater {
            model: ["Recent", "Earlier"]
            delegate: Rectangle {
              required property string modelData
              Layout.fillWidth: true
              height: 28
              radius: 6
              color: root.activeTab === modelData
                ? Colors.tab_active_bg : Colors.tab_inactive_bg

              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 11
                font.family: "Playfair Display"
                font.bold: root.activeTab === modelData
                color: root.activeTab === modelData
                  ? Colors.tab_active_text : Colors.tab_inactive_text
              }

              MouseArea {
                anchors.fill: parent
                onClicked: root.activeTab = modelData
              }
            }
          }
        }

        // List
        ListView {
          id: groupList
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          spacing: 4
          model: root.filteredList

          Text {
            anchors.centerIn: parent
            text: "No Notifications"
            color: Colors.text
            font.pixelSize: 12
            font.family: "Playfair Display"
            visible: groupList.count === 0
          }

          delegate: Item {
            id: groupDelegate
            required property int index
            required property var modelData

            width: groupList.width
            height: groupColumn.implicitHeight

            Column {
              id: groupColumn
              width: parent.width
              spacing: 3

              // App header 
              Rectangle {
                width: parent.width
                height: 24
                color: "transparent"
                visible: groupDelegate.modelData.count > 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8

                  Rectangle {
                    width: 6; height: 6
                    radius: 3
                    color: Colors.notif_group_dot
                    Layout.alignment: Qt.AlignVCenter
                  }

                  Text {
                    text: groupDelegate.modelData.appName
                    color: Colors.notif_group_title
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Playfair Display"
                    Layout.fillWidth: true
                  }

                  Text {
                    text: groupDelegate.modelData.count + " notifications"
                    color: Colors.notif_group_count
                    font.pixelSize: 9
                    font.family: "Playfair Display"
                  }
                }
              }

              // Notif items in group
              Repeater {
                model: groupDelegate.modelData.items

                delegate: Rectangle {
                  id: notifItem
                  required property var modelData

                  width: groupColumn.width
                  height: itemContent.implicitHeight + 16
                  color: notifArea.containsMouse ? Colors.notif_panel_item_hovered : Colors.notif_panel_item_bg

                  radius: 6

                  Behavior on color {
                    ColorAnimation { duration: 100 }
                  }

                  // Dismiss button 
                  Rectangle {
                    width: 16; height: 16
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 5
                    anchors.rightMargin: 5
                    color: dismissArea.containsMouse ? Colors.notif_dismiss_hovered : "transparent"
                    radius: 3
                    z: 2

                    Text {
                      anchors.centerIn: parent
                      text: "✕"
                      color: Colors.notif_dismiss_icon
                      font.pixelSize: 9
                    }

                    MouseArea {
                      id: dismissArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: notifServer.removeFromHistory(notifItem.modelData.originalIndex)
                    }
                  }

                  RowLayout {
                    id: itemContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 10
                    anchors.rightMargin: 26
                    anchors.topMargin: 8
                    spacing: 8

                    // App icon 
                    Rectangle {
                      visible: groupDelegate.modelData.count === 1
                      width: 42; height: 42
                      radius: 8
                      color: Colors.notif_icon_bg
                      Layout.alignment: Qt.AlignVCenter

                      Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        color: Colors.notif_icon
                        font.pixelSize: 16
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 1

                      // App name + time 
                      RowLayout {
                        Layout.fillWidth: true
                        visible: groupDelegate.modelData.count === 1

                        Text {
                          text: notifItem.modelData.data.appName
                          color: Colors.notif_app_name
                          font.pixelSize: 10
                          font.bold: true
                          font.family: "Playfair Display"
                          Layout.fillWidth: true
                          elide: Text.ElideRight
                        }

                        Text {
                          text: notifItem.modelData.data.time
                          color: Colors.notif_time
                          font.pixelSize: 9
                          font.family: "Playfair Display"
                        }
                      }

                      // Time 
                      Text {
                        visible: groupDelegate.modelData.count > 1
                        text: notifItem.modelData.data.time
                        color: Colors.notif_time_grouped
                        font.pixelSize: 9
                        font.family: "Playfair Display"
                      }

                      Text {
                        text: notifItem.modelData.data.summary
                        color: Colors.notif_summary
                        font.pixelSize: 11
                        font.family: "Playfair Display"
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      Text {
                        text: notifItem.modelData.data.body
                        color: Colors.notif_body
                        font.pixelSize: 10
                        font.family: "Playfair Display"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                      }
                    }
                  }

                  MouseArea {
                    id: notifArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onClicked: (mouse) => { mouse.accepted = false }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
