import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../services"
import ".."

PanelWindow {
  id: root

  implicitWidth: 280
  implicitHeight: Math.min(contentColumn.implicitHeight + 36, 560)

  property bool isShowing: false

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

  anchors { top: true; right: true }
  margins { top: 70; right: 10 }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  PwObjectTracker {
    id: tracker
    objects: Pipewire.nodes.values
  }

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
      id: innerRect
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.bottomMargin: 12
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.1; color: Colors.topbar_gradient5 }
        GradientStop { position: 0.9; color: Colors.topbar_gradient6 }
      }
      radius: 10
      border.color: Colors.outline_variant
      border.width: 2

      ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Audio Devices"
            color: Colors.header_title
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
          }
          Rectangle {
            width: 20; height: 20
            color: closeArea.containsMouse ? Colors.close_btn_hovered : "transparent"
            radius: 4
            Text { anchors.centerIn: parent; text: "✕"; color: Colors.close_btn_icon; font.pixelSize: 12 }
            MouseArea {
              id: closeArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.requestClose()
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Colors.divider }

        // Output Label
        Text {
          text: "Output"
          color: Colors.header_title
          font.pixelSize: 12
          font.bold: true
        }

        ScriptModel {
          id: outputModel
          values: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
        }

        // Output List
        ListView {
          id: outputList
          Layout.fillWidth: true
          Layout.preferredHeight: outputModel.values.length * 48
          clip: true
          spacing: 4
          model: outputModel

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            contentItem: Rectangle {
              implicitWidth: 2; implicitHeight: 2; radius: 2
              color: Colors.scrollbar_thumb
              opacity: parent.pressed ? 1.0 : parent.hovered ? 0.8 : 0.5
            }
            background: Rectangle {
              implicitWidth: 2; radius: 2
              color: Colors.scrollbar_track
              opacity: 0.5
            }
          }

          delegate: Rectangle {
            required property var modelData
            readonly property bool isDefault: Pipewire.defaultAudioSink !== null
                                              && modelData.id === Pipewire.defaultAudioSink.id

            width: ListView.view.width
            height: 44
            radius: 6
            color: isDefault
              ? (Colors.isDark ? Colors.audio_item_active_bg : Qt.alpha(Colors.audio_item_active_bg, 0.3))
              : Colors.audio_item_inactive_bg

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 8

              Text {
                text: "󰕾"
                color: isDefault ? Colors.audio_item_active_icon : Colors.audio_item_inactive_icon
                font.pixelSize: 16
              }

              Text {
                text: modelData.description || modelData.name || ""
                color: Colors.audio_item_text
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Rectangle {
                width: 40; height: 22
                radius: 11
                color: isDefault ? Colors.audio_toggle_active_bg : Colors.audio_toggle_inactive_bg
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  anchors.centerIn: parent
                  text: isDefault ? "✓" : "Set"
                  color: isDefault ? Colors.audio_toggle_active_text : Colors.audio_toggle_inactive_text
                  font.pixelSize: 10
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Colors.divider }

        // Input Label
        Text {
          text: "Input"
          color: Colors.header_title
          font.pixelSize: 12
          font.bold: true
        }

        ScriptModel {
          id: inputModel
          values: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio !== null)
        }

        // Input List
        ListView {
          id: inputList
          Layout.fillWidth: true
          Layout.preferredHeight: inputModel.values.length * 48
          clip: true
          spacing: 4
          model: inputModel

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            contentItem: Rectangle {
              implicitWidth: 2; implicitHeight: 2; radius: 2
              color: Colors.scrollbar_thumb
              opacity: parent.pressed ? 1.0 : parent.hovered ? 0.8 : 0.5
            }
            background: Rectangle {
              implicitWidth: 2; radius: 2
              color: Colors.scrollbar_track
              opacity: 0.5
            }
          }

          delegate: Rectangle {
            required property var modelData
            readonly property bool isDefault: Pipewire.defaultAudioSource !== null
                                              && modelData.id === Pipewire.defaultAudioSource.id

            width: ListView.view.width
            height: 44
            radius: 6
            color: isDefault
              ? (Colors.isDark ? Colors.audio_item_active_bg : Qt.alpha(Colors.audio_item_active_bg, 0.3))
              : Colors.audio_item_inactive_bg

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 8

              Text {
                text: "󰍬"
                color: isDefault ? Colors.audio_item_active_icon : Colors.audio_item_inactive_icon
                font.pixelSize: 16
              }

              Text {
                text: modelData.description || modelData.name || ""
                color: Colors.audio_item_text
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Rectangle {
                width: 40; height: 22
                radius: 11
                color: isDefault ? Colors.audio_toggle_active_bg : Colors.audio_toggle_inactive_bg
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  anchors.centerIn: parent
                  text: isDefault ? "✓" : "Set"
                  color: isDefault ? Colors.audio_toggle_active_text : Colors.audio_toggle_inactive_text
                  font.pixelSize: 10
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
              }
            }
          }
        }

        // Bottom padding
        Item { Layout.fillWidth: true; height: 4 }
      }
    }
  }
}
