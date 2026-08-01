//@ probe
/**
 * The menu drawn from a made-up tunnel: the views take their status as a property, so
 * no connection is opened and nmcli is never called. `-p scenario=off` is the other
 * half - nothing up, profiles waiting, and a machine without tailscale.
 */
import ".." // The widget's own types and its VpnStatus singleton, via its qmldir
import QtQuick

Item {
    id: root

    property string scenario: "connected"

    function profile(name, active, kind) {
        return {
            "name": name,
            "active": active,
            "kind": kind ?? "nm"
        };
    }

    /// What VpnStatus would hold, minus the processes behind it
    function status(extra) {
        return Object.assign({
            "available": true,
            "connected": false,
            "icon": "public",
            "vpnName": "",
            "vpnIp": "",
            "mode": "",
            "routes": 0,
            "nmProfiles": [],
            "tsAvailable": false,
            "tsProfiles": [],
            "connect": name => {},
            "disconnect": name => {}
        }, extra ?? {});
    }

    readonly property var sets: ({
        "connected": root.status({
            "connected": true,
            "icon": "vpn_lock",
            "vpnName": "work",
            "vpnIp": "10.8.0.6",
            "mode": "split",
            "routes": 12,
            "nmProfiles": [root.profile("work", true), root.profile("home", false), root.profile("berlin-wg", false)],
            "tsAvailable": true,
            "tsProfiles": [root.profile("cloud-fi", false, "tailscale")]
        }),
        "off": root.status({
            "nmProfiles": [root.profile("work", false), root.profile("home", false)]
        })
    })

    readonly property var vpn: root.sets[root.scenario] ?? root.sets.connected

    function checks() {
        // The singleton keeps no state of its own beyond what the polls put there,
        // so its derived side reads back from a name written straight in
        VpnStatus.nmActiveName = "work";
        const up = [VpnStatus.connected, VpnStatus.vpnName, VpnStatus.icon];
        VpnStatus.nmActiveName = "";
        const down = [VpnStatus.connected, VpnStatus.icon];

        return [
            {
                "name": "an active connection is what makes the tunnel up",
                "got": up.concat(down),
                "want": [true, "work", "vpn_lock", false, "public"]
            },
            {
                "name": "short profile names still leave the menu its width",
                "got": [menu.implicitWidth >= menu.minContentWidth, tiny.implicitWidth >= tiny.minContentWidth],
                "want": [true, true]
            },
            {
                "name": "every profile gets a row, tailscale ones included",
                "got": menu.implicitHeight > noTailscale.implicitHeight && noTailscale.implicitHeight > tiny.implicitHeight,
                "want": root.scenario === "connected"
            },
            {
                "name": "the chips only show up while something is connected",
                "got": menu.implicitHeight > sameButOff.implicitHeight,
                "want": root.scenario === "connected"
            }
        ];
    }

    implicitWidth: menu.implicitWidth
    implicitHeight: menu.implicitHeight

    VpnMenu {
        id: menu
        vpn: root.vpn
    }

    // Off-screen, for the checks above: the same tunnel with no tailscale, with
    // nothing connected, and a machine where nothing is set up at all
    VpnMenu {
        id: noTailscale
        visible: false
        vpn: Object.assign({}, root.vpn, {
            "tsAvailable": false
        })
    }

    VpnMenu {
        id: sameButOff
        visible: false
        vpn: Object.assign({}, root.vpn, {
            "connected": false
        })
    }

    VpnMenu {
        id: tiny
        visible: false
        vpn: root.status()
    }
}
