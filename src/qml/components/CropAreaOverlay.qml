import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: base
    anchors.fill: parent
    property real radius: 0.8*(Theme.iconSizeMedium/2)
    property var image

    Canvas {
        id: frame
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.2);
            ctx.fillRect(0, 0, width, height)
            ctx.fillStyle = Qt.rgba(0, 0, 0, 0);
            ctx.globalCompositeOperation = "copy"
            ctx.strokeStyle = Theme.highlightColor
            ctx.beginPath()
            ctx.moveTo(topLeft.center.x, topLeft.center.y)
            ctx.lineTo(topRight.center.x, topRight.center.y)
            ctx.lineTo(bottomRight.center.x, bottomRight.center.y)
            ctx.lineTo(bottomLeft.center.x, bottomLeft.center.y)
            ctx.closePath()
            ctx.fill()
            ctx.stroke()
        }
    }

    CornerMarker {
        id: topLeft
        radius: parent.radius
        initialCenterX: (image.width - image.paintedWidth) / 2 + radius
        initialCenterY: (image.height - image.paintedHeight) / 2 + radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomLeft.x = x; topRight.y = y;
            frame.requestPaint();
        }
    }

    CornerMarker {
        id: topRight
        radius: parent.radius
        initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
        initialCenterY: (image.height - image.paintedHeight) / 2 + radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomRight.x = x; topLeft.y = y;
            frame.requestPaint();
        }

    }

    CornerMarker {
        id: bottomLeft
        radius: parent.radius
        initialCenterX: (image.width  - image.paintedWidth) / 2 + radius
        initialCenterY: (image.height + image.paintedHeight) / 2 - radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            topLeft.x = x; bottomRight.y = y;
            frame.requestPaint();
        }

    }

    CornerMarker {
        id: bottomRight
        radius: parent.radius
        initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
        initialCenterY: (image.height + image.paintedHeight) / 2 - radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            topRight.x = x; bottomLeft.y = y;
            frame.requestPaint();
        }
    }

    CornerMarker {
        id: topCenter
        radius: parent.radius
        beVCenter: true
        initialCenterX: image.width/2
        initialCenterY: (image.height - image.paintedHeight) / 2 + radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            topLeft.y = y; topRight.y = y;
            x = Math.min(topLeft.x, topRight.x)+Math.abs(topLeft.x-topRight.x)/2
            frame.requestPaint();
        }
    }

    CornerMarker {
        id: bottomCenter
        radius: parent.radius
        beVCenter: true
        initialCenterX: image.width/2
        initialCenterY: (image.height + image.paintedHeight) / 2 - radius
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomLeft.y = y; bottomRight.y = y;
            x = Math.min(bottomLeft.x, bottomRight.x)+Math.abs(bottomLeft.x-bottomRight.x)/2
            frame.requestPaint();
        }
    }

    CornerMarker {
        id: leftCenter
        radius: parent.radius
        beHCenter: true
        initialCenterX: (image.width  - image.paintedWidth) / 2 + radius
        initialCenterY: image.height/2
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomLeft.x = x; topLeft.x = x;
            y = Math.min(bottomLeft.y, topLeft.y)+Math.abs(bottomLeft.y-topLeft.y)/2
            frame.requestPaint();
        }
    }

    CornerMarker {
        id: rightCenter
        radius: parent.radius
        beHCenter: true
        initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
        initialCenterY: image.height/2
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomRight.x = x; topRight.x = x;
            y = Math.min(bottomRight.y, topRight.y)+Math.abs(bottomRight.y-topRight.y)/2
            frame.requestPaint();
        }
    }
}
