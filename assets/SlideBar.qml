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
    property bool onSlider: false
    property int height: 105
    property bool pauseHandle
    property variant layoutSize
    property int bookmarkPositionX
    property int progressBarPositionX
    property bool bookmarkTouched: false
    property bool bookmarkVisible: true
    property int timeAreaWidth: 180
    property int timeAreaHeight: 70
    property int sliderHandleWidth: 87
    property real factor: 105
    property real slideBarHeight
    preferredHeight: slideBarHeight + 50

    layout: DockLayout {

    }
    Container {
        preferredHeight: slideBarHeight
        layout: DockLayout {
        
        }
    background: backgroundImage.imagePaint
    verticalAlignment: VerticalAlignment.Bottom
    horizontalAlignment: HorizontalAlignment.Fill

    
    Container {
        layout: StackLayout {
            
        }
        id: sliderContainer
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Center
        property int positionOfX

        CustomSlider {
            id: slider
            objectName: "slider"
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Bottom
            fromValue: slideBar.fromValue
            toValue: slideBar.toValue

            onHandleLongPressed: {
                slideBar.onSlider = true;
                if (slider.toValue > my.minTime) {
                    bpsEventHandler.startVibration(20,200);
                    smallStepSlider.smallCurrentValue = slider.value;
                    smallStepSlider.visible = true;
                    if (slider.value - my.dt < slider.fromValue) {
                        smallStepSlider.fromValue = slider.fromValue;
                        smallStepSlider.toValue = slider.value + my.dt;
                        smallStepSlider.value = slider.value;
                        smallStepSlider.layoutSize = Qt.size((my.smallStepSliderWidth - slideBar.factor) * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + slideBar.factor, slideBar.height)
                    } else if (slider.value + my.dt > slider.toValue) {
                        smallStepSlider.fromValue = slider.value - my.dt;
                        smallStepSlider.toValue = slider.toValue;
                        smallStepSlider.value = slider.value;
                        smallStepSlider.layoutSize = Qt.size((my.smallStepSliderWidth - slideBar.factor) * (smallStepSlider.toValue - smallStepSlider.fromValue) / (2 * my.dt) + slideBar.factor, slideBar.height)
                    } else {
                        smallStepSlider.fromValue = slider.value - my.dt;
                        smallStepSlider.toValue = slider.value + my.dt;
                        smallStepSlider.value = slider.value;
                        smallStepSlider.layoutSize = Qt.size(my.smallStepSliderWidth, slideBar.height)
                    }

                    smallStepSlider.layoutProperties.positionX = slider.handleLocalX() - smallStepSlider.handleLocalX() + sliderContainer.positionOfX;
                    my.longPressInitX = positionX;
                    my.handlLongPressed = true;

                    if (OrientationSupport.orientation == UIOrientation.Portrait) {
                        smallStepSlider.smallCordX = smallStepSlider.layoutProperties.positionX;
                        if (smallStepSlider.layoutProperties.positionX < -20) {
                            smallStepSlider.layoutProperties.positionX = -20;
                        }
                    }
                    smallStepSlider.animation = true;
                    seekInterval.start();
                } else
                    slider.setLongPressEnabled(false);
            }

            onMediaStateChanged: {

                slideBar.pauseHandle = mediaState
            }

            onMove: {
                if (slider.toValue > my.minTime)
                    smallStepSlider.value = smallStepSlider.fromSmallSliderPosXToValue(windowX - smallStepSlider.layoutProperties.positionX - my.longPressInitX);
                slider.value = slideBar.value = smallStepSlider.value;
            }

            onHandleReleased: {
                seekInterval.stop();
                slideBar.onSlider = false;
                my.handlLongPressed = false;
                smallStepSlider.visible = false;
            }

            onImmediateValueChanged: {
                slideBar.immediateValue = immediateValue;
                slideBar.value = value;
            }
        }
    }
    Container {
        layout: DockLayout {
        }
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Center
        preferredHeight: slideBar.height
        overlapTouchPolicy: OverlapTouchPolicy.Allow
    TimeArea {
        id: timeArea
        timeInMsc: slideBar.toValue
        horizontalAlignment: HorizontalAlignment.Right
        
    }

    TimeArea {
        id: currentTimeLabel
        timeInMsc: slideBar.value
        horizontalAlignment: HorizontalAlignment.Left
    }
}

    Container {
        id: smallSliderContainer
        verticalAlignment: VerticalAlignment.Center
        horizontalAlignment: HorizontalAlignment.Fill
        implicitLayoutAnimationsEnabled: false
        layout: AbsoluteLayout {
        }
        CustomSlider {
            id: smallStepSlider
            objectName: "smallStepSlider"
            smallSliderMaxWidth: my.smallStepSliderWidth
            background: "asset:///images/Player/SliderPrecision.png"
            visible: false
            layoutProperties: AbsoluteLayoutProperties {
                positionY: 10
            }            
        }
    }
}
	
	
Container {
    topPadding: Helpers.bookmarkPaddingYInPortrait
    translationX: slideBar.bookmarkPositionX
    id: bookmark
    verticalAlignment: VerticalAlignment.Top
    layout: DockLayout {
    }
    implicitLayoutAnimationsEnabled: false
    ImageView {
        id: bookmarkIcon
        visible: slideBar.bookmarkVisible
        imageSource: "asset:///images/Player/BookmarkIcon.png"
        implicitLayoutAnimationsEnabled: false
        //            layoutProperties: AbsoluteLayoutProperties {
        //                positionX: bookmarkPositionX
        //            }
        gestureHandlers: [
            TapHandler {
                onTapped: {
                    console.log("bookmark touched =====")
                    slideBar.bookmarkTouched = ! slideBar.bookmarkTouched
                }
            }
        ]
        onVisibleChanged: {
            if (visible) {
                slider.showBookmarkProgressBar(progressBarPositionX);
            } else {
                slider.hideBookmarkProgressBar();
            }
        }
    
    } //bookmark Icon
    
    animations: [
        TranslateTransition {
            id: moveDown
            toY: OrientationSupport.orientation == UIOrientation.Portrait? Helpers.bookmarkAnimationForwardYPortrait : 45  
            duration: 100
            onEnded: {
                moveUp.play();
            }
        },
        TranslateTransition {
            id: moveUp
            toY: OrientationSupport.orientation == UIOrientation.Portrait ? Helpers.bookmarkAnimationBackYPortrait : 7
            duration: 100
            onEnded: {
                myPlayer.seekTime(infoListModel.getVideoPosition());
                fadeOut.play();
            }
        },
        FadeTransition {
            id: fadeOut
            fromOpacity: 1
            toOpacity: 0
            duration: 600
            onEnded: {
                slideBar.bookmarkVisible = false;
                bookmark.opacity = 1;
            }
        }
    ]
} //bookmark
	
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
                    sliderContainer.preferredWidth = displayInfo.height
                    slider.layoutSize = Qt.size(displayInfo.height, height)
                    sliderContainer.bottomPadding = -10
                    smallSliderContainer.bottomPadding = 0
                    timeArea.rightPadding = Helpers.timeAreasHorizontalPaddingInPortrait
                    currentTimeLabel.leftPadding = Helpers.timeAreasHorizontalPaddingInPortrait
                    timeArea.topPadding = Helpers.timeAreasVerticalPaddingInPortrait;
                    currentTimeLabel.topPadding = Helpers.timeAreasVerticalPaddingInPortrait;
                    smallSliderContainer.verticalAlignment = VerticalAlignment.Bottom
                    smallStepSlider.layoutProperties.positionY = 35
                    slideBar.slideBarHeight = 130;
                    bookmark.topPadding = Helpers.bookmarkPaddingYInPortrait
                } else {
                    timeArea.verticalAlignment = VerticalAlignment.Center
                    currentTimeLabel.verticalAlignment = VerticalAlignment.Center
                    sliderContainer.positionOfX = slideBar.timeAreaWidth
                    sliderContainer.preferredWidth = displayInfo.width - 2 * slideBar.timeAreaWidth
                    slider.layoutSize = Qt.size(displayInfo.width - 2 * slideBar.timeAreaWidth, height)
                    currentTimeLabel.leftPadding = Helpers.timeAreasHorizontalPaddingInLandscape
                    timeArea.rightPadding = Helpers.timeAreasHorizontalPaddingInLandscape
                    timeArea.topPadding = Helpers.timeAreasVerticalPaddingInLandscape
                    currentTimeLabel.topPadding = Helpers.timeAreasVerticalPaddingInLandscape
                    sliderContainer.bottomPadding = 0
                    smallSliderContainer.bottomPadding = 10
                    smallSliderContainer.verticalAlignment = VerticalAlignment.Center
                    smallStepSlider.layoutProperties.positionY = 10
                    slideBar.slideBarHeight = 115;
                    bookmark.topPadding = Helpers.bookmarkPaddingYInLandscape;
                }
            }
        }
    ]

    function startBookmarkAnimation() {
        moveDown.play()
    }

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
            sliderContainer.preferredWidth = displayInfo.height
            slider.layoutSize = Qt.size(displayInfo.height, height)
            timeArea.rightPadding = Helpers.timeAreasHorizontalPaddingInPortrait
            currentTimeLabel.leftPadding = Helpers.timeAreasHorizontalPaddingInPortrait
            timeArea.topPadding = Helpers.timeAreasVerticalPaddingInPortrait;
            currentTimeLabel.topPadding = Helpers.timeAreasVerticalPaddingInPortrait;
            sliderContainer.bottomPadding = -10
            smallSliderContainer.verticalAlignment = VerticalAlignment.Top
            smallStepSlider.layoutProperties.positionY = 35
            slideBar.slideBarHeight = 130;
            bookmark.topPadding = Helpers.bookmarkPaddingYInPortrait
        } else { 
            timeArea.verticalAlignment = VerticalAlignment.Center
            currentTimeLabel.verticalAlignment = VerticalAlignment.Center
            sliderContainer.positionOfX = slideBar.timeAreaWidth
            sliderContainer.preferredWidth = displayInfo.width - 2 * slideBar.timeAreaWidth 
            slider.layoutSize = Qt.size(displayInfo.width - 2 * slideBar.timeAreaWidth, height)
            currentTimeLabel.leftPadding = Helpers.timeAreasHorizontalPaddingInLandscape
            timeArea.rightPadding = Helpers.timeAreasHorizontalPaddingInLandscape
            timeArea.topPadding = Helpers.timeAreasVerticalPaddingInLandscape
            currentTimeLabel.topPadding = Helpers.timeAreasVerticalPaddingInLandscape
            sliderContainer.bottomPadding = 0
            smallSliderContainer.verticalAlignment = VerticalAlignment.Center
            smallStepSlider.layoutProperties.positionY = 10
            slideBar.slideBarHeight = 115;
            bookmark.topPadding = Helpers.bookmarkPaddingYInLandscape;
        }
    }

	onProgressBarPositionXChanged: {
    	if (slideBar.bookmarkVisible) {
        	slider.showBookmarkProgressBar(progressBarPositionX);
        	}
    }
   
}



