// BarButton.qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"   
import ".."

Item {
  id: root
  Layout.alignment: Qt.AlignHCenter
  implicitWidth: 72
  implicitHeight: 96

  property string iconSource: ""
  property string label: ""
  property bool active: false
  signal clicked()

  readonly property color accent: "#C9A84C"
  readonly property color fg: root.active ? accent : Colors.text_variant1

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: root.active
           ? Qt.alpha(root.accent, 0.15)
           : (hov.containsMouse ? Qt.alpha(Colors.text_variant1, 0.08) : "transparent")
    border.color: root.active ? root.accent : "transparent"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 4

      SvgIcon {
        Layout.alignment: Qt.AlignHCenter
        source: root.iconSource
        size: 48
        color: root.fg
        opacity: root.active ? 1.0 : 0.9

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        font.pixelSize: 17
        font.family: "Playfair Display"
        font.letterSpacing: 0.8
        color: root.fg
        opacity: root.active ? 1.0 : 0.9

        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }
  }

  MouseArea {
    id: hov
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
