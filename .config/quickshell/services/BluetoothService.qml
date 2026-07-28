pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property bool available: Bluetooth.defaultAdapter !== null
    readonly property bool enabled: available && Bluetooth.defaultAdapter.enabled
    readonly property var allDevices: available ? Bluetooth.defaultAdapter.devices.values : []
    readonly property var connectedDevices: allDevices.filter(d => d.connected)
    readonly property bool hasConnected: connectedDevices.length > 0
    readonly property string icon: {
        if (!available || !enabled) return "󰂲"
        if (hasConnected) return "󰂱"
        return "󰂯"
    }

    // Satu-satunya address yang sedang diproses. Kosong = tidak ada operasi berjalan.
    property string connectingAddress: ""

    function toggle() {
        if (available)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    }

    // Cari device berdasarkan address (bukan nama!) lalu connect/disconnect
    function connectDevice(address) {
        if (connectingAddress !== "") return   // sudah ada operasi berjalan, tolak
        var device = _findByAddress(address)
        if (!device) return
        connectingAddress = address
        if (device.connected)
            device.disconnect()
        else
            device.connect()
    }

    // Dipanggil oleh delegate setelah state connected berubah
    function clearConnecting(address) {
        if (connectingAddress === address)
            connectingAddress = ""
    }

    function _findByAddress(address) {
        for (var i = 0; i < allDevices.length; i++) {
            if (allDevices[i].address === address)
                return allDevices[i]
        }
        return null
    }
}
