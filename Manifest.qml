import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "vpn"
    name: Translation.tr("VPN")
    description: Translation.tr("Toggle and inspect VPN connections")
    icon: "vpn_lock"
    version: "1.0"
    author: "Berupor"
    minShellVersion: "1.0"
    dependencies: ["nmcli"] // Tailscale is optional, without it there are just no exit nodes
    slots: ({ "barUtilButton": "VpnButton.qml" })
    options: [
        { key: "ovpnDir", default: "" } // No label: text input, rendered by settingsPage
    ]
    settingsPage: "VpnSettings.qml"
}
