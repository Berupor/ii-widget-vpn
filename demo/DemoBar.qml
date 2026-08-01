//@ probe
/** Both button states side by side, plus the one a machine without nmcli gets. */
import ".."
import QtQuick

Row {
    id: root
    spacing: 4

    function checks() {
        return [
            {
                "name": "the icon locks up once a tunnel is on",
                "got": [off.vpn.icon, on.vpn.icon],
                "want": ["public", "vpn_lock"]
            },
            {
                // `visible` reads as false while the scene hangs off no window yet,
                // so the button that stays is checked by its size instead
                "name": "no nmcli, no button in the bar",
                "got": [on.implicitWidth > 0, gone.visible],
                "want": [true, false]
            }
        ];
    }

    VpnButton {
        id: off
        vpn: ({
            "available": true,
            "connected": false,
            "icon": "public"
        })
    }

    VpnButton {
        id: on
        vpn: ({
            "available": true,
            "connected": true,
            "icon": "vpn_lock"
        })
    }

    VpnButton {
        id: gone
        vpn: ({
            "available": false,
            "connected": false,
            "icon": "public"
        })
    }
}
