// BarButton.qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: root.active ? Qt.rgba(201/255, 168/255, 76/255, 0.15) : (hov.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
    border.color: root.active ? "#C9A84C" : "transparent"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 4

      Item {
        Layout.alignment: Qt.AlignHCenter
        width: 48
        height: 48

        Image {
          id: svgIcon
          anchors.fill: parent
          source: root.iconSource
          fillMode: Image.PreserveAspectFit
          sourceSize.width: 48   // force SVG render di ukuran ini
          sourceSize.height: 48
          visible: false
          smooth: true
        }

        ColorOverlay {
          anchors.fill: svgIcon
          source: svgIcon
          color: root.active ? "#C9A84C" : "#F0EDE6"
          opacity: root.active ? 1.0 : 0.9

          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on opacity { NumberAnimation { duration: 120 } }
        }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        font.pixelSize: 17
        font.family: "Playfair Display"
        font.letterSpacing: 0.8
        color: root.active ? "#C9A84C" : "#F0EDE6"
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
