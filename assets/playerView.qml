import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0
import bpsEventHandler 1.0
import nutty.slider 1.0

Page {
    id: pgPlayer
    
    property variant currentPath: ""
    property variant currentLenght: 0

    Container {
        id: appContainer
         background: backgroundImage.imagePaint

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

        // This properties are used for dynamically defining video window size for different orientations
        property int landscapeWidth : 1280
        property int landscapeHeight : 768

        property int subtitleAreaBottomPadding : 200

        property double maxPinchPercentFactor :1.2 //120 percent
        property double minPinchPercentFactor :0.8 //80 percent

        property int touchPositionX: 0
        property int touchPositionY: 0

        property double minScreenScale: 0.5        //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0        //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScale: 1.0    // Starts the video with original dimensions (that is, scale factor 1.0)
                                                   // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
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

        Container {
            id: contentContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center

            layout: DockLayout {}

            preferredWidth:  appContainer.width
            preferredHeight: appContainer.height 

            property int startingX
            property int startingY  

           Container {
               layout: AbsoluteLayout {
                           }
           ForeignWindowControl {
                id: videoWindow
                objectName: "VideoWindow"
                windowId: "VideoWindow"

                layoutProperties: AbsoluteLayoutProperties {
                }
                property double startScale: appContainer.initialScreenScale

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
                        toX: 1.0
                        toY: 1.0
                        duration: 200
                    }
                ]
                preferredWidth:  appContainer.landscapeWidth
                preferredHeight: appContainer.landscapeHeight 

                visible:  boundToWindow
                updatedProperties:// WindowProperty.SourceSize | 
                    WindowProperty.Size |
                    WindowProperty.Position |
                    WindowProperty.Visible

                onVisibleChanged: {
                    console.log("foreignwindow visible = " + visible);
                }
                onBoundToWindowChanged: {
                    console.log("VideoWindow bound to mediaplayer!");
                }
            } //videoWindow
                onTouch: {
                    if (! appContainer.isPinchZoom) {
                        if (OrientationSupport.orientation == UIOrientation.Portrait) {
                            appContainer.heightOfScreen = appContainer.landscapeWidth;
                            appContainer.widthOfScreen = appContainer.landscapeHeight;
                            appContainer.touchDistanceAgainstMode = appContainer.landscapeHeight / 5;
                        } else {
                            appContainer.heightOfScreen = appContainer.landscapeHeight;
                            appContainer.widthOfScreen = appContainer.landscapeWidth;
                            appContainer.touchDistanceAgainstMode = appContainer.landscapeWidth / 5;
                        }
                        if (event.touchType == TouchType.Down) {
                            appContainer.previousPositionX = event.localX;
                            appContainer.previousPositionY = event.localY;
                            appContainer.touchPositionX = event.localX;
                            appContainer.touchPositionY = event.localY;
                            contentContainer.startingX = videoWindow.translationX;
                            contentContainer.startingY = videoWindow.translationY;
                            appContainer.directionIsDetect = false;
                            appContainer.volumeChange = false;
                            appContainer.volumeFullorMute = false;
                            appContainer.counterForDetectDirection = 5;
                            appContainer.offsetX = 0;
                            appContainer.offsetY = 0;

                        } else if (event.touchType == TouchType.Up && ! appContainer.volumeChange) {
                            if (Math.abs(appContainer.touchPositionX - event.localX) > appContainer.touchDistanceAgainstMode) {
                                // TODO: probably we could use the application container size
                                // to calculate the magic numbers below by the percentage

                                if (appContainer.touchPositionX >= event.localX + appContainer.touchDistanceAgainstMode) {
                                    appContainer.changeVideoPosition = true;
                                    if (durationSlider.immediateValue + (5 * 1000) < durationSlider.toValue) {
                                        appContainer.seekPlayer(durationSlider.immediateValue + 5 * 1000);
                                    } else {
                                        appContainer.seekPlayer(durationSlider.toValue);
                                        myPlayer.pause();
                                    }
                                } else if (appContainer.touchPositionX + appContainer.touchDistanceAgainstMode < event.localX) {
                                    appContainer.changeVideoPosition = true;
                                    appContainer.seekPlayer(durationSlider.immediateValue - 5 * 1000);
                                }
                                appContainer.changeVideoPosition = false;
                            }
                            if (event.localY > 180 && videoListScrollBar.isVisible && ! appContainer.videoScrollBarIsClosing) {
                                videoListDisappearAnimation.play();
                            } else {
                                upperMenu.setOpacity(1);
                                controlsContainer.setOpacity(1);
                                controlsContainer.setVisible(true);
                                uiControlsShowTimer.start();
                            }
                        } else if (event.touchType == TouchType.Move) {
                            if (! appContainer.directionIsDetect) {

                                if (appContainer.counterForDetectDirection != 0) {
                                    appContainer.offsetX += Math.abs(appContainer.previousPositionX - event.localX);
                                    appContainer.offsetY += Math.abs(appContainer.previousPositionY - event.localY);
                                    -- appContainer.counterForDetectDirection;
                                } else {
                                    if (appContainer.offsetX > appContainer.offsetY) {
                                        appContainer.directionIsDetect = true;
                                    } else {
                                        appContainer.volumeChange = true;
                                        if (appContainer.previousPositionY - event.localY > 0) {
                                            appContainer.curVolume = appContainer.curVolume + (appContainer.previousPositionY - event.localY) / 10;
                                            if (appContainer.curVolume > 100) appContainer.curVolume = 100;
                                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);

                                            volume.visible = true;
                                            if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png";
                                            else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                                            if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png";
                                            else volumeFull.imageSource = "asset:///images/Player/VolumeFull.png"; 
                                        }
                                        if (appContainer.previousPositionY - event.localY < 0) {
                                            appContainer.curVolume = appContainer.curVolume + (appContainer.previousPositionY - event.localY) / 10;
                                            if (appContainer.curVolume < 0) appContainer.curVolume = 0;
                                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);

                                            volume.visible = true;
                                            if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png";
                                            else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                                            if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png";
                                            else volumeFull.imageSource = "asset:///images/Player/VolumeFull.png"; 
                                        }
                                    }
                                }
                                appContainer.previousPositionX = event.localX;
                                appContainer.previousPositionY = event.localY;
                            }
                        }
                    }
                    if (event.touchType == TouchType.Up && appContainer.isPinchZoom) {
                        appContainer.isPinchZoom = false;
                    }
                } // onTouch

                //Subtitle area
            SubtitleArea {
                preferredWidth: videoWindow.preferredWidth
                id: subtitleAreaContainer
                layoutProperties: AbsoluteLayoutProperties {
                    id: subtitleArea
                    positionX: 0
                    positionY: videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
               }
           }

            }

            Container {
                id: volume
                layout: AbsoluteLayout {
                }
                visible: false

                property int positionY: 225
                property int indicator_length: 280
                property int indicator_count: 16
                property int indicators_length: 10
                property int indicators_space: 8

                function coord(vol) {
                    var pos = vol * (indicator_length / 100);
                    for (var i = 1; i < indicator_count; i ++) {
                        var begin = indicators_length * i + indicators_space * (i - 1);
                        var end = indicators_length * (i + 1) + indicators_space * i;
                        if (pos >= begin && pos < (end - begin) / 2 + begin) return begin;
                        if (pos <= end && pos >= (end - begin) / 2 + begin) return end;
                    }
                    return 0;
                }
                Container {
                    layout: AbsoluteLayout {
                    }

                    preferredHeight: volume.positionY + 140

                    ImageView {
                        layoutProperties: AbsoluteLayoutProperties {
                            positionX: 60
                            positionY: volume.positionY - 140
                        }
                        imageSource: "asset:///images/Player/VolumeInactive.png"
                    }
                    ImageView {
                        id: volumeActive
                        layoutProperties: AbsoluteLayoutProperties {
                            id: activeVolumeImagelayout
                            positionX: 60
                            positionY: volume.positionY + 140 - volume.coord(appContainer.curVolume)
                        }
                        implicitLayoutAnimationsEnabled: false
                        imageSource: "asset:///images/Player/VolumeActive.png"
                    }
                }
                Container {
                    layout: AbsoluteLayout {
                    }
                    ImageView {
                        id: volumeFull
                        layoutProperties: AbsoluteLayoutProperties {
                            positionX: 50
                            positionY: volume.positionY - 145 - 70
                        }
                        imageSource: "asset:///images/Player/VolumeFull.png"
                        horizontalAlignment: HorizontalAlignment.Left
                        onTouch: {
                            appContainer.volumeFullorMute = true
                            appContainer.curVolume = 100;
                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                            volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png"   
                            volumeMute.imageSource = "asset:///images/Player/VolumeMute.png"
                        }
                    }
                    ImageView {
                        id: volumeMute
                        layoutProperties: AbsoluteLayoutProperties {
                            positionX: 50
                            positionY: volume.positionY + 145
                        }
                        imageSource: "asset:///images/Player/VolumeMute.png"
                        horizontalAlignment: HorizontalAlignment.Left
                        onTouch: {
                            appContainer.volumeFullorMute = true
                            appContainer.curVolume = 0;
                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                            volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png"  
                            volumeFull.imageSource = "asset:///images/Player/VolumeFull.png"
                        }
                    }
                }
            }
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
                        videoWindow.startScale = videoWindow.scaleX;
                        appContainer.startTranslationX = videoWindow.translationX;
                        appContainer.startTranslationY = videoWindow.translationY;
                        appContainer.startPinchDistance = event.distance;
                        appContainer.startMidPointX = event.midPointX;
                        appContainer.startMidPointY = event.midPointY;
                        appContainer.isPinchZoom = true;

                    }

                    // As the pinch expands or contracts, change the scale of
                    // the image
                    onPinchUpdated: {
                        appContainer.coefficientOfZoom = event.distance / appContainer.startPinchDistance;
                        videoWindow.scaleX = videoWindow.scaleY = videoWindow.startScale * appContainer.coefficientOfZoom;
                        videoWindow.translationX = appContainer.startTranslationX // start translation 
                        + (appContainer.startTranslationX + videoWindow.preferredWidth / 2 - appContainer.startMidPointX) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointX isn't changed 
                        + (event.midPointX - appContainer.startMidPointX); // translation in time of move

                        videoWindow.translationY = appContainer.startTranslationY // start translation 
                        + (appContainer.startTranslationY + videoWindow.preferredHeight / 2 - appContainer.startMidPointY) * (appContainer.coefficientOfZoom - 1) // translation in time zoom when midPointY isn't changed
                        + (event.midPointY - appContainer.startMidPointY); // translation in time of move

                    } // onPinchUpdate
                    onPinchEnded: {
                        if (videoWindow.translationX >= (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2)) {
                            videoWindow.translationX = (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2);
                        }
                        if (videoWindow.translationX <= - ((((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2) )) {
                            videoWindow.translationX = - (((videoWindow.scaleX - 1.0) * videoWindow.preferredWidth) / 2);
                        }
                        if (videoWindow.translationY >= (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2)) {
                            videoWindow.translationY = (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2);
                        }
                        if (videoWindow.translationY <= - ((((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2) )) {
                            videoWindow.translationY = - (((videoWindow.scaleY - 1.0) * videoWindow.preferredHeight) / 2);
                        }
                        if (videoWindow.scaleX < 1) {
                            scaleAnimation.play();
                            videoWindow.translationX = 0;
                            videoWindow.translationY = 0;
                        }
                    } // onPinchEnded
                } // PinchHandler
            ] // attachedObjects
            // Play/pause image is transparent. It will become visible when the video
            // is played/paused using tap event. It will be visible 1 sec.
            ImageView {
                id: screenPlayPauseImage
                opacity: 0
                implicitLayoutAnimationsEnabled: false
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
            }

        }//contentContainer

        // Video list scroll bar for Portrait mode
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            // Video list scroll bar for Portrait mode
            VideoListScrollBar {
                id: videoListScrollBar
                horizontalAlignment: HorizontalAlignment.Center
                overlapTouchPolicy: OverlapTouchPolicy.Allow
                currentPath: pgPlayer.currentPath
                visible: false
                isVisible: false

                onVideoSelected: {
                    console.log("selected item PATH == " + item.path);

                    pgPlayer.currentPath= item.path;
                    myPlayer.setSourceUrl(item.path);

                    if (appContainer.playMediaPlayer() == MediaError.None) {
                        videoWindow.visible = true;
                        contentContainer.visible = true;
                        durationSlider.resetValue();
                        durationSlider.setEnabled(true)
                        subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl);
                        infoListModel.setSelectedIndex(infoListModel.getVideoPosition(item));
                        trackTimer.start();
                        myPlayer.play();
                        videoListDisappearAnimation.play();
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
                    id: backButtonContainer
                    objectName: backButtonContainer
                    opacity: 0.5
                    leftPadding: 10

                    horizontalAlignment: HorizontalAlignment.Left
                    verticalAlignment: VerticalAlignment.Center
                    ImageButton {
                        id: backButton
                        defaultImageSource: "asset:///images/Player/BackButton.png"

                        onClicked: {
                            if(upperMenu.opacity != 0) {
                                infoListModel.setVideoPosition(myPlayer.position);
                                appContainer.curVolume = bpsEventHandler.getVolume();
                                navigationPane.pop();
                                pgPlayer.destroy();
                            }
                        }
                    }
                } //backButtonContainer
                Container {
                    id: videoTitleContainer
                    background: backgroundPaint.imagePaint
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    maxWidth: upperMenu.preferredWidth - 400
                    opacity: 1
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

                        ImageButton {
                            id: hdmiButton
                            defaultImageSource: "asset:///images/Player/HDMIButtonInactive.png"

                            onClicked: {
                                if (upperMenu.opacity != 0) hdmiButtonContainer.hdmiEnabled = ! hdmiButtonContainer.hdmiEnabled;
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
                    Container {
                        id: subtitleButtonContainer
                        objectName: subtitleButtonContainer
                        opacity: 0.5
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Right
                        rightPadding: 15
                        topPadding: 20
                        property bool subtitleEnabled

                        ImageButton {
                            id: subtitleButton
                            defaultImageSource: "asset:///images/Player/SubtitleButton.png"
                            onClicked: {
                                if (upperMenu.opacity != 0) {
                                    subtitleButtonContainer.subtitleEnabled = ! subtitleButtonContainer.subtitleEnabled;
                                    settings.setValue("subtitleEnabled", subtitleButtonContainer.subtitleEnabled);
                                }
                            }
                        }
                        onCreationCompleted: {
                            subtitleEnabled = settings.value("subtitleEnabled");
                            if (subtitleEnabled) {
                                subtitleAreaContainer.setOpacity(1);
                                subtitleButton.setDefaultImageSource("asset:///images/Player/SubtitleButton.png");
                            } else {
                                subtitleAreaContainer.setOpacity(0);
                                subtitleButton.setDefaultImageSource("asset:///images/Player/SubtitleButtonInactive.png");
                            }
                        }
                        onSubtitleEnabledChanged: {
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
                implicitLayoutAnimationsEnabled: false
                
                attachedObjects: [
                    LayoutUpdateHandler {
                        id:upperMenuLayout
                    }
                ]
            }

            onCreationCompleted: {
                if (OrientationSupport.orientation == UIOrientation.Landscape) upperMenu.preferredWidth = appContainer.landscapeWidth;
                else upperMenu.preferredWidth = appContainer.landscapeHeight
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
                upperMenu.setOpacity(1);
                uiControlsShowTimer.start();
            }
        }

        Container {
            id: controlsContainer
            opacity: 0
            visible: true
            enabled: true
            layout: StackLayout {
                orientation: LayoutOrientation.TopToBottom
            }
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom

            Container {
                id: bookmark
                layout: AbsoluteLayout {
                }
                //bookmark Icone
                ImageView {
                    implicitLayoutAnimationsEnabled: false
                    id: bookmarkIcon
                    layoutProperties: AbsoluteLayoutProperties {
                        positionX: OrientationSupport.orientation == UIOrientation.Landscape 
                        ? 220 + infoListModel.getVideoPosition() * ((appContainer.landscapeWidth - 505) / pgPlayer.currentLenght) + 5 
                        : 220 + infoListModel.getVideoPosition() * ((appContainer.landscapeHeight - 505) / pgPlayer.currentLenght) + 5

                    }
                    imageSource: "asset:///images/Player/BookmarkIcon.png"
                    visible: true

                    
                    onTouch: {
                        myPlayer.seekTime(infoListModel.getVideoPosition());
                        durationSlider.immediateValue= infoListModel.getVideoPosition();
                        bookmarkIcon.visible= false;
                        bookmarkTimer.stop();
                    }

                } //bookmark Icon
            } //bookmark

            Container {
                id: sliderContainer
                objectName: sliderContainer
                
                layout: StackLayout {
                    orientation: LayoutOrientation.LeftToRight
                }
                
                leftPadding: 5
                rightPadding: 5
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Bottom

                SlideBar {
                    id: durationSlider
                    leftMargin: 5
                    rightMargin: 5
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center

                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    onImmediateValueChanged: {
                        //console.log("onImmediateValueChanged");
                        if(myPlayer.mediaState == MediaState.Started ||
                            myPlayer.mediaState == MediaState.Paused) {
                            if(appContainer.changeVideoPosition == true && immediateValue != value) {
                                myPlayer.seekTime(durationSlider.immediateValue);
                                myPlayer.valueChangedBySeek = true;
                                appContainer.changeVideoPosition = false;
                            }
                        }
                    }
                    onTouch: {
                        uiControlsShowTimer.start();
                    }
                } //durationSlider
            }//sliderContainer
        }//controlsContainer

        function playMediaPlayer() {
            trackTimer.start();
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
                myPlayer.seekTime(durationSlider.immediateValue);
                appContainer.playMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/play.png"
            } else {
                appContainer.pauseMediaPlayer();
                screenPlayPauseImage.imageSource = "asset:///images/pause.png"
            }
            screenPlayPauseImage.setOpacity(0.5);
            screenPlayPauseImageTimer.start();
        }

        attachedObjects: [
            Sheet {
                id: videoSheet
                objectName: "videoSheet"
                content:Page {

                }
            },
            ImagePaintDefinition {
                id: backgroundImage
                imageSource: "asset:///images/bg.png"
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
                   durationSlider.value = position;
                   //Set correct subtitle positon
                   if (valueChangedBySeek) {
                       myPlayer.positionInMsecs = myPlayer.position;
                       subtitleManager.seek(myPlayer.positionInMsecs);
                       valueChangedBySeek = false;
                   }
               }
               onDurationChanged: {
                   durationSlider.toValue = duration;
                   // If the duration is changes, it means the video to play is changes.
                   // So update the video title on the UI as well
                   videoTitle.text = infoListModel.getVideoTitle();
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

           BpsEventHandler {
               id: bpsEventHandler
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
               
                onSpeakerVolumeChanged: {
                    volume.visible = true;
                    appContainer.curVolume = bpsEventHandler.getVolume();
                    if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/Player/VolumeMuteActive.png";
                    else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                    if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/Player/VolumeFullActive.png";
                    else volumeFull.imageSource = "asset:///images/Player/VolumeFull.png";  
                }

                onShowVideoScrollBar: {
                   if(!videoListScrollBar.visible)
                      videoListScrollBar.visible = true;
                      
                    if(!videoListScrollBar.isVisible && !appContainer.videoScrollBarIsClosing){
                         videoListAppearAnimation.play();
                         videoListScrollBar.isVisible = true;
                    }
                    else
                         videoListDisappearAnimation.play(); 
               }
               
                onDeviceLockStateChanged: {
               	  	if (isLocked && myPlayer.mediaState == MediaState.Started) {
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
                               trackTimer.start();
                            }
                        }
                     }
            },

           QTimer {
               id: trackTimer
               singleShot: false
               property int videoCurrentPos:0 //to track position changes on media player.
               interval: 5
               onTimeout: {
                   if(myPlayer.mediaState == MediaState.Started) {
                       appContainer.changeVideoPosition = false;
                       myPlayer.positionInMsecs += 5;
                       //Sync every time when myPlayer.position changed: i.e. one time per second
                       if(videoCurrentPos != myPlayer.position) {
                           videoCurrentPos = myPlayer.position;
                           myPlayer.positionInMsecs = myPlayer.position;
                       }
                       //Duration is 0 for first several time outs.
                       //TODO: Figure out that, though seems it is a MediaPlayer issue.
                       //'if' is used as workaround
                       if (myPlayer.duration && myPlayer.positionInMsecs <= myPlayer.duration) {
                           durationSlider.setValue(myPlayer.positionInMsecs)
                       }
                       appContainer.changeVideoPosition = true;
                       subtitleManager.handlePositionChanged(myPlayer.positionInMsecs);
                   }
                   else if(myPlayer.mediaState == MediaState.Stopped) {
                       appContainer.changeVideoPosition = false;
                       durationSlider.setValue(durationSlider.toValue)
                       appContainer.changeVideoPosition = true;
                       trackTimer.stop();
                   }
               }
           },

           QTimer {
               id: screenPlayPauseImageTimer
               singleShot: true
               interval: 1000
               onTimeout: {
                   screenPlayPauseImage.setOpacity(0)
                   screenPlayPauseImageTimer.stop()
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
                   upperMenu.setOpacity(0);
                   controlsContainer.setOpacity(0);
                   controlsContainer.setVisible(false);
                   uiControlsShowTimer.stop();
                   volume.visible = false;
                   }
               }
           },

            QTimer {
                id: bookmarkTimer
                singleShot: true
                interval: 7000
                onTimeout: {
                    bookmarkIcon.visible= false;
                }
            },

            OrientationHandler {
               onOrientationAboutToChange: {
                   if (orientation == UIOrientation.Landscape) {
                       volume.positionY = 384;
                       upperMenu.preferredWidth = appContainer.landscapeWidth
                       videoWindow.preferredWidth = appContainer.landscapeWidth
                       videoWindow.preferredHeight = appContainer.landscapeHeight
                       subtitleArea.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
                    } else {
                       volume.positionY = 225;
                       upperMenu.preferredWidth = appContainer.landscapeHeight
                       videoWindow.preferredWidth = appContainer.landscapeHeight
                       videoWindow.preferredHeight = (appContainer.landscapeHeight * appContainer.landscapeHeight) / appContainer.landscapeWidth
                       subtitleArea.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;                       
                    }
               }
           }

        ] // Attached objects.

        onCreationCompleted: {
            OrientationSupport.supportedDisplayOrientation =
                SupportedDisplayOrientation.All;
            // centre the videosurface
            videoWindow.translationY = 0;
            videoWindow.translationX = 0;
            if (OrientationSupport.orientation == UIOrientation.Landscape) {
                videoWindow.preferredWidth = appContainer.landscapeWidth
                videoWindow.preferredHeight = appContainer.landscapeHeight

            } else {
                videoWindow.preferredWidth = appContainer.landscapeHeight
                videoWindow.preferredHeight = (appContainer.landscapeHeight * appContainer.landscapeHeight) / appContainer.landscapeWidth
            }

            myPlayer.setSourceUrl(infoListModel.getSelectedVideoPath());
            myPlayer.prepare();
            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
            if (appContainer.playMediaPlayer() == MediaError.None) {

                var videoPos = 0;
                bookmarkTimer.start();
                
                if(!bookmarkIcon.visible) 
                	bookmarkIcon.visible= true;
                	
                if(infoListModel.getVideoPosition()==0) 
                {
                	bookmarkIcon.visible = false;
                	bookmarkTimer.stop();
                }

                videoWindow.visible = true;
                contentContainer.visible = true;
                subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl);
                appContainer.changeVideoPosition = false;
                if(myPlayer.seekTime(videoPos) != MediaError.None) {
                    console.log("seekTime ERROR");
                }
                appContainer.changeVideoPosition = true;
                trackTimer.start();
            }
            upperMenu.setOpacity(1);
            controlsContainer.setOpacity(1);
            controlsContainer.setVisible(true);
            uiControlsShowTimer.start();
        }
    }//appContainer
}// Page