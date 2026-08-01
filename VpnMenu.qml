pragma ComponentBehavior: Bound

// Vpn menu body: status strip, tunnel facts as chips, profile list, entry to the tui.
// Split from VpnPopup's window frame so widget-probe can render it.

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    signal requestClose

    /// The live tunnel, unless a demo scene hands the view a made-up one
    property var vpn: VpnStatus

    readonly property real padding: 8
    // Profile names are short ("work", "home"), a floor keeps the strip and the chips
    // from collapsing
    readonly property real minContentWidth: 230

    implicitWidth: Math.max(root.minContentWidth, column.implicitWidth + root.padding * 2)
    implicitHeight: column.implicitHeight + root.padding * 2

    // One fact about the live tunnel
    component DetailChip: Pill {
        id: chip
        property string icon
        property string label
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: 26
        color: Appearance.colors.colLayer3

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: chip.icon
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                textFormat: Text.PlainText
            }
        }
    }

    // One row, shared by nm profiles and tailscale exit-node candidates
    component ProfileRow: RippleButton {
        id: profileRow
        required property var modelData
        readonly property bool isActive: modelData.active === true
        readonly property color colText: profileRow.isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
        readonly property bool isTailscale: modelData.kind === "tailscale"

        Layout.fillWidth: true
        implicitHeight: 36
        horizontalPadding: 10
        buttonRadius: Appearance.rounding.verysmall
        toggled: profileRow.isActive

        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3)
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active
        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        releaseAction: () => {
            if (profileRow.isActive)
                root.vpn.disconnect(profileRow.modelData.name);
            else
                root.vpn.connect(profileRow.modelData.name);
            root.requestClose();
        }

        contentItem: RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: profileRow.horizontalPadding
                rightMargin: profileRow.horizontalPadding
            }
            spacing: 10

            MaterialSymbol {
                text: profileRow.isTailscale ? "alt_route" : (profileRow.isActive ? "vpn_lock" : "vpn_key")
                fill: profileRow.isActive ? 1 : 0
                iconSize: Appearance.font.pixelSize.large
                color: profileRow.colText
            }
            StyledText {
                Layout.fillWidth: true
                text: profileRow.modelData.name
                elide: Text.ElideRight
                textFormat: Text.PlainText
                color: profileRow.colText
            }
            // Turns into disconnect on hover, clicking the active profile drops the tunnel
            MaterialSymbol {
                visible: profileRow.isActive
                text: profileRow.hovered ? "link_off" : "check"
                iconSize: Appearance.font.pixelSize.large
                color: profileRow.colText
            }
        }
    }

    component SectionLabel: StyledText {
        Layout.leftMargin: 8
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.padding
        }
        spacing: 4

        Rectangle { // Status strip
            Layout.fillWidth: true
            implicitHeight: statusRow.implicitHeight + 8 * 2
            radius: Appearance.rounding.small
            color: root.vpn.connected ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer3

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RowLayout {
                id: statusRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                    rightMargin: 12
                }
                spacing: 10

                // ShapeCanvas morphs between the two shapes, so connecting is animated
                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    shape: root.vpn.connected ? MaterialShape.Shape.Clover4Leaf : MaterialShape.Shape.Circle
                    text: root.vpn.icon
                    iconSize: Appearance.font.pixelSize.large
                    padding: 7
                    color: root.vpn.connected ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    colSymbol: root.vpn.connected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: (root.vpn.connected && root.vpn.vpnName !== "") ? root.vpn.vpnName : Translation.tr("VPN")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: root.vpn.connected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                // Connected needs no word: the strip is filled and the chips below say more
                StyledText {
                    visible: !root.vpn.connected
                    text: Translation.tr("Off")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }

        Flow { // Tunnel facts, wraps when the addresses are long
            Layout.fillWidth: true
            visible: root.vpn.connected
            spacing: 4

            DetailChip {
                visible: root.vpn.vpnIp !== ""
                icon: "lan"
                label: root.vpn.vpnIp
            }
            DetailChip {
                visible: root.vpn.mode !== ""
                icon: "alt_route"
                label: root.vpn.mode === "split" ? Translation.tr("Split, %1 routes").arg(root.vpn.routes) : root.vpn.mode === "full" ? Translation.tr("Full tunnel") : root.vpn.mode
            }
        }

        SectionLabel {
            Layout.topMargin: 2
            text: root.vpn.nmProfiles.length > 0 ? Translation.tr("Profiles") : Translation.tr("No profiles")
        }

        ColumnLayout { // Rows flush, they group by hover shape rather than by gaps
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.vpn.nmProfiles
                delegate: ProfileRow {}
            }
        }

        SectionLabel {
            visible: root.vpn.tsAvailable && root.vpn.tsProfiles.length > 0
            Layout.topMargin: 6
            text: Translation.tr("Tailscale exit node")
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.vpn.tsAvailable && root.vpn.tsProfiles.length > 0
            spacing: 0

            Repeater {
                model: root.vpn.tsProfiles
                delegate: ProfileRow {}
            }
        }

        RippleButtonWithIcon { // Open nmtui for profiles nmcli itself can't edit here
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 34
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer3
            colBackgroundHover: Appearance.colors.colLayer3Hover
            colRipple: Appearance.colors.colLayer3Active
            materialIcon: "tune"
            materialIconFill: false
            mainText: Translation.tr("Open nmtui…")
            onClicked: {
                // apps.terminal can carry its own flags ("kitty -1"), needs shell word-splitting
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e nmtui`]);
                root.requestClose();
            }
        }
    }
}
