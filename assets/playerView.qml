import bb.cascades 1.0
import bb.multimedia 1.0
import bb.system 1.0
import nuttyPlayer 1.0
import bpsEventHandler 1.0
import nutty.slider 1.0
import "helpers.js" as Helpers

Page {
    id: pgPlayer
    
    property variant currentPath: ""
    property variant currentLenght: 0

    Container {
        id: appContainer
         background: backgroundImage.imagePaint
         implicitLayoutAnimationsEnabled: false

        layout: DockLayout {
        }
        
        property int counterForDetectDirection : 5
        property int previousPositionX : 0
        property int previousPositionY: 0
        property int offsetX : 0
        property int offsetY : 0
        property bool directionIsDetect : false
        property bool volumeChange : false
        property bool volumeFullorMute : false

        property int heightOfScreen 
        property int widthOfScreen
        //This variable is used to control video duration logic. 
        //Indicates whether to change the video position, when the slider's value is changed.
        property bool changeVideoPosition : false

        property int startHeight
        property int startWidth
        property int videoWidth
        property int videoHeight

        property int subtitleAreaBottomPadding : 200

        property double maxPinchPercentFactor :1.2 //120 percent
        property double minPinchPercentFactor :0.8 //80 percent

        property int touchPositionX: 0
        property int touchPositionY: 0

        property double minScreenScale: 0.5        //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0        //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScaleX: 1.0    // Starts the video with original dimensions (that is, scale factor 1.0)
        property double initialScreenScaleY: 1.0 // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
                                                   // They both start with the same value but the "initialScale" value is different for every new pinch
        property double startPinchDistance: 0.0
        property double startTranslationX: 0.0
        property double startTranslationY: 0.0
        property double startMidPointX: 0.0
        property double startMidPointY: 0.0
        property double coefficientOfZoom: 0
        property bool isPinchZoom

        property double curVolume: bpsEventHandler.getVolume();    // system speaker volume current value

//        property bool videoTitleVisible : false
        property int touchDistanceAgainstMode: 0;    // This is used to have 2 different distances between the point tounched
                                                     // and the point released. This is needed for differentiation of 
                                                     // gestures handling for "zoom out" and "seek 5 seconds" 
        property bool videoScrollBarIsClosing : false;    // If the video Scroll bar is in closing process
        property int bookmarkMinTime : 60000
        
        function setDimensionsFromOrientation(pOrientation)
        {
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

            layout: DockLayout {}

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
                //background: Color.Red
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

                gestureHandlers: [
                ]
                animations: [
                    ScaleTransition {
                        id: scaleAnimation
                        toX: appContainer.initialScreenScaleX
                        toY: appContainer.initialScreenScaleY
                        duration: 200
                    }
                ]
 

                visible:  boundToWindow
                updatedProperties:// WindowProperty.SourceSize | 
                    WindowProperty.Size |
                    WindowProperty.Position |
                    WindowProperty.Visible


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
                    console.log("maxHeight ==" + maxHeight)
                }
                onBoundToWindowChanged: {
                    console.log("VideoWindow bound to mediaplayer!");
                }
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
                        if (event.windowY < appContainer.heightOfScreen - Helpers.heightOfSlider) {
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
                                        myPlayer.seekTime(durationSlider.value + Helpers.seekTimeInSlide);
                                    } else {
                                        myPlayer.seekTime(durationSlider.toValue);
                                    }
                                } else if (appContainer.touchPositionX + appContainer.touchDistanceAgainstMode < event.windowX) {
                                    appContainer.changeVideoPosition = true;
                                    myPlayer.seekTime(Math.max(durationSlider.value - Helpers.seekTimeInSlide,0));
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
                                        if (Math.abs(deltaPosition) < 70) 
                                        {
                                            // min and max to bound value between 0 and 100
                                            appContainer.curVolume = Math.min(Math.max(appContainer.curVolume + deltaPosition / 9, 0),100);
                                        }
                                        bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                                        volume.setMuteIcons();
                                        volume.setVisible(true);
                                        uiControlsShowTimer.start();
                                    }
                                }
                                appContainer.previousPositionX = event.windowX;
                                appContainer.previousPositionY = event.windowY;
                            }
                        }
                        } else {
                            if(event.touchType == TouchType.Up && !controlsContainer.visible)
                            {
                                subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - durationSlider.slideBarHeight;
                                subtitleButtonContainer.setOpacity(1);
                            	controlsContainer.setVisible(true);
                                uiControlsShowTimer.start();
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
                            if (event.y < appContainer.heightOfScreen - durationSlider.height) {
                                appContainer.showPlayPauseButton();
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
                            videoWindow.translationX = appContainer.startTranslationX // start translation 
                            						+ (appContainer.startTranslationX + videoWindow.preferredWidth / 2 - appContainer.startMidPointX) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointX isn't changed 
                            						+ (event.midPointX - appContainer.startMidPointX); // translation in time of move

                            videoWindow.translationY = appContainer.startTranslationY // start translation 
                            						+ (appContainer.startTranslationY + videoWindow.preferredHeight / 2 - appContainer.startMidPointY) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointY isn't changed
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
                    signal initializeStates
                        touchBehaviors: [
                            TouchBehavior {
                                TouchReaction {
                                    eventType: TouchType.Down
                                    phase: PropagationPhase.Capturing
                                    response: TouchResponse.StartTracking
                                }
                            },
                            TouchBehavior {
                                TouchReaction {
                                    eventType: TouchType.Down
                                    phase: PropagationPhase.AtTarget
                                    response: TouchResponse.StartTracking
                                }
                            }
                        ]
                        onTouchCapture: {
                            foreignWindowControlContainer.touch(event)
                        }
                        onTouch: {
                            foreignWindowControlContainer.touch(event)
                            if(event.touchType == TouchType.Up)
                            {
                                // no subtitle file was found
                                if (!subtitleButton.enabled)
                                {
                                    noSubToast.show();
                                }
                                if (subtitleButtonContainer.opacity != 0) {
                                    uiControlsShowTimer.start();
                                    subtitleButtonContainer.subtitleEnabled = ! subtitleButtonContainer.subtitleEnabled;
                                    settings.setValue("subtitleEnabled", subtitleButtonContainer.subtitleEnabled);
                                }
                            }
                    }
                    ImageButton {
                        id: subtitleButton
                        disabledImageSource: "asset:///images/Player/SubtitleButtonDisabled.png"
                        pressedImageSource: "asset:///images/Player/SubtitleButtonPressed.png"
                        defaultImageSource: "asset:///images/Player/SubtitleButton.png"
                    }
                    onCreationCompleted: {
                        subtitleButton.setEnabled(false);
                        initializeStates();
                    }
                    onSubtitleEnabledChanged: {
                            subtitleButtonContainer.showSubButton();
                        }

                    onInitializeStates: {
                       		subtitleEnabled = settings.value("subtitleEnabled");
                            subtitleButtonContainer.showSubButton();
                        }

                    function showSubButton() {
                        if (subtitleEnabled) {
                            subtitleAreaContainer.setOpacity(1);
                            subtitleButton.setDefaultImageSource("asset:///images/Player/SubtitleButton.png");
                        } else {
                            subtitleAreaContainer.setOpacity(0);
                            subtitleButton.setDefaultImageSource("asset:///images/Player/SubtitleButtonInactive.png");
                        }
                    }
                } //subtitleButtonContainer
            }

            }

            Container {
                id: volume
                layout: StackLayout {
                    orientation:  LayoutOrientation.TopToBottom
                }
                leftPadding: 50
                verticalAlignment: VerticalAlignment.Center //orientationHandler.orientation == UIOrientation.Portrait ? VerticalAlignment.Center : VerticalAlignment.Center
                visible: false
                preferredHeight: 2*volumeFuleAndMuteHeight + indicator_length
                property int volumeFuleAndMuteHeight: 70
                property int indicator_length: 284
                property int indicator_count: 16
                property int indicators_length: 10
                property int indicators_space: 8
                property int currentActiveIndicatorsCount : ((1 - appContainer.curVolume / 100) * volume.indicator_count)
                
                // this function changes the icons on the volume bar when the volume reaches its extremes
                function setMuteIcons()
                {	
                    if (volumeActive.layoutProperties.positionY == indicator_count*(indicators_length + indicators_space)) volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png";
                    else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                    if (volumeActive.layoutProperties.positionY == 0) volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png";
                    else volumeFull.imageSource = "asset:///images/Player/VolumeFull.png";
                }

                ImageView {
                    id: volumeFull
                    imageSource: "asset:///images/Player/VolumeFull.png"
                    onTouch: {
                        appContainer.volumeFullorMute = true
                        appContainer.curVolume = 100;
                        bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                        volume.setMuteIcons();
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
                        onTouch: 
                        {
                            if ( event.localY > 0 && event.localY < volume.indicator_length) 
                            {
                                appContainer.curVolume = (1 - event.localY / volume.indicator_length) * 100;
                                bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                                volume.setMuteIcons();
                            } 
                        }
                        touchBehaviors: [
                            TouchBehavior {
                                TouchReaction {
                                    eventType: TouchType.Down
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
                            positionY: volume.currentActiveIndicatorsCount *(volume.indicators_length + volume.indicators_space)
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
                    onTouch: {
                        appContainer.volumeFullorMute = true
                        appContainer.curVolume = 0;
                        bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                        volume.setMuteIcons();
                    }
                }
            } // volume container
         
            ImageView {
                id: screenPlayPauseImage
                implicitLayoutAnimationsEnabled: false
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
                animations: [ 
                    SequentialAnimation {
                        id : fadeInOut
                      FadeTransition {
                          toOpacity: 0.8
                          fromOpacity: 0.0
                          duration: 800
                          easingCurve: StockCurve.SineOut
                        }  
                    
                      FadeTransition {
                          toOpacity: 0.0
                          fromOpacity: 0.8
                          duration: 1500
                          easingCurve: StockCurve.QuarticOut
                     }
                }
                ]
            }
        }//contentContainer

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
                    if(durationSlider.bookmarkVisible)
                    {
                        durationSlider.bookmarkVisible = false;
                        bookmarkTimer.stop();
                    }
                    infoListModel.setVideoPosition(myPlayer.position);
                    pgPlayer.currentPath = item.path;
                    myPlayer.setSourceUrl(item.path);
                    pgPlayer.currentLenght = item.duration;

                    if (appContainer.playMediaPlayer() == MediaError.None) {
                        videoWindow.visible = true;
                        contentContainer.visible = true;
                        durationSlider.toValue = item.duration;
                        videoTitle.text = item.title;
                        durationSlider.resetValue();
                        durationSlider.setEnabled(true)
                        if(subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl))
                        {
                            subtitleButton.setEnabled(true);
                            subtitleButtonContainer.initializeStates();
                        }
                        else
                        {
                            subtitleButton.setEnabled(false);
                            subtitleAreaContainer.setOpacity(0);
                        }
                        infoListModel.setSelectedIndex(infoListModel.getVideoPosition(item.path));
                        if (infoListModel.getVideoPosition() > appContainer.bookmarkMinTime) {
                            durationSlider.bookmarkPositionX = durationSlider.getBookmarkPosition();
                            durationSlider.bookmarkVisible = true;
                            bookmarkTimer.start();
                        }
                        upperMenu.setOpacity(1);
                        controlsContainer.setOpacity(1);
                        subtitleButtonContainer.setOpacity(1);
                        controlsContainer.setVisible(true);
                        subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - durationSlider.slideBarHeight;
                        uiControlsShowTimer.start();

                        videoWindow.initializeVideoScales();
                        myPlayer.play();
                        videoListDisappearAnimation.play();
                    } else {
                        invalidToast.show();
                    }
                }
                attachedObjects: [
                    LayoutUpdateHandler {
                        id: videoListScrollLayout
                    }
                ]
            }// videoListScrollBar


            Container {
                id: upperMenu
                layout: DockLayout {}
                preferredWidth: 768

                Container {
                    layout: DockLayout {}
                    id: backButtonContainer
                    objectName: backButtonContainer
                    opacity: 0.5
                    leftPadding: 10
                    topPadding: 10

                    horizontalAlignment: HorizontalAlignment.Left
                    verticalAlignment: VerticalAlignment.Center
                    ImageButton {
                        pressedImageSource: "asset:///images/Player/back_button_press.png"
                        defaultImageSource: "asset:///images/Player/back_button_normal.png"
                        onClicked: {
                            backButtonContainer.goBack();
                        }
                    }
                    function goBack() {
                        settings.setValue("inPlayerView", false);
                        infoListModel.setVideoPosition(myPlayer.position);
                        appContainer.curVolume = bpsEventHandler.getVolume();
                        pgPlayer.destroy();
                        myPlayer.stop();
                    }
                } //backButtonContainer
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
                    // This part of code is commented our for now in case we need it in the feature
                    //                animations: [
                    //                    TranslateTransition {
                    //                        id: titleAppearAnimation
                    //                        duration: 800
                    //                        easingCurve: StockCurve.CubicOut
                    //                        fromY: -50
                    //                        toY: 0
                    //                        onEnded: {
                    //                            if (myPlayer.mediaState == MediaState.Paused) {
                    //                                appContainer.videoTitleVisible = true;
                    //                            } else {
                    //                                titleDisappearOpacityAnimation.play()
                    //                                titleDisappearAnimation.play()
                    //                            }
                    //                        }
                    //                    },
                    //                    TranslateTransition {
                    //                        id: titleDisappearAnimation
                    //                        duration: 800
                    //                        delay: 4000
                    //                        easingCurve: StockCurve.CubicOut
                    //                        toY: -50
                    //                    },
                    //                    FadeTransition {
                    //                        id: titleDisappearOpacityAnimation
                    //                        duration: 800
                    //                        delay: 4000
                    //                        easingCurve: StockCurve.CubicOut
                    //                        toOpacity: 0.0
                    //                    },
                    //                    FadeTransition {
                    //                        id: titleAppearOpacityAnimation
                    //                        duration: 800
                    //                        easingCurve: StockCurve.CubicOut
                    //                        toOpacity: 1.0
                    //                    }
                    //                ]
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
                Container {
                    layout: StackLayout {
                        orientation: LayoutOrientation.TopToBottom
                    }
                    horizontalAlignment: HorizontalAlignment.Right
                    verticalAlignment: VerticalAlignment.Center
                    Container {
                        id: hdmiButtonContainer
                        objectName: hdmiButtonContainer
                        opacity: 0.5
                        verticalAlignment: VerticalAlignment.Center
                        rightPadding: 10
                        topPadding: 10
                        property bool hdmiEnabled: false
                        visible: false
                        enabled: HDMIScreen.connection

                        ImageButton {
                            id: hdmiButton
                            pressedImageSource: "asset:///images/Player/HDMIButtonPressed.png"
                            disabledImageSource: "asset:///images/Player/HDMIButtonDisabled.png"
                            defaultImageSource: "asset:///images/Player/HDMIButtonInactive.png"

                            onClicked: {
                                if (upperMenu.opacity != 0) 
                                    hdmiButtonContainer.hdmiEnabled = ! hdmiButtonContainer.hdmiEnabled;
                            }
                        }
                        onCreationCompleted: {
                            if (hdmiEnabled) {
                                hdmiButton.setDefaultImageSource("asset:///images/Player/HDMIButton.png");
                            } else {
                                hdmiButton.setDefaultImageSource("asset:///images/Player/HDMIButtonInactive.png");
                            }
                        }
                        onHdmiEnabledChanged: {
                            if (hdmiEnabled) {
                                hdmiButton.setDefaultImageSource("asset:///images/Player/HDMIButton.png");
                            } else {
                                hdmiButton.setDefaultImageSource("asset:///images/Player/HDMIButtonInactive.png");
                            }
                        }
                    } //hdmiButtonContainer
                }
                implicitLayoutAnimationsEnabled: false
                
                attachedObjects: [
                    LayoutUpdateHandler {
                        id:upperMenuLayout
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
                    duration: 800
                    easingCurve: StockCurve.CubicOut
                    fromY: - videoListScrollLayout.layoutFrame.height
                    toY: 0
                },
                TranslateTransition {
                    id: videoListDisappearAnimation
                    duration: 600
                    easingCurve: StockCurve.ExponentialIn
                    fromY: 0 
                    toY:  - videoListScrollLayout.layoutFrame.height
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
                if(upperMenu.opacity == 0 && event.localY < 100 && event.localX < 104)
                    backButtonContainer.goBack();
                upperMenu.setOpacity(1);
                uiControlsShowTimer.start();
            }
        }

        Container {
            id: controlsContainer
            //opacity: 0
            visible: true
            enabled: true
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom

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
                    bookmarkVisible: false
                    toValue: pgPlayer.currentLenght
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    onImmediateValueChanged: {
                        if(myPlayer.mediaState == MediaState.Started ||
                            myPlayer.mediaState == MediaState.Paused) {
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
                        if(! durationSlider.pauseHandle)
                        {
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
                    onSlideBarHeightChanged: {
                        if(controlsContainer.visible == true)
                        subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - durationSlider.slideBarHeight;
                    }

                    function getBookmarkPosition() {
                        return OrientationSupport.orientation == UIOrientation.Landscape 
                        			? timeAreaWidth + sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.width - 2 * timeAreaWidth - sliderHandleWidth) - 30 
                        			: sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.height - sliderHandleWidth) - 30

                    }

                } //durationSlider
            }//sliderContainer
        }//controlsContainer

        function playMediaPlayer() {
            if(bpsEventHandler.locked)
                return; // Video does not play if phone is locked

            return myPlayer.play();
        }

        function pauseMediaPlayer() {
            return myPlayer.pause();
        }
        function seekPlayer(time) {
            myPlayer.seekTime(time);
            myPlayer.valueChangedBySeek = true;
            appContainer.changeVideoPosition = false;
        }

        function showPlayPauseButton() {
            if(myPlayer.mediaState != MediaState.Started) {
                appContainer.playMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/Player/Play.png"
            } else {
                appContainer.pauseMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/Player/Pause.png"
            }
            upperMenu.setOpacity(1);
            subtitleButtonContainer.setOpacity(1);
            controlsContainer.setVisible(true);
            subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - durationSlider.slideBarHeight;
            uiControlsShowTimer.start();
            fadeInOut.play();
        }

        attachedObjects: [
            // Notification displayed to the user when broken file is opened
            SystemToast {
                id: invalidToast
                body: "Video is corrupt or invalid."
                onFinished: {
                    backButtonContainer.goBack();
                }
            },
            // Notification displayed to the user when broken file is opened
            SystemToast {
                id: noSubToast
                body: "Subtitles aren't available for this video."
                position: SystemUiPosition.BottomCenter
            },
            Sheet {
                id: videoSheet
                objectName: "videoSheet"
                content:Page {

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
               property bool valueChangedBySeek:false //keeping this flag to optimise the handling of immediateValueChanged. 

               onPositionChanged: {
                   if (valueChangedBySeek) {
                       subtitleManager.seek(position);
                   }
                   else{
                        subtitleManager.seek(position);
                        durationSlider.setValue(position);
                        }
                   mainPage.currentMoviePosition = position;
                }

               // Investigate how the metadata can be retrieved without playing the video.
               onMetaDataChanged: {
                    console.log("player onMetaDataChanged");
                    console.log("--------------------------------bit_rate=" + myPlayer.metaData.bit_rate);
                    console.log("-----------------------------------genre=" + myPlayer.metaData.genre);
                    console.log("-----------------------------sample_rate=" + myPlayer.metaData.sample_rate);
                    console.log("-----------------------------------title=" + myPlayer.metaData.title);
                }

               onMediaStateChanged: {
                   if(myPlayer.mediaState == MediaState.Stopped) {
                       appContainer.curVolume = bpsEventHandler.getVolume();
                       navigationPane.pop();
                       pgPlayer.destroy();
                   }
               }
           },

           SubtitleManager {
               id: subtitleManager;
           },

           Settings {
               id: settings;
           },

           Screenshot {
               id: screenshot
           },

           BpsEventHandler {
               id: bpsEventHandler
               property bool locked: false
               onVideoWindowStateChanged: {
                   if(isMinimized && myPlayer.mediaState == MediaState.Started) {
                       // Application is minimized. Pause the video
                       appContainer.pauseMediaPlayer();
                   }
                   if(!isMinimized && myPlayer.mediaState == MediaState.Paused) {
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
                    appContainer.curVolume = bpsEventHandler.getVolume();
                    volume.setMuteIcons();
                    uiControlsShowTimer.start();
                }

                onShowVideoScrollBar: {
                    if(!videoListScrollBar.isVisible && !appContainer.videoScrollBarIsClosing){
                         videoListAppearAnimation.play();
                         videoListScrollBar.isVisible = true;
                         videoListScrollBar.scrollItemToMiddle(infoListModel.getIntIndex(infoListModel.getSelectedIndex()), OrientationSupport.orientation == UIOrientation.Landscape, infoListModel.size());
                    }
                    else
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
                   if(myPlayer.mediaState == MediaState.Started) {
                       appContainer.pauseMediaPlayer();
                   }
                   else if(myPlayer.mediaState == MediaState.Paused) {
                       appContainer.playMediaPlayer();
                       }
                       else {
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


           QTimer {
               id: uiControlsShowTimer
               singleShot: true
               interval: 3000
               onTimeout: {
                   if(durationSlider.onSlider) {
                       uiControlsShowTimer.start();
                   } else {
                   subtitleButtonContainer.setOpacity(0);
                   upperMenu.setOpacity(0);
                   controlsContainer.setVisible(false);
                   subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - Helpers.distanceFromSubtitleToBottomOfScreen;
                   uiControlsShowTimer.stop();
                   volume.visible = false;
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

           OrientationHandler {
               onOrientationAboutToChange: {
                    videoListScrollBar.scrollItemToMiddle(infoListModel.getIntIndex(infoListModel.getSelectedIndex()), OrientationSupport.orientation == UIOrientation.Portrait, infoListModel.size());
                    appContainer.setDimensionsFromOrientation(orientation);
                    if (orientation == UIOrientation.Landscape) {
                        durationSlider.bookmarkPositionX = durationSlider.timeAreaWidth + durationSlider.sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.width - 2 * durationSlider.timeAreaWidth - durationSlider.sliderHandleWidth) - 30
                        upperMenu.preferredWidth = displayInfo.width
                    }  else {
                        durationSlider.bookmarkPositionX = durationSlider.sliderHandleWidth / 2 + (infoListModel.getVideoPosition() / pgPlayer.currentLenght) * (displayInfo.height - durationSlider.sliderHandleWidth) - 30
                        upperMenu.preferredWidth = displayInfo.height
                    }
                    	videoWindow.initializeVideoScales();
                    if (controlsContainer.visible == false)
                    {
                        subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
                    }
                }
           },

            QTimer {
                id: initTimer
                singleShot: true
                interval: 1
                onTimeout: {
                    myPlayer.setSourceUrl(infoListModel.getSelectedVideoPath());
                    myPlayer.prepare();
                    if (appContainer.playMediaPlayer() == MediaError.None) {

                        var videoPos = 0;
                        if(infoListModel.getVideoPosition() > appContainer.bookmarkMinTime)
                        {
                            durationSlider.bookmarkVisible = true;
                            bookmarkTimer.start();
                        }

                        videoWindow.visible = true;
                        contentContainer.visible = true;
                        if(subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl))
                            subtitleButton.setEnabled(true);

                        appContainer.changeVideoPosition = false;
                        if(myPlayer.seekTime(videoPos) != MediaError.None) {
                            console.log("seekTime ERROR");
                        }
                        appContainer.changeVideoPosition = true;
                    }
                    else
                    {
                        invalidToast.show();
                    }
                    upperMenu.setOpacity(1);
                    subtitleButtonContainer.setOpacity(1);
                    subtitleContainer.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding - durationSlider.slideBarHeight;
                    controlsContainer.setOpacity(1);
                    controlsContainer.setVisible(true);
                    volume.setVisible(true);
                    uiControlsShowTimer.start();
                }
            }
       ] // Attached objects.

        onCreationCompleted: {
            settings.setValue("inPlayerView", true);
            Application.thumbnail.connect(onThumbnail);
            initTimer.start();
        }

        function onThumbnail() {
            volume.visible = false;
            subtitleButtonContainer.setOpacity(0);
            upperMenu.setOpacity(0);
            controlsContainer.setVisible(false);
            screenshot.makeScreenShot();
        }

    }//appContainer
}// Page