import bb.cascades 1.0
import bb.multimedia 1.0
import bb.system 1.0
import nuttyPlayer 1.0
import bpsEventHandler 1.0
import nutty.slider 1.0
import customtimer 1.0
import system 1.0
import "helpers.js" as Helpers

Page {
    id: pgPlayer

    actionBarVisibility: ChromeVisibility.Hidden    

    property variant currentPath: ""
    property variant currentLenght: 0
    property bool isHDMIVideoPlaying: HDMIPlayer.playing
    property bool startListening
    property bool isHDMIVideoStopped: HDMIPlayer.stopped
    property bool isPlaying: false
    property int slideAction_BarsHeight: (OrientationSupport.orientation == UIOrientation.Portrait) ? durationSlider.slideBarHeight + Helpers.actionBarPortraitHeight : durationSlider.slideBarHeight + Helpers.actionBarLandscapeHeight
    property int rateOfChangeVolume: 6
    
    onSlideAction_BarsHeightChanged: {
        pgPlayer.updateSubtitlesPosition();
    }
    
    function updateSubtitlesPosition() {
        if (controlsContainer.visible) {
            subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - slideAction_BarsHeight;
        } else {
            subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - Helpers.distanceFromSubtitleToBottomOfScreen;
        }
    }

    onIsHDMIVideoPlayingChanged: {
        if(isHDMIVideoPlaying)
            slideBarTimer.start();
        else
            slideBarTimer.stop();
    }

    onIsHDMIVideoStoppedChanged: {
        if(HDMIPlayer.stopped && startListening) {
            appContainer.goBack();
        }
    }

    Container {
        id: appContainer
        background: backgroundImage.imagePaint
        implicitLayoutAnimationsEnabled: false

        layout: DockLayout {
        }

        property int counterForDetectDirection: 5
        property int previousPositionX: 0
        property int previousPositionY: 0
        property int offsetX: 0
        property int offsetY: 0
        property bool directionIsDetect: false
        property bool volumeChange: false
        property bool volumeFullorMute: false

        property int heightOfScreen
        property int widthOfScreen
        //This variable is used to control video duration logic.
        //Indicates whether to change the video position, when the slider's value is changed.
        property bool changeVideoPosition: false

        property int startHeight
        property int startWidth
        property int videoWidth
        property int videoHeight

        property int subtitleAreaBottomPadding: 200

        property double maxPinchPercentFactor: 1.2 //120 percent
        property double minPinchPercentFactor: 0.8 //80 percent

        property int touchPositionX: 0
        property int touchPositionY: 0

        property double minScreenScale: 0.5 //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0 //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScaleX: 1.0 // Starts the video with original dimensions (that is, scale factor 1.0)
        property double initialScreenScaleY: 1.0 // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
        // They both start with the same value but the "initialScale" value is different for every new pinch
        property double startPinchDistance: 0.0
        property double startTranslationX: 0.0
        property double startTranslationY: 0.0
        property double startMidPointX: 0.0
        property double startMidPointY: 0.0
        property double coefficientOfZoom: 0
        property bool isPinchZoom

        property double curVolume: system.getVolume(); // system speaker volume current value

        //        property bool videoTitleVisible : false
        property int touchDistanceAgainstMode: 0; // This is used to have 2 different distances between the point tounched
        // and the point released. This is needed for differentiation of
        // gestures handling for "zoom out" and "seek 5 seconds"
        property bool videoScrollBarIsClosing: false; // If the video Scroll bar is in closing process
        property int bookmarkMinTime: 60000   							//ignoring bookmark in the first minute
        property int bookmarkMaxTime: durationSlider.toValue * 0.995  	//ignoring bookmark in the last 0.5% of duration
        property int retryCount: 5

        function setDimensionsFromOrientation(pOrientation) {
            if (pOrientation == UIOrientation.Landscape) {
                appContainer.heightOfScreen = displayInfo.height;
                appContainer.widthOfScreen = displayInfo.width;
                videoWindow.preferredHeight = displayInfo.height;
                videoWindow.preferredWidth = displayInfo.width
            } else {
                appContainer.heightOfScreen = displayInfo.width;
                appContainer.widthOfScreen = displayInfo.height;
                videoWindow.preferredHeight = displayInfo.width;
                videoWindow.preferredWidth = displayInfo.height
            }
        }

        Container {
            id: contentContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            implicitLayoutAnimationsEnabled: false

            layout: DockLayout {
            }

            property int startingX
            property int startingY

            Container {
                implicitLayoutAnimationsEnabled: false
                layout: AbsoluteLayout {
                }
                id: foreignWindowControlContainer
                touchBehaviors: [
                    TouchBehavior {
                        TouchReaction {
                            eventType: TouchType.Down
                            phase: PropagationPhase.Bubbling
                            response: TouchResponse.StartTracking
                        }
                    }
                ]

                ForeignWindowControl {
                    id: videoWindow
                    objectName: "VideoWindow"
                    windowId: "VideoWindow"
                    implicitLayoutAnimationsEnabled: false
                    layoutProperties: AbsoluteLayoutProperties {
                    }
                    property double startScaleX
                    property double startScaleY
                    signal initializeVideoScales

                    // This custom property determines how quickly the ForeignWindow grows
                    // or shrinks in response to the pinch gesture
                    property double scaleFactor: 0.5

                    // Temporary variable, used in computation for pinching everytime
                    property double newScaleVal

                    gestureHandlers: []
                    animations: [
                        ScaleTransition {
                            id: scaleAnimation
                            toX: appContainer.initialScreenScaleX
                            toY: appContainer.initialScreenScaleY
                            duration: 200
                        }
                    ]

                    visible: boundToWindow
                    updatedProperties: WindowProperty.Size | WindowProperty.Position | WindowProperty.Visible

                    onCreationCompleted: {
                        appContainer.setDimensionsFromOrientation(OrientationSupport.orientation);
                        initializeVideoScales();
                        appContainer.startWidth = videoWindow.preferredWidth;
                        appContainer.startHeight = videoWindow.preferredHeight;
                    }

                    onInitializeVideoScales: {
                        appContainer.videoWidth = infoListModel.getWidth()
                        appContainer.videoHeight = infoListModel.getHeight()
                        if (appContainer.videoHeight / appContainer.videoWidth >= appContainer.heightOfScreen / appContainer.widthOfScreen) {
                            videoWindow.scaleY = appContainer.initialScreenScaleY = 1
                            videoWindow.scaleX = appContainer.initialScreenScaleX = (appContainer.videoWidth * appContainer.heightOfScreen / appContainer.videoHeight) / videoWindow.preferredWidth
                        } else {
                            videoWindow.scaleX = appContainer.initialScreenScaleX = 1;
                            videoWindow.scaleY = appContainer.initialScreenScaleY = (appContainer.videoHeight * appContainer.widthOfScreen / appContainer.videoWidth) / videoWindow.preferredHeight
                        }
                        videoWindow.translationX = 0
                        videoWindow.translationY = 0
                    }
                    onVisibleChanged: {
                        console.log("foreignwindow visible = " + visible);
                    }
                    onBoundToWindowChanged: {
                        console.log("VideoWindow bound to mediaplayer!");
                    }

                    attachedObjects: [
                        ImplicitAnimationController {
                            propertyName: "scaleX"
                            enabled: false
                        },
                        ImplicitAnimationController {
                            propertyName: "scaleY"
                            enabled: false
                        }
                    ]
                } //videoWindow
                onTouch: {
                    if (! appContainer.isPinchZoom) {
                        if (OrientationSupport.orientation == UIOrientation.Portrait) {
                            appContainer.heightOfScreen = displayInfo.width;
                            appContainer.widthOfScreen = displayInfo.height;
                            appContainer.touchDistanceAgainstMode = displayInfo.height / 5;
                        } else {
                            appContainer.heightOfScreen = displayInfo.height;
                            appContainer.widthOfScreen = displayInfo.width;
                            appContainer.touchDistanceAgainstMode = displayInfo.width / 5;
                        }
                        if (event.windowY < appContainer.heightOfScreen - pgPlayer.slideAction_BarsHeight) {
                            if (event.touchType == TouchType.Down) {
                                appContainer.previousPositionX = event.windowX;
                                appContainer.previousPositionY = event.windowY;
                                appContainer.touchPositionX = event.windowX;
                                appContainer.touchPositionY = event.windowY;
                                contentContainer.startingX = videoWindow.translationX;
                                contentContainer.startingY = videoWindow.translationY;
                                appContainer.directionIsDetect = false;
                                appContainer.volumeChange = false;
                                appContainer.volumeFullorMute = false;
                                appContainer.counterForDetectDirection = 5;
                                appContainer.offsetX = 0;
                                appContainer.offsetY = 0;

                            } else if (event.touchType == TouchType.Up && ! appContainer.volumeChange) {
                                if (Math.abs(appContainer.touchPositionX - event.windowX) > appContainer.touchDistanceAgainstMode) {
                                    // TODO: probably we could use the application container size
                                    // to calculate the magic numbers below by the percentage

                                    if (appContainer.touchPositionX >= event.windowX + appContainer.touchDistanceAgainstMode) {
                                        appContainer.changeVideoPosition = true;
                                        if (durationSlider.value + Helpers.seekTimeInSlide < durationSlider.toValue) {
                                            if(HDMIScreen.connection) {
                                                HDMIPlayer.seekToValue((durationSlider.value + Helpers.seekTimeInSlide).toString() );
                                            } else {
                                                myPlayer.seekTime(durationSlider.value + Helpers.seekTimeInSlide);
                                            }
                                        } else {
                                            if(HDMIScreen.connection) {
                                                HDMIPlayer.seekToValue(durationSlider.immediateValue.toString());
                                            } else {
                                                myPlayer.seekTime(durationSlider.toValue);
                                            }
                                        }
                                    } else if (appContainer.touchPositionX + appContainer.touchDistanceAgainstMode < event.windowX) {
                                        appContainer.changeVideoPosition = true;
                                        if(HDMIScreen.connection) {
                                            HDMIPlayer.seekToValue(Math.max(durationSlider.value - Helpers.seekTimeInSlide, 0).toString());
                                        } else {
                                            myPlayer.seekTime(Math.max(durationSlider.value - Helpers.seekTimeInSlide, 0));
                                        }
                                    }
                                    appContainer.changeVideoPosition = false;
                                }
                                if (event.windowY > 180 && videoListScrollBar.isVisible && ! appContainer.videoScrollBarIsClosing) {
                                    videoListDisappearAnimation.play();
                                }
                            } else if (event.touchType == TouchType.Move) {
                                if (! appContainer.directionIsDetect) {

                                    if (appContainer.counterForDetectDirection != 0) {
                                        appContainer.offsetX += Math.abs(appContainer.previousPositionX - event.windowX);
                                        appContainer.offsetY += Math.abs(appContainer.previousPositionY - event.windowY);
                                        -- appContainer.counterForDetectDirection;
                                    } else {
                                        if (appContainer.offsetX > appContainer.offsetY) {
                                            appContainer.directionIsDetect = true;
                                        } else {
                                            appContainer.volumeChange = true;
                                            var deltaPosition = appContainer.previousPositionY - event.localY;
                                            // limit the size of deltaPosition to avoid any large jumps in the volume
                                            if (Math.abs(deltaPosition) < 70) {
                                                // min and max to bound value between 0 and 100
                                                appContainer.curVolume = Math.min(Math.max(appContainer.curVolume + deltaPosition / pgPlayer.rateOfChangeVolume, 0), 100);
                                            }
                                            system.setVolume(appContainer.curVolume);
                                            volume.setVolumeIcons();
                                            volume.setVisible(true);
                                            uiControlsShowTimer.start();
                                        }
                                    }
                                    appContainer.previousPositionX = event.windowX;
                                    appContainer.previousPositionY = event.windowY;
                                }
                            }
                        }
                    }
                    if (event.touchType == TouchType.Up && appContainer.isPinchZoom) {
                        appContainer.isPinchZoom = false;
                    }
                } // onTouch

                gestureHandlers: [
                    TapHandler {
                        onTapped: {
                            if (event.y < appContainer.heightOfScreen - pgPlayer.slideAction_BarsHeight
                                && ! videoListScrollBar.isVisible && ! appContainer.videoScrollBarIsClosing) {
                                appContainer.showPlayPauseButton();
                                actionBarVisibility = ChromeVisibility.Overlay;
                            } else if (event.y > appContainer.heightOfScreen - pgPlayer.slideAction_BarsHeight 
                                && !controlsContainer.visible) {                                
                                subtitleButtonContainer.setOpacity(1);
                                controlsContainer.setVisible(true);
                                upperMenu.setOpacity(1);
                                volume.setVisible(true);
                                actionBarVisibility = ChromeVisibility.Overlay
                                uiControlsShowTimer.start();
                            }
                        }
                    },
                    // Add a handler for pinch gestures
                    PinchHandler {
                        onPinchStarted: {
                            videoWindow.startScaleX = videoWindow.scaleX;
                            videoWindow.startScaleY = videoWindow.scaleY;
                            appContainer.startTranslationX = videoWindow.translationX;
                            appContainer.startTranslationY = videoWindow.translationY;
                            appContainer.startPinchDistance = event.distance;
                            appContainer.startMidPointX = event.midPointX;
                            appContainer.startMidPointY = event.midPointY;
                            appContainer.isPinchZoom = true;
                            appContainer.startWidth = videoWindow.preferredWidth;
                            appContainer.startHeight = videoWindow.preferredHeight;
                        }

                        // As the pinch expands or contracts, change the scale of
                        // the image
                        onPinchUpdated: {
                            appContainer.coefficientOfZoom = event.distance / appContainer.startPinchDistance;
                            if (appContainer.coefficientOfZoom <= 1 || videoWindow.scaleX / appContainer.initialScreenScaleX < 4) {
                                videoWindow.scaleX = videoWindow.startScaleX * appContainer.coefficientOfZoom;
                                videoWindow.scaleY = videoWindow.startScaleY * appContainer.coefficientOfZoom;
                            } else {
                                appContainer.coefficientOfZoom = 1;
                            }
                            videoWindow.translationX = appContainer.startTranslationX // start translation + (appContainer.startTranslationX + videoWindow.preferredWidth / 2 - appContainer.startMidPointX) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointX isn't changed + (event.midPointX - appContainer.startMidPointX); // translation in time of move

                            videoWindow.translationY = appContainer.startTranslationY // start translation + (appContainer.startTranslationY + videoWindow.preferredHeight / 2 - appContainer.startMidPointY) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointY isn't changed
                            + (event.midPointY - appContainer.startMidPointY); // translation in time of move
                        } // onPinchUpdate
                        onPinchCancelled: {
                            pinchFinalize();
                        }
                        onPinchEnded: {
                            pinchFinalize();
                        }

                        function pinchFinalize() {
                            if (videoWindow.scaleX < appContainer.initialScreenScaleX || videoWindow.scaleY < appContainer.initialScreenScaleY) {
                                scaleAnimation.play();
                                videoWindow.translationX = 0;
                                videoWindow.translationY = 0;
                                if (appContainer.videoHeight / appContainer.videoWidth >= appContainer.heightOfScreen / appContainer.widthOfScreen) {
                                    videoWindow.scaleX = appContainer.initialScreenScaleX = (appContainer.videoWidth * appContainer.heightOfScreen / appContainer.videoHeight) / videoWindow.preferredWidth
                                    videoWindow.scaleY = appContainer.initialScreenScaleY = 1;
                                } else {
                                    videoWindow.scaleY = appContainer.initialScreenScaleY = (appContainer.videoHeight * appContainer.widthOfScreen / appContainer.videoWidth) / videoWindow.preferredHeight
                                    videoWindow.scaleX = appContainer.initialScreenScaleX = 1;
                                }
                            } else {
                                if (appContainer.videoHeight / appContainer.videoWidth >= appContainer.heightOfScreen / appContainer.widthOfScreen) {
                                    if (videoWindow.scaleX <= 1) {
                                        videoWindow.translationX = 0
                                    }
                                } else {
                                    if (videoWindow.scaleY <= 1) {
                                        videoWindow.translationY = 0
                                    }
                                }
                            }
                            if (videoWindow.scaleX > 1) {

                                if (videoWindow.translationX > (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2)) {
                                    videoWindow.translationX = (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2);
                                }
                                if (videoWindow.translationX < - ((((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2) )) {
                                    videoWindow.translationX = - (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2);
                                }
                            }
                            if (videoWindow.scaleY > 1) {
                                if (videoWindow.translationY > (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2)) {
                                    videoWindow.translationY = (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2);
                                }
                                if (videoWindow.translationY < - ((((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2) )) {
                                    videoWindow.translationY = - (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2);
                                }
                            }
                        }
                    } // PinchHandler
                ] // attachedObjects
                // Play/pause image is transparent. It will become visible when the video
                // is played/paused using tap event. It will be visible 1 sec.

                //Subtitle area
                Container {
                    id: subtitleContainer
                    preferredWidth: videoWindow.preferredWidth
                    implicitLayoutAnimationsEnabled: false
                    layout: DockLayout {
                    }
                    layoutProperties: AbsoluteLayoutProperties {
                        positionX: 0
                    }
                    Container {
                        id: subtitleAreaContainer
                        preferredWidth: videoWindow.preferredWidth - Helpers.differentScreenWidthAndSubtitleWidth
                        horizontalAlignment: HorizontalAlignment.Center
                        layout: DockLayout {

                        }
                        SubtitleArea {
                            id: subtitleArea
                            horizontalAlignment: HorizontalAlignment.Center
                        }
                    }

                    Container {
                        layout: DockLayout {
                        }
                        id: subtitleButtonContainer
                        objectName: subtitleButtonContainer
                        opacity: 0.5
                        preferredWidth: Helpers.widthOfSubtitleButton
                        verticalAlignment: VerticalAlignment.Bottom
                        horizontalAlignment: HorizontalAlignment.Right
                        leftPadding: 15
                        implicitLayoutAnimationsEnabled: false
                        property bool subtitleEnabled
                        property bool videoHasSubtitles
                        signal initializeStates
                        onCreationCompleted: {
                            subtitleButtonContainer.videoHasSubtitles = false;
                            initializeStates();
                        }
                        onSubtitleEnabledChanged: {
                            subtitleButtonContainer.showSubButton();
                        }
                        
                        onVideoHasSubtitlesChanged: {
                            if (subtitleButtonContainer.videoHasSubtitles) {
                                subtitleEnabled = true;
                                subtitleButtonContainer.showSubButton();
                            } else {
                                subtitleEnabled = false;
                                subtitleButtonContainer.showSubButton();
                            }
                        }

                        onInitializeStates: {
                            subtitleEnabled = true;
                            subtitleButtonContainer.showSubButton();
                        }

                        function showSubButton() {
                            if (subtitleEnabled && subtitleButtonContainer.videoHasSubtitles) {
                                subtitleAreaContainer.setOpacity(1);
                                subtitleActionItem.imageSource = "asset:///images/Player/subt_icon_on.png"
                            } else {
                                subtitleAreaContainer.setOpacity(0);
                                subtitleActionItem.imageSource = "asset:///images/Player/subt_icon_off.png"
                            }
                        }
                    } //subtitleButtonContainer
                }
            }

            Container {
                id: volume
                layout: StackLayout {
                    orientation: LayoutOrientation.TopToBottom
                }
                scaleX: Helpers.volumeBarScaleX
                scaleY: Helpers.volumeBarScaleY
                leftPadding: 50
                verticalAlignment: VerticalAlignment.Center //orientationHandler.orientation == UIOrientation.Portrait ? VerticalAlignment.Center : VerticalAlignment.Center
                visible: false
                preferredHeight: 2 * volumeFuleAndMuteHeight + indicator_length
                property int volumeFuleAndMuteHeight: 70
                property int indicator_length: Helpers.volumeIndicatorLength
                property int indicator_count: Helpers.volumeBarIndicatorsCount
                property int indicators_length: 10
                property int indicators_space: 8
                property int currentActiveIndicatorsCount: (appContainer.curVolume / 100) * (volume.indicator_count + 1)

                // this function changes the icons on the volume bar when the volume reaches its extremes
                function setVolumeIcons() {
                    if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png";
                    else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                    if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png";
                    else volumeFull.imageSource = "asset:///images/Player/VolumeFull.png";
                }

                ImageView {
                    id: volumeFull
                    imageSource: "asset:///images/Player/VolumeFull.png"
                    onTouch: {
                        if(event.touchType == TouchType.Down)
                        {
                            appContainer.volumeFullorMute = true
                            appContainer.curVolume = 100;
                            system.setVolume(appContainer.curVolume);
                            volume.setVolumeIcons();
                        }
                    }
                }

                Container {
                    preferredHeight: volume.indicator_length
                    leftPadding: 100
                    layout: AbsoluteLayout {
                    }
                    ImageView {
                        imageSource: "asset:///images/Player/VolumeInactive.png"
                        layoutProperties: AbsoluteLayoutProperties {
                            positionX: 10
                        }
                        onTouch: {
                            if (event.localY > 0 && event.localY < volume.indicator_length) {
                                appContainer.curVolume = (1 - event.localY / volume.indicator_length) * 100;
                                system.setVolume(appContainer.curVolume);
                                volume.setVolumeIcons();
                            }
                        }
                        touchBehaviors: [
                            TouchBehavior {
                                TouchReaction {
                                    eventType: TouchType.Down | TouchType.Move
                                    phase: PropagationPhase.AtTarget
                                    response: TouchResponse.StartTracking
                                }
                            }
                        ]
                    }
                    ImageView {
                        id: volumeActive
                        layoutProperties: AbsoluteLayoutProperties {
                            positionX: 10
                            positionY: (volume.indicator_count - ((volume.currentActiveIndicatorsCount==0 && appContainer.curVolume!=0 ) ? 1 : volume.currentActiveIndicatorsCount)) * (volume.indicators_length + volume.indicators_space)
                        }
                        overlapTouchPolicy: OverlapTouchPolicy.Allow
                        implicitLayoutAnimationsEnabled: false
                        imageSource: "asset:///images/Player/VolumeActive.png"
                    }
                }
                ImageView {
                    topMargin: 0
                    id: volumeMute
                    imageSource: "asset:///images/Player/VolumeMute.png"
                    property bool active: false
                    property double beforeMute

                    onTouch: {
                        if(event.touchType == TouchType.Down)
                        {
                            if (! volumeMute.active) {
                                volumeMute.beforeMute = system.getVolume();
                                appContainer.volumeFullorMute = true;
	                            appContainer.curVolume = 0;
	                            system.setVolume(appContainer.curVolume);
	                            volume.setVolumeIcons();
                            } else {
                                appContainer.curVolume = volumeMute.beforeMute;
                                system.setVolume(appContainer.curVolume);
                            }	                            
                        }
                    }
                    onImageSourceChanged: {
                        if (imageSource == "asset:///images/Player/VolumeMute.png") {
                            volumeMute.active = false;
                        } else {
                            volumeMute.active = true;
                        }
                    }
                }
                animations: [
                    FadeTransition {
                        id: volumeAnimation
                        fromOpacity: 1.0
                        toOpacity: 0.0
                        duration: 50
                        easingCurve: StockCurve.SineOut
                        onEnded: {
                            volume.visible = false
                            volume.opacity = 1.0
                        }
                    }
                ]
            } // volume container

            ImageView {
                id: screenPlayPauseImage
                implicitLayoutAnimationsEnabled: false
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
                animations: [
                    ParallelAnimation {
                        id: fadeInOut                      
                        FadeTransition {
                            toOpacity: 0.0
                            fromOpacity: 0.8
                            duration: 500 
                             easingCurve: StockCurve.SineIn
                        }
                        ScaleTransition {
                            fromX: 0.7
                            fromY: 0.7
                            toX: 1.2
                            toY: 1.2
                            duration: 400
                            easingCurve: StockCurve.SineIn
                        }
                    }
                ]
                onImageSourceChanged: {
                    if (imageSource == "asset:///images/Player/Play.png") {
                        playPauseActionItem.title = qsTr("Pause") + Retranslate.onLanguageChanged
                        playPauseActionItem.imageSource = "asset:///images/Player/Pause_icon.png"
                    } else {
                        playPauseActionItem.title = qsTr("Play") + Retranslate.onLanguageChanged;
                        playPauseActionItem.imageSource = "asset:///images/Player/Play_icon.png"
                    }
                }
            }
        } //contentContainer

        // Video list scroll bar for Portrait mode
        Container {
            translationY: -200
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            // Video list scroll bar for Portrait mode
            VideoListScrollBar {
                id: videoListScrollBar
                horizontalAlignment: HorizontalAlignment.Center
                overlapTouchPolicy: OverlapTouchPolicy.Allow
                currentPath: pgPlayer.currentPath
                visible: true
                isVisible: false

                onVideoSelected: {
                    infoListModel.setVideoPosition(durationSlider.value);
                    durationSlider.bookmarkVisible = false;
                    bookmarkTimer.stop();
                    infoListModel.setSelectedIndex(infoListModel.getVideoPosition(item.path));
                    durationSlider.resetValue();
                    durationSlider.setEnabled(true)
                    videoTitle.text = item.title;
                    pgPlayer.currentPath = item.path;
                    durationSlider.toValue = item.duration;
                    pgPlayer.currentLenght = item.duration;

                    if (HDMIScreen.connection) {
                        console.log("2nd screen connected");
                        startListening = false;
                        HDMIPlayer.setVideoSize(item.width, item.height)
                        HDMIPlayer.play(item.path);
                        controlsContainer.setOpacity(1);
                        controlsContainer.setVisible(true);
                        volume.setVisible(true);
                        // Starting listen with delay because HDMIPlayer emiting 1 stopped at the start
                        startListenForStopped.start();
                    } else {
                        myPlayer.setSourceUrl(item.path);
                        if (appContainer.playMediaPlayer() == MediaError.None) {
                            appContainer.retryCount = 5;
                            videoWindow.visible = true;
                            contentContainer.visible = true;
                            if (subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl)) {
                                subtitleButtonContainer.videoHasSubtitles = true;
                                subtitleButtonContainer.initializeStates();
                            } else {
                                console.log("Force to disable");
                                subtitleButtonContainer.videoHasSubtitles = false;
                                subtitleAreaContainer.setOpacity(0);
                            }
                            upperMenu.setOpacity(1);
                            controlsContainer.setOpacity(1);
                            subtitleButtonContainer.setOpacity(1);
                            controlsContainer.setVisible(true);
                            uiControlsShowTimer.start();
                            actionBarVisibility = ChromeVisibility.Overlay
                            videoWindow.initializeVideoScales();
                            myPlayer.seekTime(0);
                            myPlayer.valueChangedBySeek = false;
                        } else {
                            invalidToast.show();
                        }
                    }
                    infoListModel.markSelectedAsWatched();
                    videoListDisappearAnimation.play();
                    if (infoListModel.getVideoPosition() > appContainer.bookmarkMinTime && infoListModel.getVideoPosition() < appContainer.bookmarkMaxTime) {
                        durationSlider.bookmarkPositionX = durationSlider.getBookmarkPosition();
                        durationSlider.progressBarPositionX  = durationSlider.getProgressBarPosition();
                        durationSlider.bookmarkVisible = true;
                        bookmarkTimer.start();
                    }
                    if (loadingIndicator.running) {
                        loadingIndicator.stop();
                    }
                }
                attachedObjects: [
                    LayoutUpdateHandler {
                        id: videoListScrollLayout
                    }
                ]
            } // videoListScrollBar

            Container {
                id: upperMenu
                layout: DockLayout {
                }
                preferredWidth: 768
                opacity: 0
                Container {
                    id: videoTitleContainer
                    background: backgroundPaint.imagePaint
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    maxWidth: upperMenu.preferredWidth - 400
                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 3
                    bottomPadding: 7
                    opacity: 0.7
                    Label {
                        id: videoTitle
                        text: infoListModel.getVideoTitle()
                        textStyle.color: Color.White
                        textStyle.textAlign: TextAlign.Center
                        //maxWidth: handler.layoutFrame.width * 0.8
                        //verticalAlignment: VerticalAlignment.Center
                        //horizontalAlignment: HorizontalAlignment.Fill
                        textStyle.fontStyle: FontStyle.Italic
                    }
                    attachedObjects: [
                        ImagePaintDefinition {
                            id: backgroundPaint
                            imageSource: "asset:///images/Player/MovieTitleBG.png"
                            repeatPattern: RepeatPattern.Fill
                        },
                        LayoutUpdateHandler {
                            id: handler
                        }
                    ]
                } // videoTitleContainer
                
                implicitLayoutAnimationsEnabled: false

                attachedObjects: [
                    LayoutUpdateHandler {
                        id: upperMenuLayout
                    }
                ]
                animations: [
                    FadeTransition {
                        id: upperMenuAnimation
                        fromOpacity: 1.0
                        toOpacity: 0.0
                        duration: 50
                        easingCurve: StockCurve.SineOut
                    }
                ]
            }

            onCreationCompleted: {
                if (OrientationSupport.orientation == UIOrientation.Landscape) upperMenu.preferredWidth = displayInfo.width;
                else upperMenu.preferredWidth = displayInfo.height
            }

            animations: [
                TranslateTransition {
                    id: videoListAppearAnimation
                    duration: 300
                    easingCurve: StockCurve.CubicOut
                    fromY: - videoListScrollLayout.layoutFrame.height
                    toY: 0
                },
                TranslateTransition {
                    id: videoListDisappearAnimation
                    duration: 400
                    easingCurve: StockCurve.ExponentialIn
                    fromY: 0
                    toY: - videoListScrollLayout.layoutFrame.height
                    onStarted: {
                        appContainer.videoScrollBarIsClosing = true;
                    }
                    onEnded: {
                        appContainer.videoScrollBarIsClosing = false;
                        videoListScrollBar.isVisible = false;
                    }
                }
            ]
            onTouch: {
                if (upperMenu.opacity == 0 ) {  
                    subtitleButtonContainer.setOpacity(1);
                    controlsContainer.setVisible(true);
                    upperMenu.setOpacity(1);
                    volume.setVisible(true);
                    actionBarVisibility = ChromeVisibility.Overlay;                    
                }
                uiControlsShowTimer.start();
            }
        }

        Container {
            id: controlsContainer
            translationY: OrientationSupport.orientation == UIOrientation.Portrait ? - Helpers.actionBarPortraitHeight : - Helpers.actionBarLandscapeHeight
            visible: false
            enabled: true
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom
            onVisibleChanged: {
                pgPlayer.updateSubtitlesPosition();
            }
            Container {
                id: sliderContainer
                objectName: sliderContainer

                layout: StackLayout {
                    orientation: LayoutOrientation.LeftToRight
                }

                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Bottom

                SlideBar {
                    id: durationSlider
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center

                    bookmarkPositionX: getBookmarkPosition()
                    progressBarPositionX: getProgressBarPosition()
                    bookmarkVisible: false
                    toValue: pgPlayer.currentLenght
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    onImmediateValueChanged: {
                        if(HDMIScreen.connection) {
                            HDMIPlayer.seekToValue(durationSlider.immediateValue.toString());
                        } else if (myPlayer.mediaState == MediaState.Started || myPlayer.mediaState == MediaState.Paused) {
                            myPlayer.seekTime(durationSlider.immediateValue);
                            myPlayer.valueChangedBySeek = true
                        }
                    }
                    property bool previousState: false
                    onPauseHandleChanged: {
                        if (myPlayer.mediaState == MediaState.Started && durationSlider.pauseHandle) {
                            previousState = true;
                            appContainer.pauseMediaPlayer();
                        } else if (myPlayer.mediaState == MediaState.Paused && ! durationSlider.pauseHandle && previousState) {
                            appContainer.playMediaPlayer();
                            previousState = false;
                        }
                        if (! durationSlider.pauseHandle) {
                            myPlayer.valueChangedBySeek = false;
                        }
                    }

                    onTouch: {
                        uiControlsShowTimer.start();
                    }
                    onBookmarkTouchedChanged: {
                        durationSlider.startBookmarkAnimation();
                        bookmarkTimer.stop();
                    }

                    function getBookmarkPosition() {
                        return OrientationSupport.orientation == UIOrientation.Landscape ? timeAreaWidth + (displayInfo.width - height - timeAreaWidth * 2) * (infoListModel.getVideoPosition() / pgPlayer.currentLenght) + 24: (displayInfo.height - height) * (infoListModel.getVideoPosition() / pgPlayer.currentLenght) + 24;
                    }

                    function getProgressBarPosition() {
                        return OrientationSupport.orientation == UIOrientation.Landscape ? (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.width - height - timeAreaWidth * 2) + 10: (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.height - height) + 10;
                    }

                } //durationSlider
            } //sliderContainer
            animations: [
                FadeTransition {
                    id: controlsAnimation
                    fromOpacity: 1.0
                    toOpacity: 0.0
                    duration: 50
                    easingCurve: StockCurve.SineOut
                    onEnded: {
                        controlsContainer.visible = false
                        controlsContainer.opacity = 1.0
                    }
                }
            ]
        } //controlsContainer
        
        Container {    
            id: loadingIndicatorContainer    
            visible: loadingIndicator.running   
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            ActivityIndicator {
                id: loadingIndicator        
                property int indicatorSize: 200            
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                preferredHeight: loadingIndicator.indicatorSize
                preferredWidth: loadingIndicator.indicatorSize
            }
            Label {
                id: loadingText 
                visible: loadingIndicator.running
                text: "Loading video from remote source"
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center  
                textStyle.fontSize: FontSize.Small       
            }
            Button {
                id: loadingButton
                text: "Cencel"     
                visible: loadingIndicator.running   
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center 
                onTouch: {
                    if (event.touchType == TouchType.Up) {
                        myPlayer.destroy();
                        pgPlayer.destroy();		                           
                        if(navigationPane.top == navigationPane.at(1))
                            navigationPane.pop();                               
                    }      
                } 
            }
        }

        function playMediaPlayer() {
            if (bpsEventHandler.locked)
                return; // Video does not play if phone is locked
            return myPlayer.play();
        }

        function pauseMediaPlayer() {
            return myPlayer.pause();
        }
        function seekPlayer(time) {
            if(HDMIScreen.connection) {
                HDMIPlayer.seekToValue(time.toString());
            } else {
                myPlayer.seekTime(time);
                myPlayer.valueChangedBySeek = true;
                appContainer.changeVideoPosition = false;
            }
        }

        function showPlayPauseButton() {
            if(HDMIScreen.connection) {
                HDMIPlayer.pause(! HDMIPlayer.paused);
                screenPlayPauseImage.imageSource = HDMIPlayer.paused ? "asset:///images/Player/Pause.png" : "asset:///images/Player/Play.png"
            } else if (myPlayer.mediaState != MediaState.Started) {
                appContainer.playMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/Player/Play.png";
            } else {
                appContainer.pauseMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/Player/Pause.png";
            }
            upperMenu.setOpacity(1);
            subtitleButtonContainer.setOpacity(1);
            volume.setVisible(true);
            controlsContainer.setVisible(true);
            uiControlsShowTimer.start();
            fadeInOut.play();
        }

        attachedObjects: [
            // Notification displayed to the user when broken file is opened
            SystemToast {
                id: invalidToast
                body: "Video is corrupt or invalid."
                onFinished: {
                    appContainer.goBack()
                }
            },
            // Notification displayed to the user when broken file is opened
            SystemToast {
                id: noSubToast
                body: "Subtitles aren't available for this video."
                position: SystemUiPosition.MiddleCenter
            },
            Sheet {
                id: videoSheet
                objectName: "videoSheet"
                content: Page {

                }
            },
            ImagePaintDefinition {
                id: backgroundImage
                imageSource: "asset:///images/Player/VideoBG.png"
            },
            MediaPlayer {
                id: myPlayer
                // Use the device's primary display to
                // show the video.
                videoOutput: VideoOutput.PrimaryDisplay

                // The ID of the ForeignWindow control to
                // use as the rendering surface.
                windowId: "VideoWindow"

                property int positionInMsecs: 0 //track position in msecs. Using this since player does not give position value in msecs.
                property bool valueChangedBySeek: false //keeping this flag to optimise the handling of immediateValueChanged.

                onPositionChanged: {
                    if (valueChangedBySeek) {
                        subtitleManager.seek(position);
                    } else {
                        subtitleManager.seek(position);
                        durationSlider.setValue(position);
                    }
                    mainPage.currentMoviePosition = position;
                }

                // Investigate how the metadata can be retrieved without playing the video.
                onMetaDataChanged: {
                    console.log("player onMetaDataChanged");
                    if(!infoListModel.isPlayable(infoListModel.getSelectedIndex()) && myPlayer.metaData.duration != undefined) {
                        myPlayer.stop();
                        var item = infoListModel.data(infoListModel.getSelectedIndex());
                        item.duration = myPlayer.metaData.duration;
                        item.height = myPlayer.metaData.height;
                        item.width = myPlayer.metaData.width;
                        infoListModel.updateItem(infoListModel.getSelectedIndex(), item);
                        initTimer.start();
                    }
                }

                onMediaStateChanged: {
                    if (myPlayer.mediaState == MediaState.Stopped) {
                        elapsedTimer.restart()
                    }
                }
           },

            SubtitleManager {
                id: subtitleManager
            },

            Settings {
                id: settings
            },

            System {
                id: system
            },

            BpsEventHandler {
                id: bpsEventHandler
                property bool locked: false
                onVideoWindowStateChanged: {
                    if (isMinimized && myPlayer.mediaState == MediaState.Started) {
                        // Application is minimized. Pause the video
                        appContainer.pauseMediaPlayer();
                    }
                    if (! isMinimized && myPlayer.mediaState == MediaState.Paused) {
                        // Application is maximized. Started playing the stopped video
                        appContainer.pauseMediaPlayer();
                    }
                }

                onWindowInactive: {
                    bpsEventHandler.locked = true;
                    if (myPlayer.mediaState == MediaState.Started) {
                        appContainer.pauseMediaPlayer();
                    }
                }

                onWindowActive: {
                    bpsEventHandler.locked = false;
                }

                onSpeakerVolumeChanged: {
                    appContainer.curVolume = system.getVolume();
                    volume.setVolumeIcons();
                    uiControlsShowTimer.start();
                }

                onShowVideoScrollBar: {
                    if (! videoListScrollBar.isVisible && ! appContainer.videoScrollBarIsClosing) {
                        videoListAppearAnimation.play();
                        videoListScrollBar.isVisible = true;
                        videoListScrollBar.scrollItemToMiddle(infoListModel.getSelectedIndex(), OrientationSupport.orientation == UIOrientation.Landscape);
                    } else
                        videoListDisappearAnimation.play();
                }

                onDeviceLockStateChanged: {
                    bpsEventHandler.locked = true;
                    if (myPlayer.mediaState == MediaState.Started) {
                        appContainer.pauseMediaPlayer();
                    }
                }
            },

            MediaKeyWatcher {
                id: keyWatcher
                key: MediaKey.PlayPause

                onShortPress: {
                    if (myPlayer.mediaState == MediaState.Started) {
                        appContainer.pauseMediaPlayer();
                    } else if (myPlayer.mediaState == MediaState.Paused) {
                        appContainer.playMediaPlayer();
                    } else {
                        console.log("CURRENT VIDEO PATH")
                        console.log(mycppPlayer.getVideoPath())
                        myPlayer.setSourceUrl(mycppPlayer.getVideoPath())
                        if (appContainer.playMediaPlayer() == MediaError.None) {
                            videoWindow.visible = true;
                            contentContainer.visible = true;
                            durationSlider.setEnabled(true)
                            durationSlider.resetValue()
                        }
                    }
                }
            },

            CustomElapsedTimer {
                id: elapsedTimer
                onIntervalChanged: {
                    if(interval < 1000)
                    {
                         appContainer.curVolume = system.getVolume();
                         if (appContainer.retryCount != 0) {
                             appContainer.playMediaPlayer();
                             --appContainer.retryCount;
                         } else {
                             invalidToast.show();
                         }
                    }
                    else{
                        appContainer.goBack()
                    }
                }
            },

            QTimer {
                id: uiControlsShowTimer
                singleShot: true
                interval: 3000
                onTimeout: {
                    if(HDMIScreen.connection)
                        return;
                    if (durationSlider.onSlider) {
                        uiControlsShowTimer.start();
                    } else {
                        if (upperMenu.opacity == 1.0)
                            upperMenuAnimation.play();
                        if (controlsContainer.opacity == 1.0)
                            controlsAnimation.play();
                        if (actionBarVisibility == ChromeVisibility.Overlay)
                            actionBarVisibility = ChromeVisibility.Hidden;
                        pgPlayer.updateSubtitlesPosition();
                        uiControlsShowTimer.stop();
                        if (volume.visible) 
                        	volumeAnimation.play();
                        
                    }
                }
            },

            QTimer {
                id: bookmarkTimer
                singleShot: true
                interval: 30000
                onTimeout: {
                    durationSlider.bookmarkVisible = false;
                }
            },

            QTimer {
                id: slideBarTimer
                interval: 300
                onTimeout: {
                    if(!HDMIPlayer.paused)
                        durationSlider.setValue(HDMIPlayer.position)
                }
            },

            OrientationHandler {
                onOrientationAboutToChange: {
                    videoListScrollBar.scrollItemToMiddle(infoListModel.getSelectedIndex(), OrientationSupport.orientation == UIOrientation.Portrait);
                    appContainer.setDimensionsFromOrientation(orientation);
                    if (orientation == UIOrientation.Landscape) {
                        durationSlider.bookmarkPositionX = durationSlider.timeAreaWidth + durationSlider.sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.width - 2 * durationSlider.timeAreaWidth - durationSlider.sliderHandleWidth) - 30;
                        durationSlider.progressBarPositionX = (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.width - 2 * durationSlider.timeAreaWidth - durationSlider.sliderHandleWidth);
                        upperMenu.preferredWidth = displayInfo.width;
                    } else {
                        durationSlider.bookmarkPositionX = durationSlider.sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.height - durationSlider.sliderHandleWidth) - 30
                        durationSlider.progressBarPositionX = (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.height - durationSlider.sliderHandleWidth);
                        upperMenu.preferredWidth = displayInfo.height;
                    }
                    videoWindow.initializeVideoScales();
                }
            },

            QTimer {
                id: startListenForStopped
                singleShot: true
                interval: 700
                onTimeout: {
                    startListening = true;
                }
            },

            QTimer {
                id: initTimer
                singleShot: true
                interval: 1
                onTimeout: {
                    // There is a 2nd screen connected, play over it
                    if(HDMIScreen.connection) {
                        console.log("2nd screen connected");
                        HDMIPlayer.setVideoSize(infoListModel.getWidth(), infoListModel.getHeight())
                        HDMIPlayer.play(infoListModel.getSelectedVideoPath());
                        upperMenu.setOpacity(1);
                        controlsContainer.setOpacity(1);
                        controlsContainer.setVisible(true);
                        volume.setVisible(true);
                        actionBarVisibility = ChromeVisibility.Overlay;
                        // Starting listen with delay because HDMIPlayer emiting 1 stopped at the start
                        startListenForStopped.start();
                    } else {
                        elapsedTimer.start();
                        myPlayer.setSourceUrl(infoListModel.getSelectedVideoPath());
                        myPlayer.prepare();
                        if (appContainer.playMediaPlayer() == MediaError.None) {
                            videoWindow.visible = true;
                            contentContainer.visible = true;
                            if (subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl)) {
                                pgPlayer.updateSubtitlesPosition();
                                subtitleButtonContainer.videoHasSubtitles = true;
                            }

                            appContainer.changeVideoPosition = false;
                            if (myPlayer.seekTime(0) != MediaError.None) {
                                console.log("seekTime ERROR");
                            }
                            appContainer.changeVideoPosition = true;
                        } else {
                            invalidToast.show();
                        }
                        if (durationSlider.bookmarkVisible) {
                            upperMenu.setOpacity(1);
	                        subtitleButtonContainer.setOpacity(1);
	                        controlsContainer.setOpacity(1);
	                        controlsContainer.setVisible(true);
	                        volume.setVisible(true);
	                        uiControlsShowTimer.start();
                            actionBarVisibility = ChromeVisibility.Overlay;
                        } else {
                            upperMenu.setOpacity(0);
                            subtitleButtonContainer.setOpacity(0);
                            controlsContainer.setVisible(false);
                            volume.setVisible(false);
                            actionBarVisibility = ChromeVisibility.Hidden;
                        }
                        videoWindow.initializeVideoScales();
                    }
                    if (infoListModel.getVideoPosition() > appContainer.bookmarkMinTime && infoListModel.getVideoPosition() < appContainer.bookmarkMaxTime) {
                        durationSlider.bookmarkVisible = true;
                        bookmarkTimer.start();
                    }
                    currentLenght = infoListModel.getVideoDuration();
                    infoListModel.markSelectedAsWatched();
                    if (loadingIndicator.running) {
                    	loadingIndicator.stop();
                    }
                }                
            }
        ] // Attached objects.

        onCreationCompleted: {
            if (!infoListModel.isLocal(infoListModel.getSelectedVideoPath())) {
                loadingIndicator.start();
            }
            settings.setValue("inPlayerView", true);
            Application.thumbnail.connect(onThumbnail);
            infoListModel.itemMetaDataAdded.connect(onItemMetaDataAdded);            
            startListening = false;
            initTimer.start();
        }

        function onItemMetaDataAdded() {
            if(infoListModel.isPlayable(infoListModel.getSelectedIndex()) && !isPlaying) {
                initTimer.start();
                isPlaying = true;
            }
        }

        function goBack() {
            infoListModel.setVideoPosition(durationSlider.value);
            appContainer.curVolume = system.getVolume();
            if(!HDMIScreen.connection || HDMIPlayer.stopped) {
                if(HDMIPlayer.stopped)
                    HDMIPlayer.stop();
                pgPlayer.destroy();
            }
            if(settings.value("inPlayerView"))
                navigationPane.pop();
            settings.setValue("inPlayerView", false);
            Application.setMenuEnabled(true);
        }

        function onThumbnail() {
            volume.visible = false;
            subtitleButtonContainer.setOpacity(0);
            upperMenu.setOpacity(0);
            controlsContainer.setVisible(false);
        }

    } //appContainer
    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            title: qsTr("Back") + Retranslate.onLanguageChanged
            onTriggered: {
                appContainer.goBack()
            }
        }
    }

    actions: [
        ActionItem {
            id: playPauseActionItem
            ActionBar.placement: ActionBarPlacement.OnBar
            title: qsTr("Pause") + Retranslate.onLanguageChanged
            imageSource: "asset:///images/Player/Pause_icon.png"            
            onTriggered: {
                appContainer.showPlayPauseButton();
            }
        },
        ActionItem {
            id: subtitleActionItem
            ActionBar.placement: ActionBarPlacement.OnBar
            title: qsTr("Subtitles") + Retranslate.onLanguageChanged
            imageSource: "asset:///images/Player/subt_icon_off.png"
            onTriggered: {
                if (! subtitleButtonContainer.videoHasSubtitles) {
                    noSubToast.show();
                }
                if (subtitleButtonContainer.opacity != 0) {
                    uiControlsShowTimer.start();
                    subtitleButtonContainer.subtitleEnabled = ! subtitleButtonContainer.subtitleEnabled;                    
                }
            }
        }
    ]
    function popPage() {
        settings.setValue("inPlayerView", false);
        infoListModel.setVideoPosition(durationSlider.value);
        appContainer.curVolume = system.getVolume();
        if(HDMIScreen.connection) {
            if(HDMIPlayer.stopped) {
                HDMIPlayer.stop();
                pgPlayer.destroy();
            }
        } else {
            pgPlayer.destroy();
        }
    }
}// Page