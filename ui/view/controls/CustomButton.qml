import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.0
import QtQuick.Controls.impl 2.4
import QtQuick.Controls.Styles 1.2
import QtGraphicalEffects 1.0
import "."

Button {
    id: control
    
    palette.button: Style.background_button
    palette.buttonText: Style.content_main
    property alias textOpacity: rect.opacity
    property alias shadowSamples: drop_shadow.samples
    property alias shadowRadius: drop_shadow.radius
    property bool allLowercase: !text.startsWith("I ")
    property bool showHandCursor: false

    property var disabledAlpha: 0.25
    property var disalbedTextAlpha: 0.25

    property color iconColor: "transparent"

    property bool isCompleted: false

    font { 
        family: "SF Pro Display"
        pixelSize: 14
        styleName: control.checkable ? "Regular" : "Bold"
        weight: control.checkable ? Font.Normal : Font.Bold
        capitalization: allLowercase && !control.checkable ? Font.AllLowercase : Font.MixedCase
    }

//    width: 122
    height: 38
    Layout.preferredHeight: 38
    leftPadding: 30
    rightPadding: 30
    
    activeFocusOnTab: true

    spacing: 15
    icon.width: 16
    icon.height: 16

    function getTextColor () {
        var color = (control.checkable ?  (control.checked ? Style.content_opposite : Style.content_secondary) : control.palette.buttonText)
        if (color == Style.content_opposite)
            return color;
        return control.enabled ? color : Qt.rgba(color.r, color.g, color.b, control.disalbedTextAlpha)
    }
    
    function updateIconColor() {
        if (control.isCompleted) {
            if (control.iconColor == Style.content_opposite)
                return control.iconColor;
            icon.color = enabled ? control.iconColor : Qt.rgba(control.iconColor.r, control.iconColor.g, control.iconColor.b, disabledAlpha);
        }
    }

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font: control.font
        
        color: getTextColor()
        MouseArea {
            anchors.fill:  parent
            hoverEnabled: true
            enabled:      false
            cursorShape: control.showHandCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
            propagateComposedEvents: true
        }
    }
    
    Keys.onPressed: {
        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) control.clicked();
    }

    background: Rectangle {
        id: rect
        radius: control.checkable ? 10 : 50
        color: (control.checkable ?
            (control.checked ? Style.active : "transparent") :
                control.palette.button)
        opacity: control.enabled ? 1.0 : control.disabledAlpha
        
        width: control.width
        height: control.height
    }

    DropShadow {
        id: drop_shadow
        anchors.fill: rect
        radius: 7
        samples: 9
        color: Style.content_main
        source: rect
        visible: control.visualFocus || control.hovered || control.checked
    }

    onEnabledChanged: {
       updateIconColor();
    }

    Component.onCompleted: {
        if (control.iconColor != "#00000000") {    // ARGB fully transparent
            icon.color = control.iconColor;
        }
        else {
            // copy color from icon object to correct handling 'onEnabledChanged' signal:
            // shadow the icon if the button is disabled
            control.iconColor = icon.color;
        }

        control.isCompleted = true;
        updateIconColor();
    }
}
