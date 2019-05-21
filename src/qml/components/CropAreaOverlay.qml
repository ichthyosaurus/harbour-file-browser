import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: base
    anchors.fill: parent
    property real radius: 0.8*(Theme.iconSizeMedium/2)
    property var image

    transform: [
        Rotation {
            id: rotationTr
            origin: image.imageRotation.origin
            angle: image.imageRotation.angle
        },
        Scale {
            origin: image.imageRotation.origin
            xScale: rotationTr.angle % 180 === 0 ? (image.paintedWidth*image.scale)/(image.paintedWidth-2*base.radius) :
                                                   (image.paintedHeight*image.scale)/(image.paintedHeight-2*base.radius)
            yScale: rotationTr.angle % 180 === 0 ? (image.paintedHeight*image.scale)/(image.paintedHeight-2*base.radius) :
                                                   (image.paintedWidth*image.scale)/(image.paintedWidth-2*base.radius)
        }
    ]

    function updateCenterMarkers(skip) {
        if (skip !== "horizontal") {
            topCenter.x = Math.min(topLeft.x, topRight.x)+Math.abs(topLeft.x-topRight.x)/2
            topCenter.y = topLeft.y;
            bottomCenter.x = Math.min(bottomLeft.x, bottomRight.x)+Math.abs(bottomLeft.x-bottomRight.x)/2;
            bottomCenter.y = bottomLeft.y;
        }
        if (skip !== "vertical") {
            leftCenter.y = Math.min(bottomLeft.y, topLeft.y)+Math.abs(bottomLeft.y-topLeft.y)/2;
            leftCenter.x = topLeft.x;
            rightCenter.y = Math.min(bottomRight.y, topRight.y)+Math.abs(bottomRight.y-topRight.y)/2;
            rightCenter.x = topRight.x;
        }
    }

    function reset() {
        topLeft.reset(); topCenter.reset(); topRight.reset();
        leftCenter.reset(); rightCenter.reset();
        bottomLeft.reset(); bottomCenter.reset(); bottomRight.reset();
    }

    Rectangle {
        color: "transparent"
        visible: true
        x: topLeft.initialCenterX
        y: topLeft.initialCenterY
        width: bottomRight.initialCenterX-x
        height: bottomRight.initialCenterY-y

        Rectangle {
            id: boundariesRect
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.highlightBackgroundOpacity)
            visible: false
            layer.enabled: true
            layer.smooth: true
        }

        Rectangle {
            id: cropRect
            x: Math.min((leftCenter.x+leftCenter.width/2), (rightCenter.x+rightCenter.width/2)) - parent.x
            y: Math.min(topCenter.y+topCenter.height/2, bottomCenter.y+bottomCenter.height/2) - parent.y
            width: Math.abs(leftCenter.x-rightCenter.x)
            height: Math.abs(topCenter.y-bottomCenter.y)
            color: "black"
            visible: true
        }

        layer.enabled: true
        layer.samplerName: "maskSource"
        layer.effect: ShaderEffect {
            property variant source: boundariesRect
            fragmentShader: "
                varying highp vec2 qt_TexCoord0;
                uniform highp float qt_Opacity;
                uniform lowp sampler2D source;
                uniform lowp sampler2D maskSource;
                void main(void) {
                    gl_FragColor = texture2D(source, qt_TexCoord0.st) * (1.0-texture2D(maskSource, qt_TexCoord0.st).a) * qt_Opacity;
                }
            "
        }
    }

    CropMarker {
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
            updateCenterMarkers();
        }
    }

    CropMarker {
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
            updateCenterMarkers();
        }

    }

    CropMarker {
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
            updateCenterMarkers();
        }

    }

    CropMarker {
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
            updateCenterMarkers();
        }
    }

    CropMarker {
        id: topCenter
        radius: parent.radius
        beVCenter: true
        initialCenterX: image.width/2
        initialCenterY: (image.height - image.paintedHeight) / 2 + radius
        minX: Math.min(topLeft.x, topRight.x)+Math.abs(topLeft.x-topRight.x)/2 + 2*radius
        maxX: minX
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            topLeft.y = y; topRight.y = y;
            updateCenterMarkers("horizontal");
        }
    }

    CropMarker {
        id: bottomCenter
        radius: parent.radius
        beVCenter: true
        initialCenterX: image.width/2
        initialCenterY: (image.height + image.paintedHeight) / 2 - radius
        minX: Math.min(bottomLeft.x, bottomRight.x)+Math.abs(bottomLeft.x-bottomRight.x)/2 + 2*radius
        maxX: minX
        minY: (image.height - image.paintedHeight) / 2
        maxY: (image.height + image.paintedHeight) / 2 - 2*radius
        onCenterChanged: {
            if (!dragActive) return;
            bottomLeft.y = y; bottomRight.y = y;
            updateCenterMarkers("horizontal");
        }
    }

    CropMarker {
        id: leftCenter
        radius: parent.radius
        beHCenter: true
        initialCenterX: (image.width  - image.paintedWidth) / 2 + radius
        initialCenterY: image.height/2
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: Math.min(bottomLeft.y, topLeft.y)+Math.abs(bottomLeft.y-topLeft.y)/2 + 2*radius
        maxY: minY
        onCenterChanged: {
            if (!dragActive) return;
            bottomLeft.x = x; topLeft.x = x;
            updateCenterMarkers("vertical");
        }
    }

    CropMarker {
        id: rightCenter
        radius: parent.radius
        beHCenter: true
        initialCenterX: (image.width  + image.paintedWidth) / 2 - radius
        initialCenterY: image.height/2
        minX: (image.width - image.paintedWidth) / 2
        maxX: (image.width + image.paintedWidth) / 2 - 2*radius
        minY: Math.min(bottomRight.y, topRight.y)+Math.abs(bottomRight.y-topRight.y)/2 + 2*radius
        maxY: minY
        onCenterChanged: {
            if (!dragActive) return;
            bottomRight.x = x; topRight.x = x;
            updateCenterMarkers("vertical");
        }
    }
}
