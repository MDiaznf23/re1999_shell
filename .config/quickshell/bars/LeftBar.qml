import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import "../panels"
import "../services"
import ".."

PanelWindow {
  id: leftBar
  anchors { top: true; bottom: true; left: true }
  implicitWidth: 72
  color: "transparent"

  property string activePopup: ""
  signal requestPowerMenu()
  signal menuClicked()
  signal toggleShellHidden()
  property bool shellHidden: false

  function togglePopup(name) {
    activePopup = (activePopup === name) ? "" : name
  }

  // ─── Bar body ─────────────────────────────────────────────────────────────
  Rectangle {
    anchors {
      top: parent.top
      bottom: parent.bottom
      left: parent.left
      topMargin: 12
      bottomMargin: 12
    }
    width: 72
    radius: 14
    color: "transparent"
    border.color: "transparent"
    border.width: 1.5

    ColumnLayout {
  anchors {
    top: parent.top
    bottom: parent.bottom
    horizontalCenter: parent.horizontalCenter
  }

  Item { Layout.fillHeight: true }

  BarButton {
    visible: !leftBar.shellHidden
    iconSource: "../assets/power.svg"
    label: "Power"
    active: false
    onClicked: {
      activePopup = ""
      leftBar.requestPowerMenu()
    }
  }

  Process {
    id: fileManagerProcess
    command: ["dolphin"]
  }

  BarButton {
    visible: !leftBar.shellHidden
    iconSource: "../assets/folder.svg"
    label: "Files"
    active: false
    onClicked: fileManagerProcess.running = true
  }

  BarButton {
    visible: !leftBar.shellHidden
    iconSource: "../assets/music.svg"
    label: "Media"
    active: leftBar.activePopup === "media"
    onClicked: leftBar.togglePopup("media")
  }

  BarButton {
    visible: !leftBar.shellHidden
    iconSource: "../assets/menu.svg"
    label: "Menu"
    active: false
    onClicked: {
      activePopup = ""
      leftBar.menuClicked()
    }
  }

  Item { Layout.fillHeight: true }

  Item {
    Layout.alignment: Qt.AlignHCenter
    width: 48
    height: 48
    // eye item tidak pakai visible binding — selalu tampil

    Image {
      id: svgIcon
      anchors.fill: parent
      source: leftBar.shellHidden ? "../assets/eye-on-svgrepo-com.svg" : "../assets/eye-off-svgrepo-com.svg"
      fillMode: Image.PreserveAspectFit
      sourceSize.width: 48
      sourceSize.height: 48
      visible: false
      smooth: true
    }

    ColorOverlay {
      anchors.fill: svgIcon
      source: svgIcon
      color: leftBar.shellHidden ? "#C9A84C" : "#FFFFFF"
      opacity: 1.0
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: leftBar.toggleShellHidden()
    }
  }
}
  }

  // ─── Media Popup ──────────────────────────────────────────────────────────
  PopupWindow {
    id: mediaPopup
    visible: leftBar.activePopup === "media"
    color: "transparent"

    property real screenW: Quickshell.screens[0].width
    property real screenH: Quickshell.screens[0].height
    property real barWidth: leftBar.implicitWidth

    implicitWidth: screenW - barWidth
    implicitHeight: screenH

    anchor {
      window: leftBar
      edges: Edges.Top | Edges.Bottom | Edges.Right
      rect: Qt.rect(barWidth, 0, screenW - barWidth, screenH)
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: false
      onClicked: leftBar.activePopup = ""
    }

    Item {
      id: mediaBox
      readonly property real anchorRegionHeight: 980
      x: 4
      y: (anchorRegionHeight - height) / 2
      width: mediaContent.implicitWidth + 30
      height: mediaContent.implicitHeight + 30 + 12

      opacity: mediaPopup.visible ? 1 : 0
      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      transform: Translate {
        x: mediaPopup.visible ? 0 : -24
        Behavior on x {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
      }

      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0.0; color: Colors.topbar_gradient1 }
          GradientStop { position: 0.5; color: Colors.topbar_gradient2 }
          GradientStop { position: 1.0; color: Colors.topbar_gradient3 }
        }
        radius: 12
        border.color: Colors.outline_variant
        border.width: 1.5
        clip: true

        MouseArea {
          anchors.fill: parent
          onClicked: {} 
        }

        Media {
          id: mediaContent
          anchors.centerIn: parent
        }
      }
    }
  }

  // ─── Placeholder Popup ────────────────────────────────────────────────────
  PopupWindow {
    id: placeholderPopup
    visible: leftBar.activePopup !== "" && leftBar.activePopup !== "media"
    implicitWidth: 220
    implicitHeight: 80
    color: "transparent"

    anchor {
      window: leftBar
      edges: Edges.Right
      rect: Qt.rect(
        -2,
        (leftBar.height - implicitHeight) / 2,
        leftBar.implicitWidth,
        implicitHeight
      )
    } 
  }
}
