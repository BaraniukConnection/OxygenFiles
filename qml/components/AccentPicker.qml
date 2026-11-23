import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import app.loaf

// AccentPicker -- the accent colour picker from Unia Breathe Desktop's Theme page: a palette of
// 12 hues 30 degrees apart in 4 lightness steps plus greys, or a hex value typed in.
ColumnLayout {
    id: root

    property color value
    signal picked(color c)

    spacing: 12

    // Columns are hues, rows go from light to dark; the last column is greys.
    readonly property var swatches: {
        var rows = [[0.9, 0.72], [0.85, 0.6], [0.8, 0.48], [0.75, 0.36]];
        var greys = ["#f2f2f2", "#b8b8b8", "#7a7a7a", "#3d3d3d"];
        var out = [];
        for (var r = 0; r < rows.length; ++r) {
            for (var i = 0; i < 12; ++i)
                out.push("#" + theme.hex(Qt.hsla(i / 12, rows[r][0], rows[r][1], 1)));
            out.push(greys[r]);
        }
        return out;
    }

    Grid {
        columns: 13
        spacing: 8

        Repeater {
            model: root.swatches

            delegate: Rectangle {
                required property string modelData
                readonly property bool selected: theme.sameColor(modelData, root.value)
                width: 26
                height: 26
                radius: 13
                color: modelData
                border.width: 1
                border.color: theme.outlineAlpha(theme.outlineVariant)
                scale: swMouse.pressed ? 0.9 : (swMouse.containsMouse ? 1.12 : 1.0)
                Behavior on scale { enabled: theme.animate; SpringAnimation { spring: 4.0; damping: 0.3 } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: theme.textMain
                    visible: parent.selected || swMouse.containsMouse
                    opacity: parent.selected ? 1.0 : 0.4
                }

                MouseArea {
                    id: swMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.modelData)
                }
            }
        }
    }

    RowLayout {
        spacing: 10

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 18
            color: root.value
            border.width: 1
            border.color: theme.outlineAlpha(theme.outlineVariant)
        }

        LoafTextField {
            id: hexField
            Layout.preferredWidth: 140
            text: "#" + theme.hex(root.value)
            placeholderText: "#10b981"
            maximumLength: 7
            validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
            readonly property bool valid: /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.test(text)
            // A full value applies at once; a short #abc applies on Enter, as #aabbcc.
            onTextEdited: if (/^#?[0-9a-f]{6}$/i.test(text)) root.picked("#" + text.replace("#", ""))
            onAccepted: if (valid) {
                var h = text.replace("#", "");
                root.picked("#" + (h.length === 3 ? h.split("").map(function(c) { return c + c; }).join("") : h));
            }
        }

        Text {
            text: qsTr("hex")
            color: theme.textMuted
            font.pixelSize: theme.fs(12)
        }
    }
}
