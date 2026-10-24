import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../services"
import ".."

PanelWindow {
  id: root
  anchors {
    left: true
    top: true
    right: true
    bottom: true
  }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  signal requestClose()

  property var categoryApps: ({})
  property var categories: []
  property int currentCategoryIndex: 0
  property bool isShowing: false
  property bool isLoading: false
  signal requestPowerMenu()

  Timer {
    id: showTimer
    interval: 16
    onTriggered: root.isShowing = true
  }

  onVisibleChanged: {
    if (visible) {
      isShowing = false
      showTimer.start()
    }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() {
      reloadTimer.restart()
    }
  }

  Component.onCompleted: {
    if (DesktopEntries.applications.values.length > 0) {
      loadApplications()
    } else {
      console.log("Waiting for desktop entries to load...")
      delayTimer.start()
    }
  }

  Timer {
    id: reloadTimer
    interval: 200
    repeat: false
    onTriggered: loadApplications()
  }

  Timer {
    id: delayTimer
    interval: 100
    repeat: true
    triggeredOnStart: false

    onTriggered: {
      console.log("Checking desktop entries... Count:", DesktopEntries.applications.values.length)
      if (DesktopEntries.applications.values.length > 0) {
        loadApplications()
        delayTimer.stop()
      }
    }
  }

  function loadApplications() {
    if (root.isLoading) return
    root.isLoading = true

    var appsByCategory = {}
    var seenIds = {}  // ← filter duplikat by id

    for (var i = 0; i < DesktopEntries.applications.values.length; i++) {
        var app = DesktopEntries.applications.values[i]

        if (!app || !app.name) continue

        // Skip kalau id sudah pernah diproses
        var appId = app.id || app.name
        if (seenIds[appId]) continue
        seenIds[appId] = true

        var mainCategories = ["AudioVideo", "Audio", "Video", "Development", "Education",
            "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]

        var category = "Other"
        if (app.categories && app.categories.length > 0) {
            if (app.categories.indexOf("X-WayDroid-App") !== -1) {
                category = "WayDroid"
            } else {
                for (var c = 0; c < app.categories.length; c++) {
                    if (mainCategories.indexOf(app.categories[c]) !== -1) {
                        category = app.categories[c]
                        break
                    }
                }
            }
        }

        var categoryMapping = {
            "AudioVideo": "Multimedia",
            "Audio": "Multimedia",
            "Video": "Multimedia",
            "Development": "Development",
            "Game": "Games",
            "Graphics": "Graphics",
            "Network": "Internet",
            "Office": "Office",
            "Settings": "Settings",
            "System": "System",
            "Utility": "Accessories"
        }

        if (categoryMapping[category]) {
            category = categoryMapping[category]
        }

        if (!appsByCategory[category]) {
            appsByCategory[category] = []
        }

        appsByCategory[category].push(app)
    }

    root.categoryApps = appsByCategory
    root.categories = Object.keys(appsByCategory).sort()

    if (root.currentCategoryIndex >= root.categories.length) {
        root.currentCategoryIndex = 0
    }

    categoryModel.clear()
    for (var j = 0; j < root.categories.length; j++) {
        categoryModel.append({ categoryName: root.categories[j] })
    }

    if (root.categories.length > 0) {
        updateAppList()
    }

    root.isLoading = false
  }

  ListModel {
    id: categoryModel
  }

  ListModel {
    id: appListModel
  }

  function updateAppList() {
    appListModel.clear()
    var catName = root.categories[currentCategoryIndex]
    var apps = root.categoryApps[catName] || []

    for (var i = 0; i < apps.length; i++) {
      appListModel.append({
        name: apps[i].name,
        icon: apps[i].icon,
        comment: apps[i].comment,
        desktopEntry: apps[i]
      })
    }
  }

  MouseArea {
    anchors.fill: parent
    propagateComposedEvents: true
    onClicked: (mouse) => {
      if (!mainRect.contains(mapToItem(mainRect, mouse.x, mouse.y))) {
        root.requestClose()
        mouse.accepted = true
      } else {
        mouse.accepted = false
      }
    }
  }

  Rectangle {
    id: mainRect
    width: 530
    height: 500
    x: 72
    y: 168
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.1; color: Colors.topbar_gradient1  }
      GradientStop { position: 0.5; color: Colors.topbar_gradient2 }
      GradientStop { position: 0.99; color: Colors.topbar_gradient3 }
    }

    radius: 12
    border.color: Colors.outline_variant
    border.width: 2

    Rectangle {
      anchors.fill: parent
      anchors.margins: 4
      radius: 9
      color: "transparent"
      border.color: "#a3895c"
      border.width: 1
    }

    opacity: root.isShowing ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    transform: Translate {
      y: root.isShowing ? 0 : -420
      Behavior on y {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Item {
          Layout.fillHeight: true
          Layout.preferredWidth: 192

          Rectangle {
            anchors.fill: parent
            color: "transparent"

            ColumnLayout {
              anchors.fill: parent
              anchors.rightMargin: 10
              anchors.topMargin: 10 
              anchors.bottomMargin: 10 
              anchors.leftMargin: 12
              spacing: 8

              Text {
                text: "Categories"
                color: Colors.text
                font.bold: true
                font.pixelSize: 14
                font.family: "Playfair Display"
              }

              Row {
                Layout.fillWidth: true
                spacing: 3
                Repeater {
                  model: 60
                  Rectangle { width: 2; height: 1; color: "#a3895c"; opacity: 0.6 }
                }
              }

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                  anchors.fill: parent
                  model: categoryModel
                  spacing: 4
                  currentIndex: root.currentCategoryIndex

                  ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 3
                    contentItem: Rectangle {
                      implicitWidth: 2
                      implicitHeight: 2
                      radius: 2
                      color: Colors.scrollbar_thumb
                      opacity: parent.pressed ? 1.0 : parent.hovered ? 0.8 : 0.5
                    }
                    background: Rectangle {
                      implicitWidth: 2
                      radius: 2
                      color: Colors.scrollbar_track
                      opacity: 0.5
                    }
                  }

                  delegate: MouseArea {
                    width: ListView.view.width
                    height: 35
                    hoverEnabled: true

                    Rectangle {
                      anchors.fill: parent
                      anchors.rightMargin: 5
                      color: {
                        if (root.currentCategoryIndex === index)
                          return Qt.alpha("#8a5636", 0.5)
                        if (parent.containsMouse)
                          return Qt.alpha("#8a5636", 0.3)
                        return "transparent"
                      }
                      radius: 6

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8

                        Text {
                          text: "✦"
                          visible: root.currentCategoryIndex === index
                          color: "#d9b26a"
                          font.pixelSize: 10
                        }

                        Text {
                          text: model.categoryName
                          color: root.currentCategoryIndex === index ? Colors.text : Colors.text_variant1 
                          font.pixelSize: 12
                          font.family: "Playfair Display"
                          Layout.fillWidth: true
                        }
                      }
                    }

                    onClicked: {
                      root.currentCategoryIndex = index
                      root.updateAppList()
                    }
                  }
                }
              }
            }
          }
        }

        Item {
          Layout.preferredWidth: 2
          Layout.fillHeight: true
          clip: true

          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            spacing: 4
            Repeater {
              model: 90
              Rectangle {
                width: 1
                height: 4
                color: "#a3895c"
                opacity: 0.6
              }
            }
          }
        }

        Item {
          Layout.fillHeight: true
          Layout.fillWidth: true

          Rectangle {
            anchors.fill: parent
            anchors.rightMargin: 12
            color: "transparent"

            ColumnLayout {
              anchors.fill: parent
              anchors.rightMargin: 0
              anchors.topMargin: 10 
              anchors.bottomMargin: 10 
              anchors.leftMargin: 12
              spacing: 8

              RowLayout {
                Layout.fillWidth: true

                Text {
                  text: root.categories[root.currentCategoryIndex] || "Applications"
                  color: Colors.text
                  font.bold: true
                  font.pixelSize: 14
                  font.family: "Playfair Display"
                  Layout.fillWidth: true
                }

                Text {
                  text: appListModel.count + " apps"
                  color: Colors.text
                  font.pixelSize: 11
                  font.family: "Playfair Display"
                }
              }

              Row {
                Layout.fillWidth: true
                spacing: 3
                Repeater {
                  model: 60
                  Rectangle { width: 2; height: 1; color: "#a3895c"; opacity: 0.6 }
                }
              }

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                  anchors.fill: parent
                  model: appListModel
                  spacing: 4

                  ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 3
                    contentItem: Rectangle {
                      implicitWidth: 4
                      implicitHeight: 4
                      radius: 2
                      color: Colors.scrollbar_thumb
                      opacity: parent.pressed ? 1.0 : parent.hovered ? 0.8 : 0.5
                    }
                    background: Rectangle {
                      implicitWidth: 4
                      radius: 2
                      color: Colors.scrollbar_track
                      opacity: 0.5
                    }
                  }

                  delegate: MouseArea {
                    width: ListView.view.width
                    height: 45
                    hoverEnabled: true

                    acceptedButtons: Qt.LeftButton

                    onClicked: (mouse) => {
                      model.desktopEntry.execute()
                      root.requestClose()
                    }

                    Rectangle {
                      anchors.fill: parent
                      anchors.rightMargin: 5
                      color: parent.containsMouse ? "#332c2014" : "transparent"
                      border.color: parent.containsMouse ? "#a3895c" : "transparent"
                      border.width: 1
                      radius: 6

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                          Layout.preferredWidth: 32
                          Layout.preferredHeight: 32
                          color: "#1c1712"
                          radius: 4
                          border.color: "#a3895c"
                          border.width: 1

                          Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: {
                              if (!model.icon) return "image://icon/application-x-executable"
                              if (model.icon.startsWith("/")) return Qt.resolvedUrl(model.icon)
                              var path = Quickshell.iconPath(model.icon, true)
                              if (!path) return Qt.resolvedUrl(Quickshell.shellDir + "/assets/error.png")
                              return path
                            }
                            sourceSize: Qt.size(24, 24)
                            fillMode: Image.PreserveAspectFit

                            onStatusChanged: {
                              if (status === Image.Error)
                                source = "image://icon/application-x-executable"
                            }
                          }
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 2

                          Text {
                            text: model.name
                            color: Colors.text
                            font.pixelSize: 13
                            font.family: "Josefin Sans" 
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                          }

                          Text {
                            text: model.comment || "No description"
                            color: Colors.text
                            font.pixelSize: 10
                            font.family: "Josefin Sans"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
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
      }
    }
  } 
}
