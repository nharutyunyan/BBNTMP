import bb.cascades 1.0
import nutty.slider 1.0

// TODO Clean up if needed

Container {
    id: slideBar
    property real immediateValue
    property real value
    property real fromValue: 0
    property real toValue: 1
    property bool onSlider : false
    property int height: 100

    preferredWidth: my.width
    horizontalAlignment: HorizontalAlignment.Fill

    layout: AbsoluteLayout {}
    background: backgroundImage.imagePaint

    TimeArea {
        id: currentTimeLabel
        timeInMsc: slideBar.immediateValue
        preferredWidth: my.timeAreaWidth
        preferredHeight: height
    }

    TimeArea {
        id: timeArea
        timeInMsc: slideBar.toValue
        preferredWidth: my.timeAreaWidth
        preferredHeight: height
        layoutProperties: AbsoluteLayoutProperties {
            positionX: my.width - my.timeAreaWidth
        }
    }

    CustomSlider {
        id: slider
        fromValue: slideBar.fromValue
        toValue: slideBar.toValue
        value: if(dragging) {
            if(my.handlLongPressed)
                return smallStepSlider.value;
            else
                return;
        } else {
            return slideBar.value;
        }

        preferredWidth: my.width - 2 * my.timeAreaWidth

        layoutProperties: AbsoluteLayoutProperties {
            positionX: my.timeAreaWidth
        }

        onHandleLongPressed: {
            onSlider = true;
            if(slider.toValue > my.minTime) {
                smallStepSlider.visible = true;
                smallStepSlider.value = slider.value;
                if(slider.value - my.dt < slider.fromValue) {
                    smallStepSlider.fromValue = slider.fromValue;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + smallStepSlider.handleSize.width;
                }
                else if(slider.value + my.dt > slider.toValue) {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.toValue;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + smallStepSlider.handleSize.width;
                }
                else {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth + smallStepSlider.handleSize.width;
                }
                smallStepSlider.layoutProperties.positionX = slider.handleLocalX() - smallStepSlider.handleLocalX() + slider.layoutProperties.positionX;
                my.longPressInitX = positionX;
                my.handlLongPressed = true;
            }
            else
                slider.setLongPressEnabled(false);
        }

        onMove: {
            if(slider.toValue > my.minTime)
                smallStepSlider.value = smallStepSlider.fromPosXToValue(windowX - smallStepSlider.layoutProperties.positionX - my.longPressInitX);
        }

        onHandleReleased: {
            onSlider = false;
            my.handlLongPressed = false;
            smallStepSlider.visible = false;
        }

        onImmediateValueChanged: {
            slideBar.immediateValue = immediateValue;
        }

        onValueChanged: {
            slideBar.value = value;
        }

        onDraggingChanged: {
            onSlider = dragging;
        }
    }
    
    CustomSlider {
        id: smallStepSlider
        preferredWidth: my.smallStepSliderWidth
        visible: false        
        layoutProperties: AbsoluteLayoutProperties {
        }
    }

    attachedObjects: [
        // Dummy component for local variables
        ComponentDefinition {
            id: my
            property int width: 700
            property int timeAreaWidth: 200
            property int smallStepSliderWidth: 300
            property int dt: 10 * 1000 // delta time in seconds
            property real longPressInitX
            property int minTime: 5 * 60 * 1000 // min time to show small steps slider
            property bool handlLongPressed: false
        },
        LayoutUpdateHandler {
            id: layoutHandler
            onLayoutFrameChanged: {
                my.width = layoutFrame.width;
            }
        },
        ImagePaintDefinition {
            id: backgroundImage
            imageSource: "asset:///images/Player/SliderBackground.png"
        },
        ImagePaintDefinition {
            id: zoomImage
            imageSource: "asset:///images/Player/SliderPrecisionFill.png"
        }
    ]

    function setValue(value) {
        slideBar.value = value;
    }

    function resetValue() {
        slideBar.value = slideBar.fromValue;
    }

    function enabled(en) {
    }
}