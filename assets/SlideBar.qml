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
    property bool pauseHandle

    preferredWidth: my.width
    preferredHeight: 2 * height
    
    layout: DockLayout {
        
    }
    background: backgroundImage.imagePaint

    TimeArea {
        id: currentTimeLabel
        timeInMsc: slideBar.value
        preferredWidth: my.timeAreaWidth
        preferredHeight: height
        horizontalAlignment: HorizontalAlignment.Left
    }

    TimeArea {
        id: timeArea
        timeInMsc: slideBar.toValue
        preferredWidth: my.timeAreaWidth
        preferredHeight: height  
        horizontalAlignment: HorizontalAlignment.Right
    }

    CustomSlider {
        id: slider
        verticalAlignment: VerticalAlignment.Bottom
        fromValue: slideBar.fromValue
        toValue: slideBar.toValue
        preferredWidth: my.width - 2 * my.timeAreaWidth

        property int positionX
        onHandleLongPressed: {
            onSlider = true;
            if(slider.toValue > my.minTime) {
                smallStepSlider.visible = true;
                if(slider.value - my.dt < slider.fromValue) {
                    smallStepSlider.fromValue = slider.fromValue;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + smallStepSlider.handleSize.width;
                    smallStepSlider.value = slider.value;
                }
                else if(slider.value + my.dt > slider.toValue) {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.toValue;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + smallStepSlider.handleSize.width;
                    smallStepSlider.value = slider.value;
                }
                else {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.preferredWidth = my.smallStepSliderWidth + smallStepSlider.handleSize.width;
                    smallStepSlider.value = slider.value;
                }
                smallStepSlider.layoutProperties.positionX = slider.handleLocalX() - smallStepSlider.handleLocalX() + slider.positionX;
                my.longPressInitX = positionX;
                my.handlLongPressed = true;
                seekInterval.start();
            }
            else
                slider.setLongPressEnabled(false);
        }

        onMediaStateChanged: {

            slideBar.pauseHandle = mediaState
        }

        onMove: {
            if(slider.toValue > my.minTime)
                smallStepSlider.value = smallStepSlider.fromPosXToValue(windowX - smallStepSlider.layoutProperties.positionX - my.longPressInitX);
                slider.value = slideBar.value = smallStepSlider.value;
        }

        onHandleReleased: {
            seekInterval.stop();
            onSlider = false;
            my.handlLongPressed = false;
            smallStepSlider.visible = false;
        }

        onImmediateValueChanged: {
            slideBar.immediateValue = immediateValue;
        }
    }

    Container {
        preferredWidth: my.width
        implicitLayoutAnimationsEnabled: false
        verticalAlignment: VerticalAlignment.Bottom
        layout: AbsoluteLayout {
        }
        CustomSlider {
        	id: smallStepSlider
        	preferredWidth: my.smallStepSliderWidth
        	 visible: false        
        	 layoutProperties: AbsoluteLayoutProperties {
        	 }
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
            property int minTime: 2 * 60 * 1000 // min time to show small steps slider
            property bool handlLongPressed: false
        },
        
        QTimer {
            id: seekInterval
            interval: 200
            onTimeout: {
                slideBar.immediateValue = smallStepSlider.value
            }
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
        },
        OrientationHandler {
            onOrientationAboutToChange: {
                if (orientation == UIOrientation.Portrait) {
                    timeArea.verticalAlignment = VerticalAlignment.Top
                    currentTimeLabel.verticalAlignment = VerticalAlignment.Top
                    slider.horizontalAlignment = HorizontalAlignment.Fill
                    slider.positionX = 0
                    slideBar.preferredHeight = 2 * height
                } else {
                    timeArea.verticalAlignment = VerticalAlignment.Bottom
                    currentTimeLabel.verticalAlignment = VerticalAlignment.Bottom
                    slider.horizontalAlignment = HorizontalAlignment.Center
                    slider.positionX = my.timeAreaWidth
                    slideBar.preferredHeight = height
                }
            }
        }
    ]

    function setValue(value) {
        slideBar.value = value;
        slider.value = value;
    }

    function resetValue() {
        slideBar.value = slideBar.fromValue;
    }

    function enabled(en) {
    }
    onCreationCompleted: {
        if (OrientationSupport.orientation == UIOrientation.Portrait) {
            timeArea.verticalAlignment = VerticalAlignment.Top
            currentTimeLabel.verticalAlignment = VerticalAlignment.Top
            slider.horizontalAlignment = HorizontalAlignment.Fill
            slider.positionX = 0

        } else {
            timeArea.verticalAlignment = VerticalAlignment.Bottom
            currentTimeLabel.verticalAlignment = VerticalAlignment.Bottom
            slider.horizontalAlignment = HorizontalAlignment.Center
            slideBar.preferredHeight = height
            slider.positionX = my.timeAreaWidth

        }
    }

}