import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Services.Pam

Rectangle {
  id: root
  signal unlocked()
  anchors.fill: parent
  color: "transparent"

  property string lockState: "idle"

  readonly property real s: height / 1080
  readonly property color fg:       "#fdfaf2"
  readonly property color gold:     "#c9a063"
  readonly property color orbitClr: "#ffffff"

  // ── Font ──────────────────────────────────────────────
  FolderListModel {
    id: fontFolder
    folder: Qt.resolvedUrl("font")
    nameFilters: ["*.ttf", "*.otf"]
  }
  FontLoader {
    id: serifFont
    source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
  }

  // ── Background ────────────────────────────────────────
  Rectangle {
    anchors.fill: parent; z: -300
    color: Qt.rgba(0, 0, 0, 0.4)
  }

  MediaPlayer {
    id: player
    source: "file:///home/diaz/.config/quickshell/bg.mp4"
    videoOutput: bgVideo
    loops: MediaPlayer.Infinite
    Component.onCompleted: play()  
  }

  VideoOutput {
    id: bgVideo
    anchors.fill: parent        // ← ganti width/height dengan ini
    fillMode: VideoOutput.PreserveAspectCrop
    z: -500
  }

  Rectangle {
    anchors.fill: parent; z: -300
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#45000000" }
      GradientStop { position: 1.0; color: "#75000000" }
    }
  }

    // ── Clock (kanan atas) ────────────────────────────────
  Item {
    id: clockWidget
    anchors.right: parent.right; anchors.rightMargin: 100 * s
    anchors.top: parent.top;    anchors.topMargin:   100 * s
    width: 450 * s; height: 250 * s

    Item {
      id: orbitalSpace
      anchors.centerIn: timeLabels
      width: 320 * s; height: 100 * s; rotation: -18; z: 10
      property real t: 0
      NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 18000; loops: Animation.Infinite; running: true }

      Shape {
        anchors.fill: parent; opacity: 0.25; antialiasing: true
        ShapePath {
            strokeWidth: 1.2; strokeColor: root.orbitClr; fillColor: "transparent"
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathAngleArc { centerX: 160 * s; centerY: 50 * s; radiusX: 160 * s; radiusY: 50 * s; startAngle: 0; sweepAngle: 360 }
        }
      }
      Rectangle {
        id: traveler; width: 8 * s; height: 8 * s; radius: 4 * s
        color: root.orbitClr; opacity: 0.6; antialiasing: true
        x: (160 * s) + (160 * s * Math.cos(orbitalSpace.t)) - (width / 2)
        y: (50 * s) + (50 * s * Math.sin(orbitalSpace.t)) - (height / 2)
      }
    }

    Row {
      id: timeLabels
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      spacing: 15 * s; z: 50
      Text { id: hhLab; text: Qt.formatTime(new Date(), "HH"); font.family: serifFont.name; font.pixelSize: 100 * s; font.letterSpacing: 4 * s; color: root.fg; layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 12 } }
      Text { id: mmLab; text: Qt.formatTime(new Date(), "mm"); font.family: serifFont.name; font.pixelSize: 100 * s; font.letterSpacing: 4 * s; color: root.fg; layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 12 } }
    }

    Column {
      anchors.right: parent.right; anchors.top: timeLabels.bottom; spacing: 5 * s; z: 100
      Text { text: Qt.formatDate(new Date(), "dddd").toUpperCase(); font.family: serifFont.name; font.pixelSize: 16 * s; font.letterSpacing: 8 * s; color: root.gold; opacity: 0.8; anchors.right: parent.right }
      Row {
          anchors.right: parent.right; spacing: 12 * s
          Rectangle { width: 40 * s; height: 1; color: root.gold; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
          Text { text: Qt.formatDate(new Date(), "MMM dd yyyy").toUpperCase(); font.family: serifFont.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; color: root.fg; opacity: 0.6 }
      }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: { hhLab.text = Qt.formatTime(new Date(), "HH"); mmLab.text = Qt.formatTime(new Date(), "mm") } }
  }

    // ── Idle: klik/ketik untuk ke login ──────────────────
  MouseArea {
      anchors.fill: parent
      enabled: root.lockState === "idle"
      onClicked: switchToLogin()
  }
  Keys.onPressed: event => {
      if (root.lockState === "idle") { switchToLogin(); event.accepted = true }
  }
  focus: true

  // ── Identity + Password (kanan bawah) ─────────────────
  Column {
    id: identityStack
    anchors.right: parent.right; anchors.rightMargin: 100 * s
    anchors.bottom: parent.bottom
    spacing: 12 * s; width: 450 * s
    opacity: root.lockState === "login" ? 1 : 0
    anchors.bottomMargin: root.lockState === "login" ? 100 * s : 60 * s

    Behavior on opacity      { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
    Behavior on anchors.bottomMargin { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

      SequentialAnimation {
        id: typingAnim
        NumberAnimation { target: identityStack; property: "scale"; from: 1.0; to: 1.01; duration: 40; easing.type: Easing.OutCubic }
        NumberAnimation { target: identityStack; property: "scale"; from: 1.01; to: 1.0; duration: 100 }
      }

      // Username
      Text {
        id: uLabel
        text: Quickshell.env("USER").toUpperCase()
        font.family: serifFont.name; font.pixelSize: 48 * s; font.letterSpacing: 4 * s
        color: root.fg; anchors.right: parent.right
        layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 12 }
      }

      Row {
        anchors.right: parent.right; spacing: 12 * s
        Rectangle { width: 60 * s; height: 1; color: root.gold; opacity: 0.2; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "✦"; font.pixelSize: 10 * s; color: root.gold; opacity: 0.4; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 60 * s; height: 1; color: root.gold; opacity: 0.2; anchors.verticalCenter: parent.verticalCenter }
      }

      // Password input
      Item {
        id: inputWrapper; width: parent.width; height: 48 * s

        TextInput {
          id: passInput
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignRight
          echoMode: TextInput.Password; passwordCharacter: "✦"
          inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
          font.family: serifFont.name; font.pixelSize: 22 * s; font.letterSpacing: 10 * s
          color: root.fg
          property bool wasClicked: false
          cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
          selectionColor: root.gold
          rightPadding: text.length > 0 ? 50 * s : 0
          Behavior on rightPadding { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
          onTextEdited: errText.text = ""
          onTextChanged: typingAnim.restart()
          onAccepted: doUnlock()

          Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) { event.accepted = true; switchToIdle() }
          }

          Text {
              anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
              text: "W A I T I N G   F O R   P A S S W O R D"
              font.family: serifFont.name; font.pixelSize: 12 * s; font.letterSpacing: 3 * s; color: root.gold
              opacity: passInput.text.length === 0 ? 0.4 : 0
              Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
              layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 3 }
          }

          Rectangle {
            id: customCursor; width: 2 * s; height: 24 * s; color: root.gold
            anchors.verticalCenter: parent.verticalCenter
            x: passInput.cursorRectangle.x
            visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)
            SequentialAnimation {
                loops: Animation.Infinite; running: customCursor.visible
                NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
            }
          }
            MouseArea { anchors.fill: parent; onClicked: { passInput.forceActiveFocus(); passInput.wasClicked = true } }
        }

        Item {
          id: loginBtn
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          width: 32 * s; height: 32 * s
          opacity: passInput.text.length > 0 ? 0.8 : 0
          scale:   passInput.text.length > 0 ? 1.0 : 0.8
          Behavior on opacity { NumberAnimation { duration: 350 } }
          Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
          Text { text: "✦"; font.pixelSize: 14 * s; color: arrowMa.containsMouse ? root.gold : root.fg; anchors.centerIn: parent; layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4 } }
          Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.gold; border.width: 1; opacity: 0.2; rotation: 45 }
          MouseArea { id: arrowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doUnlock() }
        }
      }

      Text {
        id: errText; width: parent.width; horizontalAlignment: Text.AlignRight
        height: 15 * s; verticalAlignment: Text.AlignTop
        text: ""; color: "#ff4444"
        font.family: serifFont.name; font.pixelSize: 12 * s; font.letterSpacing: 2 * s
      }
  }

    // ── Unlock animation ──────────────────────────────────
    SequentialAnimation {
      id: unlockAnimation
      ScriptAction { script: root.lockState = "unlocking" }
      NumberAnimation { target: identityStack; property: "opacity"; to: 0; duration: 350; easing.type: Easing.InOutQuad }
      PauseAnimation { duration: 150 }
      ScriptAction { script: root.unlocked() }
    }

    // ── PAM ───────────────────────────────────────────────
    PamContext {
      id: pam
      configDirectory: Qt.resolvedUrl("pam").toString().replace("file://", "")
      config: "password.conf"

      onPamMessage: {
        if (this.responseRequired) this.respond(passInput.text)
      }

      onCompleted: result => {
        if (root.lockState !== "login") return
        if (result === PamResult.Success) {
          unlockAnimation.start()
        } else {
          errText.text = "ACCESS DENIED"
          passInput.text = ""
          passInput.forceActiveFocus()
        }
      }
    }

    // ── Helpers ───────────────────────────────────────────
    function doUnlock() {
      if (passInput.text === "") return
      errText.text = ""
      pam.start()
    }

    function switchToLogin() {
      root.lockState = "login"
      passInput.forceActiveFocus()
    }

    function switchToIdle() {
      root.lockState = "idle"
      passInput.text = ""
      errText.text = ""
      pam.abort()
    }

    Timer { interval: 300; running: true; onTriggered: { if (root.lockState === "login") passInput.forceActiveFocus() } }
}
