import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0
import bpsEventHandler 1.0
import nutty.slider 1.0

Page {
    id: pgPlayer
    
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

        property int heightOfScreen : 0
            
        //This variable is used to control video duration logic. 
        //Indicates whether to change the video position, when the slider's value is changed.
        property bool changeVideoPosition : false

        // This properties are used for dynamically defining video window size for different orientations
        property int landscapeWidth : 1280
        property int landscapeHeight : 768

        property int subtitleAreaBottomPadding : 150

        property double maxPinchPercentFactor :1.2 //120 percent
        property double minPinchPercentFactor :0.8 //80 percent

        property int touchPositionX: 0
        property int touchPositionY: 0

        property double minScreenScale: 0.5        //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0        //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScale: 1.0    // Starts the video with original dimensions (that is, scale factor 1.0)
                                                   // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
                                                   // They both start with the same value but the "initialScale" value is different for every new pinch 
        property double currentTranslation;
        property double startPinchDistance:0.0;
        property double endPinchDistance:0.0;

        property double startMidPointXPinch:0.0;
        property double endMidPointXPinch:0.0;

        property double curVolume: bpsEventHandler.getVolume();    // system speaker volume current value

//        property bool videoTitleVisible : false
        property int touchDistanceAgainstMode: 0;    // This is used to have 2 different distances between the point tounched
                                                     // and the point released. This is needed for differentiation of 
                                                     // gestures handling for "zoom out" and "seek 5 seconds" 
        property bool videoScrollBarIsClosing : false;    // If the video Scroll bar is in closing process

        onTouch: {
            if (OrientationSupport.orientation == UIOrientation.Portrait) {
                heightOfScreen = landscapeWidth;
                touchDistanceAgainstMode = 150;
            } else {
                heightOfScreen = landscapeHeight;
                touchDistanceAgainstMode = 300;
            }
            if (event.touchType == TouchType.Down) {
                appContainer.previousPositionX = event.localX;
                appContainer.previousPositionY = event.localY;
                appContainer.touchPositionX =  event.localX;
                appContainer.touchPositionY =  event.localY;
                contentContainer.startingX = videoWindow.translationX;
                contentContainer.startingY = videoWindow.translationY;
                appContainer.directionIsDetect = false;
                appContainer.volumeChange = false;
                appContainer.volumeFullorMute = false;
                appContainer.counterForDetectDirection = 5;
                appContainer.offsetX = 0;
                appContainer.offsetY = 0;
                     
            } else if (event.touchType == TouchType.Up && !appContainer.volumeChange) {
                if (Math.abs(appContainer.touchPositionX - event.localX) > touchDistanceAgainstMode) {
                    if (videoWindow.scaleX <= 1.0) {
                        videoWindow.translationX = 0;
                        videoWindow.translationY = 0;
                        contentContainer.startingX = 0;
                        contentContainer.startingY = 0;
                        // TODO: probably we could use the application container size
                        // to calculate the magic numbers below by the percentage

                        if (appContainer.touchPositionX >= event.localX + touchDistanceAgainstMode) {
                            appContainer.changeVideoPosition = true;
                            if (durationSlider.immediateValue + (5 * 1000) < durationSlider.toValue) {
                                appContainer.seekPlayer(durationSlider.immediateValue + 5 * 1000);
                            } else {
                                appContainer.seekPlayer(durationSlider.toValue);
                                myPlayer.pause();
                            }
                        } else if (appContainer.touchPositionX + touchDistanceAgainstMode < event.localX) {
                            appContainer.changeVideoPosition = true;
                            appContainer.seekPlayer(durationSlider.immediateValue - 5 * 1000);
                        }
                        appContainer.changeVideoPosition = false;
                    }
                } else {
                    if (Math.abs(appContainer.touchPositionX - event.localX) < 100 && ! videoListScrollBar.visible 
                                                                              && !appContainer.volumeFullorMute) {
                        if (event.localY < heightOfScreen - durationSlider.height) {
                            appContainer.showPlayPauseButton();
                        }
                    }
                }
                if (event.localY > 180 && videoListScrollBar.visible && ! appContainer.videoScrollBarIsClosing) {
                    videoListDisappearAnimation.play();
                } else {
                    upperMenu.setOpacity(1);
                    controlsContainer.setOpacity(1);
                    controlsContainer.setVisible(true);
                    uiControlsShowTimer.start();
                }
            } 
            else if(event.touchType == TouchType.Move ){
                	if (videoWindow.scaleX > 1.0) {
                    appContainer.moveX(event.localX);
                    appContainer.moveY(event.localY);
                }
                if(!appContainer.directionIsDetect){	
                	 
                    if (appContainer.counterForDetectDirection != 0) {
                    	appContainer.offsetX += Math.abs(appContainer.previousPositionX - event.localX);
                    	appContainer.offsetY += Math.abs(appContainer.previousPositionY - event.localY);
                    	--appContainer.counterForDetectDirection;
                    }
                    else {
                    if(offsetX > offsetY){
                        appContainer.directionIsDetect = true;
                        }
                        else{
                            appContainer.volumeChange = true;
                         if (appContainer.previousPositionY - event.localY > 0) {
                         	if (videoWindow.scaleX <= 1.0) {
                         	    if(appContainer.previousPositionY - event.localY > 30){
                         	    }
                            	appContainer.curVolume = appContainer.curVolume + (appContainer.previousPositionY - event.localY) / 10;
                            	if (appContainer.curVolume > 100) 
                                appContainer.curVolume = 100;
                                bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                            
	                             volume.visible = true;
	                             if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/back.png";
	                             else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
	                             if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/back.png";
	                             else volumeFull.imageSource = "asset:///images/Player/Volume Full.png";
                    		}
                     	}
                        if ( appContainer.previousPositionY - event.localY  < 0) {
                            if (videoWindow.scaleX <= 1.0) {
                                appContainer.curVolume = appContainer.curVolume + (appContainer.previousPositionY - event.localY) / 10;
                                if (appContainer.curVolume < 0) appContainer.curVolume = 0;
                                bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);

                                volume.visible = true;
                                if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/back.png";
                                else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                                if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/back.png";
                                else volumeFull.imageSource = "asset:///images/Player/Volume Full.png";
                            }
                        }
                    }
                    }
                appContainer.previousPositionX = event.localX;
                appContainer.previousPositionY = event.localY;    
            }   
            }    
        }// onTouch

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
                property double initialScale: appContainer.initialScreenScale

               // This custom property determines how quickly the ForeignWindow grows
               // or shrinks in response to the pinch gesture
               property double scaleFactor: 0.5

               // Temporary variable, used in computation for pinching everytime
               property double newScaleVal

                gestureHandlers: [
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

            //Subtitle area
            SubtitleArea {
                id: subtitleAreaContainer
                layoutProperties: AbsoluteLayoutProperties {
                    id: subtitleArea
                    positionX: 0
                    positionY: videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
               }
           }

                Container {
                    id: volume
                    layout: AbsoluteLayout {
                    }
                    visible: false

                    property int positionY: 225

                    Container {
                        layout: AbsoluteLayout {
                        }

                        preferredHeight: volume.positionY + 80

                        Label {
                            text: appContainer.curVolume
                            horizontalAlignment: HorizontalAlignment.Center
                            verticalAlignment: VerticalAlignment.Center
                            textStyle {
                                color: Color.White
                                fontWeight: FontWeight.Normal
                            }
                        }

                        ImageView {
                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 40
                                positionY: volume.positionY - 80
                            }
                            imageSource: "asset:///images/Player/VolumeInactive.png"
                        }
                        ImageView {
                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 40
                                positionY: volume.positionY
                            }
                            imageSource: "asset:///images/Player/VolumeInactive.png"
                        }

                        ImageView {
                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 40
                                positionY: volume.positionY + 80 - appContainer.curVolume * (160 / 100)
                            }
                            imageSource: "asset:///images/Player/VolumeActive.png"
                        }
                        ImageView {

                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 40
                                positionY: volume.positionY + 80 + 80 - appContainer.curVolume * (160 / 100)
                            }
                            imageSource: "asset:///images/Player/VolumeActive.png"

                        }
                    }

                    Container {
                        layout: AbsoluteLayout {
                        }
                        ImageView {
                            id: volumeFull
                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 30
                                positionY: volume.positionY - 85 - 50
                            }
                            imageSource: "asset:///images/Player/Volume Full.png"
                            horizontalAlignment: HorizontalAlignment.Left
                            onTouch: {
                                appContainer.volumeFullorMute = true
                                appContainer.curVolume = 100;
                                volumeFull.imageSource = "asset:///images/back.png"
                                volumeMute.imageSource = "asset:///images/Player/VolumeMute.png"
                            }
                        }
                        ImageView {
                            id: volumeMute
                            layoutProperties: AbsoluteLayoutProperties {
                                positionX: 30
                                positionY: volume.positionY + 85
                            }
                            imageSource: "asset:///images/Player/VolumeMute.png"
                            horizontalAlignment: HorizontalAlignment.Left
                            onTouch: {
                                appContainer.volumeFullorMute = true
                                appContainer.curVolume = 0;
                                volumeMute.imageSource = "asset:///images/back.png"
                                volumeFull.imageSource = "asset:///images/Player/Volume Full.png"
                            }
                        }
                    }
                }

            }
       
            gestureHandlers: [
                // Add a handler for pinch gestures
                PinchHandler {
                    // When the pinch gesture starts, save the initial scale
                    // of the window
                    onPinchStarted: {
                        console.log("onPinchStart: videoWindow.scaleX = " + videoWindow.scaleX);
                        videoWindow.initialScale = videoWindow.scaleX;
                        appContainer.startPinchDistance = event.distance;
                        appContainer.startMidPointXPinch = event.midPointX;
                    }

                    // As the pinch expands or contracts, change the scale of
                    // the image
                    onPinchUpdated: {
                        console.log("onPinchUpdate");
                        videoWindow.newScaleVal = videoWindow.initialScale + ((event.pinchRatio - 1) * videoWindow.scaleFactor);
                        console.log("onPinchUpdate: videoWindow.initialScale = " + videoWindow.initialScale + ": event.pinchRatio-1= " + event.pinchRatio - 1 + " : newScaleVal = " + videoWindow.newScaleVal);
                        if (videoWindow.newScaleVal < 1) {
                            videoWindow.newScaleVal = 1;
                        }
                        if (videoWindow.newScaleVal < appContainer.maxScreenScale &&
                            videoWindow.newScaleVal > appContainer.minScreenScale) {
                            videoWindow.scaleX = videoWindow.newScaleVal;
                            videoWindow.scaleY = videoWindow.newScaleVal;
                            videoWindow.translationX = 0;
                            videoWindow.translationY = 0;
                        }
                    } // onPinchUpdate
                    onPinchEnded: {
                        if(videoWindow.initialScale <= appContainer.initialScreenScale + 0.1)
                        {
                            appContainer.endPinchDistance = event.distance;
                            appContainer.endMidPointXPinch = event.midPointX;
                            if ((appContainer.startPinchDistance / appContainer.endPinchDistance > appContainer.minPinchPercentFactor) &&
                                (appContainer.startPinchDistance / appContainer.endPinchDistance < appContainer.maxPinchPercentFactor)) {
                                if (appContainer.startMidPointXPinch > event.midPointX + 200 ||
                                    appContainer.startMidPointXPinch + 200 < event.midPointX) {
                                        if(appContainer.startMidPointXPinch > appContainer.endMidPointXPinch) {
                                            myPlayer.setSourceUrl(infoListModel.getNextVideoPath());
                                            myPlayer.play();
                                        } else {
                                            myPlayer.setSourceUrl(infoListModel.getPreviousVideoPath());
                                            myPlayer.play();
                                        }
                                }
                            }
                        }
                    } // onPinchEnded
                } // PinchHandler
            ] // attachedObjects

            // Play/pause image is transparent. It will become visible when the video
            // is played/paused using tap event. It will be visible 1 sec.
            ImageView {
                id: screenPlayPauseImage
                opacity: 0
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
                visible: false
                onVideoSelected: {
                    console.log("selected item PATH == " + item.path);
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
                    }
                }

                animations: [
                    TranslateTransition {
                        id: videoListAppearAnimation
                        duration: 800
                        easingCurve: StockCurve.CubicOut
                        fromY: -100
                        toY: 0
                    },
                    TranslateTransition {
                        id: videoListDisappearAnimation
                        duration: 600
                        easingCurve: StockCurve.ExponentialIn
                        fromY: 0
                        toY: -150
                        onStarted: {
                            appContainer.videoScrollBarIsClosing = true;
                            }
                        onEnded: {
                            appContainer.videoScrollBarIsClosing = false;
                            videoListScrollBar.visible = false;
                        }
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
                            infoListModel.setVideoPosition(myPlayer.position);
                            appContainer.curVolume = bpsEventHandler.getVolume();
                            navigationPane.pop();
                            pgPlayer.destroy();
                        }
                    }
                } //backButtonContainer
                Container {
                    id: videoTitleContainer
                    background: backgroundPaint.imagePaint
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Fill
                    maxWidth: upperMenu.preferredWidth - 300
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
                            imageSource: "asset:///images/Player/BoxMovieListItemTitle.png"
                            repeatPattern: RepeatPattern.Fill
                        },
                        LayoutUpdateHandler {
                            id: handler
                        }
                    ]
                } // videoTitleContainer
                Container {
                    layout: StackLayout {
                        orientation: LayoutOrientation.LeftToRight
                    }
                    horizontalAlignment: HorizontalAlignment.Right
                    verticalAlignment: VerticalAlignment.Center
                    Container {
                        id: subtitleButtonContainer
                        objectName: subtitleButtonContainer
                        opacity: 0.5
                        verticalAlignment: VerticalAlignment.Center
                        rightPadding: 10

                        ImageButton {
                            id: subtitleButton
                            defaultImageSource: "asset:///images/Player/SubtitlesButton.png"
                            onClicked: {
                                if (subtitleAreaContainer.opacity == 1) subtitleAreaContainer.setOpacity(0);
                                else subtitleAreaContainer.setOpacity(1);
                            }
                        }
                    } //subtitleButtonContainer
                    Container {
                        id: hdmiButtonContainer
                        objectName: hdmiButtonContainer
                        opacity: 0.5
                        verticalAlignment: VerticalAlignment.Center
                        rightPadding: 10

                        ImageButton {
                            id: hdmiButton
                            defaultImageSource: "asset:///images/Player/HDMI Button.png"

                            onClicked: {
                            // enable or disable hdmi
                            }
                        }
                    } //subtitleButtonContainer
                }
            }
            onCreationCompleted: {
                if (OrientationSupport.orientation == UIOrientation.Landscape)
                    upperMenu.preferredWidth = appContainer.landscapeWidth
                else upperMenu.preferredWidth = appContainer.landscapeHeight
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
                        console.log("onImmediateValueChanged");
                        if(myPlayer.mediaState == MediaState.Started ||
                            myPlayer.mediaState == MediaState.Paused) {
                            if(appContainer.changeVideoPosition == true && immediateValue != value) {
                                myPlayer.seekTime(durationSlider.immediateValue);
                                myPlayer.valueChangedBySeek = true;
                                appContainer.changeVideoPosition = false;
                            }
                        }
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
        function moveX(localX) {
            appContainer.currentTranslation = localX - appContainer.touchPositionX + contentContainer.startingX;
            if (appContainer.currentTranslation < 0) {
                appContainer.currentTranslation = - appContainer.currentTranslation;
            }
            if (appContainer.currentTranslation < (videoWindow.preferredWidth * videoWindow.scaleX - videoWindow.preferredWidth) / 2) {
                console.log("Trans XXXX = ", appContainer.currentTranslation);
                videoWindow.translationX = localX - appContainer.touchPositionX + contentContainer.startingX;
            }
        }
        function moveY(localY) {
            appContainer.currentTranslation = localY - appContainer.touchPositionY + contentContainer.startingY;
            if (appContainer.currentTranslation < 0) {
                appContainer.currentTranslation = - appContainer.currentTranslation;
            }
            if (appContainer.currentTranslation < (videoWindow.preferredHeight * videoWindow.scaleY - videoWindow.preferredHeight) / 2) {
                videoWindow.translationY = localY - appContainer.touchPositionY + contentContainer.startingY;
            }
        }
        function seekPlayer(time) {
            myPlayer.seekTime(time);
            myPlayer.valueChangedBySeek = true;
            appContainer.changeVideoPosition = false;
        }

        function showPlayPauseButton() {
            if(myPlayer.mediaState != MediaState.Started) {
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

           BpsEventHandler {
               id: bpsEventHandler
               onVideoWindowStateChanged: {
                   if(isMinimized && myPlayer.mediaState == MediaState.Started) {
                       // Application is minimized. Pause the video
                       appContainer.pauseMediaPlayer();
                   }
                   if(!isMinimized && myPlayer.mediaState == MediaState.Paused) {
                       // Application is maximized. Started playing the stopped video
                       appContainer.playMediaPlayer();
                   }
               }
               
                onSpeakerVolumeChanged: {
                    volume.visible = true;
                    appContainer.curVolume = bpsEventHandler.getVolume();
                    if (appContainer.curVolume == 0) volumeMute.imageSource = "asset:///images/back.png";
                    else volumeMute.imageSource = "asset:///images/Player/VolumeMute.png";
                    if (appContainer.curVolume == 100) volumeFull.imageSource = "asset:///images/back.png";
                    else volumeFull.imageSource = "asset:///images/Player/Volume Full.png";
                }

                onShowVideoScrollBar: {
                   videoListAppearAnimation.play();
                   videoListScrollBar.visible = true;
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

                var videoPos = infoListModel.getVideoPosition();
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