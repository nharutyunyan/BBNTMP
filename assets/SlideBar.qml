import bb.cascades 1.0
import nutty.slider 1.0
import "helpers.js" as Helpers

// TODO Clean up if needed

Container {
    id: slideBar
    property real immediateValue
    property real value
    property real fromValue: 0
    property real toValue: 1
    property bool onSlider : false
    property int height: 105
    property bool pauseHandle
    property variant layoutSize
    property int bookmarkPositionX
    property bool bookmarkTouched: false 
    property bool bookmarkVisible: true
    property int timeAreaWidth: 200 
    property int timeAreaHeight: 70
    property int sliderHandleWidth: 87
    property real factor: 105
    property real slideBarHeight
    preferredHeight: slideBarHeight

    layout: DockLayout {
        
    }
    background: backgroundImage.imagePaint

    Container {
        id: bookmark
        verticalAlignment: VerticalAlignment.Top
        layout: AbsoluteLayout {
        }

        ImageView {
            id: bookmarkIcon
            visible: bookmarkVisible
            imageSource: "asset:///images/Player/BookmarkIcon.png"
            implicitLayoutAnimationsEnabled: false
            layoutProperties: AbsoluteLayoutProperties {
                positionX: bookmarkPositionX

            }
            onTouch: {
                if (! bookmarkTouched) 
                  bookmarkTouched = true
            }

        } //bookmark Icon
    } //bookmark

    Container {
        id: sliderContainer
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Center
        property int positionOfX
        CustomSlider {
        id: slider
        objectName: "slider"
        horizontalAlignment: HorizontalAlignment.Fill
        fromValue: slideBar.fromValue
        toValue: slideBar.toValue

        onHandleLongPressed: {
            onSlider = true;
            if(slider.toValue > my.minTime) {

 				smallStepSlider.smallCurrentValue = slider.value; 
                smallStepSlider.visible = true;
                if(slider.value - my.dt < slider.fromValue) {
                    smallStepSlider.fromValue = slider.fromValue;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.value = slider.value;
                    smallStepSlider.layoutSize = Qt.size((my.smallStepSliderWidth - slideBar.factor)* (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + slideBar.factor, slideBar.height)
                }
                else if(slider.value + my.dt > slider.toValue) {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.toValue;
                    smallStepSlider.value = slider.value;
                    smallStepSlider.layoutSize = Qt.size((my.smallStepSliderWidth - slideBar.factor)* (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + slideBar.factor, slideBar.height)
                }
                else {
                    smallStepSlider.fromValue = slider.value - my.dt;
                    smallStepSlider.toValue = slider.value + my.dt;
                    smallStepSlider.value = slider.value;
                    smallStepSlider.layoutSize = Qt.size(my.smallStepSliderWidth , slideBar.height)
                }

                smallStepSlider.layoutProperties.positionX = slider.handleLocalX() - smallStepSlider.handleLocalX() + sliderContainer.positionOfX;
                my.longPressInitX = positionX;
                my.handlLongPressed = true;
                
                if (OrientationSupport.orientation == UIOrientation.Portrait) 
                {
                    smallStepSlider.smallCordX = smallStepSlider.layoutProperties.positionX;
                    if(smallStepSlider.layoutProperties.positionX < -20)
                    {
                        smallStepSlider.layoutProperties.positionX = -20;
                    }
                }
                smallStepSlider.animation = true;
                seekInterval.start();
            }
            else
                slider.setLongPressEnabled(false);
        }

        onMediaStateChanged: {

            slideBar.pauseHandle = mediaState
        }

        onMove: {
            if(slider.toValue > my.minTime )
                smallStepSlider.value = smallStepSlider.fromSmallSliderPosXToValue(windowX - smallStepSlider.layoutProperties.positionX - my.longPressInitX);
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
            slideBar.value = value;
        }
    }
}

    TimeArea {
        id: timeArea
        timeInMsc: slideBar.toValue
        preferredWidth: timeAreaWidth
        preferredHeight: height
        horizontalAlignment: HorizontalAlignment.Right
    }

    TimeArea {
        id: currentTimeLabel
        timeInMsc: slideBar.value
        preferredWidth: timeAreaWidth
        preferredHeight: height
        horizontalAlignment: HorizontalAlignment.Left
    }

    Container {
        id : smallSliderContainer
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Fill
        implicitLayoutAnimationsEnabled: false
            layout: AbsoluteLayout {
        }
        CustomSlider {
            id: smallStepSlider
            objectName : "smallStepSlider"
            smallSliderMaxWidth : my.smallStepSliderWidth
            background: "asset:///images/Player/SliderPrecision.png"
            visible: false
        	 layoutProperties: AbsoluteLayoutProperties {
        	 }
        }
    }

    attachedObjects: [
        // Dummy component for local variables
        ComponentDefinition {
            id: my
            property int smallStepSliderWidth: 400
            property int dt: 20 * 1000 // delta time in seconds
            property real longPressInitX
            property int minTime: 60 * 1000 // min time to show small steps slider
            property bool handlLongPressed: false
        },
        
        QTimer {
            id: seekInterval
            interval: 200
            onTimeout: {
                slideBar.immediateValue = smallStepSlider.value
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
                    sliderContainer.positionOfX = 0
                    sliderContainer.preferredWidth = Helpers.widthOfScreen
                    slider.layoutSize = Qt.size(Helpers.widthOfScreen, height)
                    timeArea.bottomPadding = 0
                    currentTimeLabel.bottomPadding = 0
                    sliderContainer.bottomPadding = 0
                    timeArea.rightPadding = 25
                    currentTimeLabel.leftPadding = 25
                    slideBar.slideBarHeight = 180;
                } else {
                    timeArea.verticalAlignment = VerticalAlignment.Bottom
                    currentTimeLabel.verticalAlignment = VerticalAlignment.Bottom
                    sliderContainer.positionOfX = currentTimeLabel.preferredWidth
                    sliderContainer.preferredWidth = Helpers.heightOfScreen - 2 * timeArea.preferredWidth
                    slider.layoutSize = Qt.size(Helpers.heightOfScreen - 2 * timeArea.preferredWidth, height)
                    timeArea.bottomPadding = 30
                    currentTimeLabel.bottomPadding = 30
                    sliderContainer.bottomPadding = 10
                    slideBar.slideBarHeight = 150;
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
            sliderContainer.positionOfX = 0
            sliderContainer.preferredWidth = Helpers.widthOfScreen
            slider.layoutSize = Qt.size(Helpers.widthOfScreen, height)
            timeArea.rightPadding = 25
            currentTimeLabel.leftPadding = 25
            timeArea.bottomPadding = 0 
            currentTimeLabel.bottomPadding = 0
            sliderContainer.bottomPadding = 0
            slideBar.slideBarHeight = 180;
        } else {
            timeArea.verticalAlignment = VerticalAlignment.Bottom
            currentTimeLabel.verticalAlignment = VerticalAlignment.Bottom
            sliderContainer.positionOfX = currentTimeLabel.preferredWidth
            sliderContainer.preferredWidth = Helpers.heightOfScreen - 2 * timeArea.preferredWidth
            slider.layoutSize = Qt.size(Helpers.heightOfScreen - 2 * timeArea.preferredWidth, height)
            timeArea.bottomPadding = 30
            currentTimeLabel.bottomPadding = 30
            sliderContainer.bottomPadding = 10
            slideBar.slideBarHeight = 150;
        }
    }

}