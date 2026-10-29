import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(modelData)

    screen: modelData
    visible: monitor !== null && monitor.isSoftwareDimming
    color: "transparent"
    mask: Region {}

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, (1 - (root.monitor?.brightness ?? 1)) * 0.85)
    }
}