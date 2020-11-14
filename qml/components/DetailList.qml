import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: base
    width: parent.width
    spacing: 0

    property string label
    property var values
    property int maxEntries: -1
    property var preprocessor: function(str) { return str; }

    Repeater {
        model: maxEntries > 0 ? (maxEntries > values.length ? values.length : maxEntries) : values.length
        delegate: DetailItem {
            label: index === 0 ? base.label : ""
            value: preprocessor(values[index])
        }
    }

    Label {
        id: moreText
        visible: maxEntries > 0 && values.length > maxEntries
        text: qsTr("... and %n more", "", values.length-maxEntries)
        anchors {
            left: parent.horizontalCenter
            right: parent.right
            leftMargin: Theme.paddingSmall
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingSmall
        }
        horizontalAlignment: Text.AlignLeft
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }
}
