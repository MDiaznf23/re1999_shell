import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import ".."

PanelWindow {
  id: notifWindow
  
  required property var notificationServer
  property real totalContentHeight: contentColumn.implicitHeight + 20
  
  property bool shouldAnimate: false
  property bool isHiding: false
  property bool isHovering: false
  property bool dndActive: false 

  anchors {
    top: true
    bottom: false
    right: false
  }
  
  margins {
    top: 0
  }
  
  visible: (notificationServer.notifications.length > 0 || isHiding) && !dndActive
  
  implicitWidth: 400
  implicitHeight: Math.max(110, contentColumn.implicitHeight + 25)
  
  color: "transparent"
  
  exclusionMode: ExclusionMode.Ignore
  
  WlrLayershell.layer: WlrLayer.Top

  onVisibleChanged: {
    if (visible && notificationServer.notifications.length > 0) {
      isHiding = false
      shouldAnimate = false
      showTimer.start()
      autoDismissTimer.restart()
    } else if (!visible) {
      autoDismissTimer.stop()
      isHiding = false
      shouldAnimate = false
      isHovering = false
    }
  }
  
  Timer {
    id: showTimer
    interval: 50
    onTriggered: {
      shouldAnimate = true
    }
  }
  
  Timer {
    id: autoDismissTimer
    interval: 3000
    running: false
    onTriggered: {
      if (notificationServer.notifications.length > 0) {
        isHiding = true
        shouldAnimate = false
        clearTimer.start()
      }
    }
  }
  
  Timer {
    id: clearTimer
    interval: 350
    onTriggered: {
      notificationServer.clearAll()
      isHiding = false
    }
  }
  
  Connections {
    target: notificationServer
    function onNotificationsChanged() {
      if (notificationServer.notifications.length > 0) {
        if (isHiding) {
          clearTimer.stop()
          isHiding = false
          shouldAnimate = true
        }
        if (!isHovering) {
          autoDismissTimer.restart()
        }
      } else {
        isHiding = false
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      notifWindow.isHovering = hovered
      if (hovered) {
        autoDismissTimer.stop()
      } else {
        if (notificationServer.notifications.length > 0 && !notifWindow.isHiding) {
          autoDismissTimer.restart()
        }
      }
    }
  }
  
  Rectangle {
    id: mainRect
    x: (notifWindow.width - width) / 2
    y: shouldAnimate ? 0 : -mainRect.height
    width: 300
    height: contentColumn.implicitHeight + 25
    border.width: 2
    border.color: Colors.outline_variant

    Rectangle {
      id: topPatch
      height: 10
      width: mainRect.width
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.18; color: Colors.topbar_gradient5 }
        GradientStop { position: 0.99; color: Colors.topbar_gradient6 }
      }
      opacity: mainRect.opacity
    }

    gradient: Gradient {
      orientation: Gradient.Horizontal 
      GradientStop { position: 0.18; color: Colors.topbar_gradient5 }
      GradientStop { position: 0.99; color: Colors.topbar_gradient6 }
    }
    radius: 12
    
    opacity: shouldAnimate ? 1 : 0
    
    Behavior on y {
      enabled: notifWindow.shouldAnimate
      NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }
    
    Behavior on opacity {
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    
    Behavior on height {
      NumberAnimation { duration: 200 }
    }
    
    Column {
      id: contentColumn
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        leftMargin: 12
        rightMargin: 12
        topMargin: 12
      }

      spacing: 10
      
      Repeater {
        model: Math.min(notificationServer.notifications.length, 3)
        
        delegate: NotificationItem {
          id: delegateItem
          required property int index
          
          width: contentColumn.width 
          
          property var rawNotif: (index < notificationServer.notifications.length) ? notificationServer.notifications[index] : null
          notification: (rawNotif && rawNotif.appName !== undefined) ? rawNotif : null
          
          visible: notification !== null
          opacity: notification ? 1 : 0

          onDismissClicked: {
            notification.dismiss()
          }
        }
      }
    }

    Canvas {
      id: righttopLauncher
      width: 14; height: 14
      anchors { top: parent.top; right: parent.right }
      anchors.rightMargin: -12 
      transform: Scale { origin.x: 7; origin.y: 7 }
      z: 1
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        ctx.fillStyle = Colors.bottombar_gradient3
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.moveTo(14, 0); ctx.lineTo(14, 2)
        ctx.arc(14, 14, 12, Math.PI / 2, Math.PI, true)
        ctx.lineTo(2, 14); ctx.lineTo(0, 14); ctx.lineTo(0, 0)
        ctx.closePath(); ctx.fill()
      }
    }

    Canvas {
      id: righttopLauncher1
      width: 14; height: 14
      anchors { top: parent.top; right: parent.right }
      anchors.rightMargin: -12
      transform: Scale { origin.x: 7; origin.y: 7 }
      z: 1
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        ctx.fillStyle = Colors.outline_variant
        ctx.beginPath()
        ctx.moveTo(14, 0); ctx.lineTo(14, 2)
        ctx.arc(14, 14, 12, Math.PI / 2, Math.PI, true)
        ctx.lineTo(2, 14); ctx.lineTo(0, 14)
        ctx.arc(14, 14, 14, Math.PI, Math.PI / 2, false)
        ctx.closePath(); ctx.fill()
      }
    }

    Canvas {
      id: lefttopLauncher
      width: 14; height: 14
      anchors { top: parent.top; left: parent.left }
      anchors.leftMargin: -12
      transform: Scale { origin.x: 7; origin.y: 7; xScale: -1 }
      z: 1
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        ctx.fillStyle = Colors.bottombar_gradient3
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.moveTo(14, 0); ctx.lineTo(14, 2)
        ctx.arc(14, 14, 12, Math.PI / 2, Math.PI, true)
        ctx.lineTo(2, 14); ctx.lineTo(0, 14); ctx.lineTo(0, 0)
        ctx.closePath(); ctx.fill()
      }
    }

    Canvas {
      id: lefttopLauncher1
      width: 14; height: 14
      anchors { top: parent.top; left: parent.left }
      anchors.leftMargin: -12
      transform: Scale { origin.x: 7; origin.y: 7; xScale: -1 }
      z: 1
      onPaint: {
        var ctx = getContext("2d"); ctx.reset()
        ctx.fillStyle = Colors.outline_variant
        ctx.beginPath()
        ctx.moveTo(14, 0); ctx.lineTo(14, 2)
        ctx.arc(14, 14, 12, Math.PI / 2, Math.PI, true)
        ctx.lineTo(2, 14); ctx.lineTo(0, 14)
        ctx.arc(14, 14, 14, Math.PI, Math.PI / 2, false)
        ctx.closePath(); ctx.fill()
      }
    }
  }
}
