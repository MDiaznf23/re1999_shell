import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../services"
import ".."

Item {
  id: root
  implicitWidth: mediaRow.width
  implicitHeight: mediaRow.height

  property bool showDropdown: false

  // --- REVERSE:1999 PALETTE ---
  property color r99_ink: "#1c1712"
  property color r99_paper: "#e9ddc6"
  property color r99_paper_dim: "#bfae8c"
  property color r99_accent: "#c97b4a"
  property color r99_accent_dim: "#8a5636"
  property color r99_gold: "#d9b26a"
  property color r99_gold_dim: "#a3895c"

  function formatTime(us) {
    var s = Math.floor((us || 0) / 1000000)
    var m = Math.floor(s / 60)
    return m + ":" + String(s % 60).padStart(2, "0")
  }

  Row {
    id: mediaRow
    spacing: 12

    // --- COVER ART, vignette ---
    Item {
      id: coverFrame
      width: 130
      height: 130
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "transparent"
        border.width: 2
        border.color: root.r99_gold_dim
      }

      Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 8
        color: root.r99_ink
        z: 0
      }

      ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 8
        z: 1

        Item {
          anchors.fill: parent

          Image {
            id: coverImage
            anchors.fill: parent
            source: MediaState.mediaData.cover ? "file://" + MediaState.mediaData.cover : ""
            visible: MediaState.mediaData.cover !== undefined && MediaState.mediaData.cover !== ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            opacity: 0
            Behavior on opacity {
              NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
            onVisibleChanged: opacity = visible ? 1 : 0
          }

          Rectangle {
            anchors.fill: parent
            radius: 8
            gradient: Gradient {
              orientation: Gradient.Vertical
              GradientStop { position: 0.0; color: "#33000000" }
              GradientStop { position: 0.6; color: "#00000000" }
              GradientStop { position: 1.0; color: "#66000000" }
            }
          }
        }
      }

      Text {
        text: "✦"
        color: root.r99_gold
        font.pixelSize: 12
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 4
        opacity: 0.85
        z: 2
      }
    }

    // --- info, player selector, progress, controls ---
    Column {
      spacing: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 220

      // player selector
      Item {
        width: parent.width
        height: 16

        MouseArea {
          id: dropdownToggle
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.showDropdown = !root.showDropdown

          Row {
            spacing: 4
            Text {
              text: "♫ " + (MediaState.mediaData.player || "No Player")
              color: root.r99_paper_dim
              font.family: "Josefin Sans"
              font.letterSpacing: 0.5
              font.pixelSize: 10
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.showDropdown ? "▲" : "▼"
              color: root.r99_gold_dim
              font.pixelSize: 7
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      // label card: title / divider / artist / status
      Item {
        id: labelCard
        width: parent.width
        height: titleColumn.height + 12

        Canvas {
          anchors.fill: parent
          antialiasing: true
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = root.r99_gold_dim
            ctx.lineWidth = 1
            var notch = 10
            ctx.beginPath()
            ctx.moveTo(0, 6)
            ctx.lineTo(0, height - 6)
            ctx.lineTo(6, height)
            ctx.lineTo(width - notch, height)
            ctx.lineTo(width, height - notch)
            ctx.lineTo(width, 6)
            ctx.lineTo(width - 6, 0)
            ctx.lineTo(6, 0)
            ctx.closePath()
            ctx.stroke()
          }
        }

        Column {
          id: titleColumn
          spacing: 3
          width: parent.width - 16
          anchors.centerIn: parent

          Text {
            text: MediaState.mediaData.title || "No Song Playing"
            color: root.r99_paper
            font.family: "Playfair Display"
            font.weight: Font.DemiBold
            font.pixelSize: 14
            width: parent.width
            elide: Text.ElideRight
          }

          Row {
            spacing: 3
            Repeater {
              model: 20
              Rectangle {
                width: 2; height: 1
                color: root.r99_gold_dim
                opacity: 0.6
              }
            }
          }

          Row {
            width: parent.width
            spacing: 8

            Text {
              text: MediaState.mediaData.artist || "Unknown Artist"
              color: root.r99_paper_dim
              font.family: "Josefin Sans"
              font.letterSpacing: 0.4
              font.pixelSize: 10
              elide: Text.ElideRight
            }

            Text {
              text: MediaState.mediaData.status || ""
              color: MediaState.mediaData.status === "Playing"
                ? root.r99_accent
                : root.r99_paper_dim
              font.family: "Josefin Sans"
              font.pixelSize: 9
              font.capitalization: Font.AllUppercase
              font.letterSpacing: 1
            }
          }
        }
      }

      // progress bar + timer
      Row {
        spacing: 6
        width: parent.width

        Text {
          text: root.formatTime(MediaState.mediaData.position)
          color: root.r99_gold_dim
          font.family: "Josefin Sans"
          font.pixelSize: 9
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          id: progressWrapper
          width: parent.width - 80
          height: 16
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            id: remainingBar
            x: waveCanvas.currentW
            width: parent.width - x
            height: 2
            radius: 1
            anchors.verticalCenter: parent.verticalCenter
            color: root.r99_accent_dim
            opacity: 0.4
          }

          Canvas {
            id: waveCanvas
            anchors.fill: parent
            antialiasing: true

            property int marginLeft: 4
            property real currentW: Math.max(marginLeft, width * progress)
            property real phase: 0
            property bool isPlaying: MediaState.mediaData.status === "Playing"

            property real rawProgress: (MediaState.mediaData.length > 0)
              ? Math.min((MediaState.mediaData.position / MediaState.mediaData.length), 1.0)
              : 0

            property real progress: rawProgress
            Behavior on progress {
              NumberAnimation { duration: 1000; easing.type: Easing.Linear }
            }

            NumberAnimation on phase {
              from: 0; to: Math.PI * 2
              duration: 3000
              loops: Animation.Infinite
              running: waveCanvas.isPlaying
            }

            onPhaseChanged: requestPaint()
            onProgressChanged: requestPaint()
            onIsPlayingChanged: requestPaint()

            onPaint: {
              var ctx = getContext("2d");
              ctx.reset();

              var w = currentW;
              var h = height / 2;
              var amplitude = isPlaying ? 3 : 0;
              var frequency = 0.2;

              var grad = ctx.createLinearGradient(0, 0, w, 0);
              grad.addColorStop(0, root.r99_gold);
              grad.addColorStop(1, root.r99_accent);

              ctx.beginPath();
              ctx.lineWidth = 2.5;
              ctx.lineCap = "round";
              ctx.strokeStyle = grad;
              ctx.moveTo(0, h);

              for (var x = 0; x <= w; x++) {
                var fadeIn = (x < 15) ? x / 15 : 1;
                var fadeOut = (w - x < 10) ? (w - x) / 10 : 1;
                var y = h + Math.sin(x * frequency - phase) * (amplitude * fadeIn * fadeOut);
                ctx.lineTo(x, y);
              }

              ctx.stroke();
            }
          }

          Rectangle {
            width: 10
            height: 10
            radius: 5
            x: waveCanvas.currentW - (width / 2)
            anchors.verticalCenter: parent.verticalCenter
            color: root.r99_paper
            border.width: 2
            border.color: root.r99_gold
          }
        }

        Text {
          text: root.formatTime(MediaState.mediaData.length)
          color: root.r99_gold_dim
          font.family: "Josefin Sans"
          font.pixelSize: 9
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // control
      Row {
        spacing: 18
        height: 32

        Item {
          width: 28; height: 28
          anchors.verticalCenter: parent.verticalCenter
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: MediaState.executePlayerctl("previous")
            Text {
              anchors.centerIn: parent
              text: "󰒮"
              color: root.r99_paper_dim
              font.pixelSize: 18
            }
          }
        }

        Item {
          width: 32; height: 32
          anchors.verticalCenter: parent.verticalCenter
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: MediaState.executePlayerctl("play-pause")

            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: "transparent"
              border.width: 1.5
              border.color: root.r99_gold
            }

            Text {
              anchors.centerIn: parent
              text: MediaState.mediaData.status === "Playing" ? "󰏤" : "󰐊"
              color: root.r99_accent
              font.pixelSize: 18
            }
          }
        }

        Item {
          width: 28; height: 28
          anchors.verticalCenter: parent.verticalCenter
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: MediaState.executePlayerctl("next")
            Text {
              anchors.centerIn: parent
              text: "󰒭"
              color: root.r99_paper_dim
              font.pixelSize: 18
            }
          }
        }
      }
    }
  }

  // --- DROPDOWN PLAYER LIST ---
  Rectangle {
    visible: root.showDropdown && MediaState.playerList.length > 0
    width: 150
    height: MediaState.playerList.length * 26
    color: root.r99_ink
    radius: 6
    z: 9999
    border.color: root.r99_gold_dim
    border.width: 1
    anchors.top: mediaRow.top
    anchors.left: mediaRow.left
    anchors.leftMargin: 102
    anchors.topMargin: 18

    Column {
      anchors.fill: parent
      anchors.margins: 2

      Repeater {
        model: MediaState.playerList

        MouseArea {
          width: 146
          height: 26
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true

          onClicked: {
            MediaState.selectedPlayer = modelData.player
            root.showDropdown = false
          }

          Rectangle {
            anchors.fill: parent
            color: parent.containsMouse ? "#33c97b4a" : "transparent"
            radius: 4
          }

          Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
              text: modelData.player
              color: MediaState.selectedPlayer === modelData.player
                ? root.r99_accent
                : root.r99_paper_dim
              font.family: "Josefin Sans"
              font.pixelSize: 11
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "●"
              color: modelData.status === "Playing"
                ? root.r99_accent
                : root.r99_paper_dim
              font.pixelSize: 8
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}
