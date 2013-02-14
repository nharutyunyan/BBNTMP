import bb.cascades 1.0
import nutty.slider 1.0

// TODO Clean up if needed

Container {
    property int currentTime
    property int totalTime
    property int time
    property int clickedByUser:0
    
    preferredWidth: my.width
    horizontalAlignment: HorizontalAlignment.Fill
    
    layout: AbsoluteLayout {}
    background: Color.create("#0088cc")

    TimeArea {
        id: currentTimeLabel
        timeInMsc: currentTime
        preferredWidth: my.timeAreaWidth
        preferredHeight: my.height
    }

    TimeArea {
        id: timeArea
        timeInMsc: totalTime
        preferredWidth: my.timeAreaWidth
        preferredHeight: my.height
        layoutProperties: AbsoluteLayoutProperties {
            positionX: my.width - my.timeAreaWidth
        }
    }

    CustomSlider {
        id: slider
        fromValue: 0
        toValue: totalTime
        value: time
        preferredWidth: my.width - 2 * my.timeAreaWidth

        layoutProperties: AbsoluteLayoutProperties {
            positionX: my.timeAreaWidth
        }

        onHandleLongPressed: {
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
        }
        
        onMove: {
            smallStepSlider.value = smallStepSlider.fromPosXToValue(windowX - smallStepSlider.layoutProperties.positionX - my.longPressInitX);
        }

        onHandleReleased: {
            smallStepSlider.visible = false;
        }
        
        onImmediateValueChanged: {
            currentTimeLabel.timeInMsc = immediateValue;
        }

        onValueChanged: {
            time = value;
            }
            
        onDraggingChanged: {
            if(dragging) {
                clickedByUser = immediateValue;
            }
        }
    }

    CustomSlider {
        id: smallStepSlider
        preferredWidth: my.smallStepSliderWidth
        visible: false
        layoutProperties: AbsoluteLayoutProperties {
        }
        onValueChanged: {
            time = value;
            clickedByUser = value;
        }
        onPreferredWidthChanged: {
        }
    }

    attachedObjects: [
        // Dummy component for local variables
        ComponentDefinition {
            id: my
            property int width: 700
            property int height: 100
            property int timeAreaWidth: 200
            property int smallStepSliderWidth: 300
            property int dt: 10 * 1000 // delta time in seconds
            property real longPressInitX
        },
        LayoutUpdateHandler {
            id: layoutHandler
            onLayoutFrameChanged: {
                my.width = layoutFrame.width;
            }
        }
    ]

    function setCurrentTime(curTime) {
        slider.value = curTime
        currentTimeLabel.timeInMsc = curTime
    }
    
}