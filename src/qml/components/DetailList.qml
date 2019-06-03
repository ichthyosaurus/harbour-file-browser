import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: base
    width: parent.width
    spacing: 0

    property string label
    property var values

    Repeater {
        model: values.length
        delegate: DetailItem {
            label: index === 0 ? base.label : ""
            value: values[index]
        }
    }
}
