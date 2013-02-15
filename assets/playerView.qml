import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0
import bpsEventHandler 1.0
import nutty.slider 1.0

Page {
    id: pgPlayer

    Container {
        id: appContainer
        background: Color.create("#ff262626")

        layout: DockLayout {
        }

        //This variable is used to control video duration logic. 
        //Indicates whether to change the video position, when the slider's value is changed.
        property bool changeVideoPosition : true

        // This properties are used for dynamically defining video window size for different orientations
        property int landscapeWidth : 1280
        property int landscapeHeight : 768
        
        property int subtitleAreaBottomPadding : 150
        
        property int touchPositionX: 0
        property int touchPositionY: 0
        property bool playerStarted: false

        property double minScreenScale: 0.5        //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0        //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScale: 1.0  // Starts the video with original dimensions (that is, scale factor 1.0)
                                                 // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
                                                 // They both start with the same value but the "initialScale" value is different for every new pinch 
        property double currentTranslation;
        
        property double curVolume: bpsEventHandler.getVolume();

        Container {
            id: contentContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom

            layout: DockLayout {}

	        preferredWidth:  appContainer.landscapeWidth
	        preferredHeight: appContainer.landscapeHeight 

	        property int startingX
	        property int startingY  

	       onTouch: {
	        	if (event.touchType == TouchType.Down)
	        	{
                    if (event.localY < 100) {
                        videoListScrollBar.visible = true;
                    } else {
                        videoListScrollBar.visible = false;
                    }
                    appContainer.touchPositionX =  event.localX;
	        	     appContainer.touchPositionY =  event.localY;
	        	     contentContainer.startingX = videoWindow.translationX
	        	     contentContainer.startingY = videoWindow.translationY
	            }
	            else if (event.touchType == TouchType.Up)
	            {
	                if ((appContainer.touchPositionX  > event.localX + 30) ||
	                    (appContainer.touchPositionX + 30  < event.localX) && 
	                    ((appContainer.touchPositionY - event.localY <= 10) ||
	                    (event.localY - appContainer.touchPositionY <= 10))) 
	                {
		                if (videoWindow.scaleX <= 1.0) 
		                {
		                    videoWindow.translationX = 0;
		                    videoWindow.translationY = 0;
		                    contentContainer.startingX = 0;
		                    contentContainer.startingY = 0;		
		                     if (appContainer.touchPositionX > event.localX + 30) {
		                         appContainer.changeVideoPosition = true;
		                         if (durationSlider.immediateValue + 5000/myPlayer.duration < 1) {
		                             durationSlider.setValue(durationSlider.immediateValue + 5000/myPlayer.duration);
		                         } else {
		                             durationSlider.setValue(1);
		                             myPlayer.pause();		                         
		                         }
		                     }
		                     else if (appContainer.touchPositionX + 30  < event.localX)
		                     {
			                     appContainer.changeVideoPosition = true;
			                     durationSlider.setValue(durationSlider.immediateValue - 5000/myPlayer.duration);
			                } 
			            }
			        } 
			        else if (appContainer.touchPositionY - event.localY > 10)
			        {
                        if (videoWindow.scaleX <= 1.0) {
                            appContainer.curVolume = appContainer.curVolume + (appContainer.touchPositionY - event.localY) / 10;
                            if (appContainer.curVolume > 100) 
                                appContainer.curVolume = 100;
                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                        }
                    }
                    else if (event.localY - appContainer.touchPositionY > 10)
                    {
                        if (videoWindow.scaleX <= 1.0) {
                            appContainer.curVolume = appContainer.curVolume + (appContainer.touchPositionY - event.localY) / 10;
                            if (appContainer.curVolume < 0) 
                                appContainer.curVolume = 0;
                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
                        }
                    }
                    else
                    {
                       if(myPlayer.mediaState != MediaState.Started) {
                        	appContainer.playMediaPlayer();
                            screenPlayImage.setOpacity(0.5)
                            screenPauseImage.setOpacity(0)
                            screenPlayImageTimer.start()
                        } else {
                            appContainer.pauseMediaPlayer();
                            screenPauseImage.setOpacity(0.5)
                            screenPlayImage.setOpacity(0)
                            screenPauseImageTimer.start()
                        }
	                 }
	            } 
	            else if (event.touchType == TouchType.Move)
	            {
	                if (videoWindow.scaleX > 1.0) 
	                {
	                    appContainer.moveX(event.localX);	
	                    appContainer.moveY(event.localY);          	                  	                  
                    }	
	            }
	        }// onTouch

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
	        
            VideoListScrollBar {
                    id: videoListScrollBar
                    horizontalAlignment: HorizontalAlignment.Center
                    overlapTouchPolicy: OverlapTouchPolicy.Allow
                    visible: false
                    onVideoSelected: {
                        console.log(item.path);
                        myPlayer.stop()
                        myPlayer.setSourceUrl(item.path);
                        if (appContainer.playMediaPlayer() == MediaError.None) {
                            videoWindow.visible = true;
                            contentContainer.visible = true;
                            durationSlider.resetValue();
                            durationSlider.setEnabled(true)
                            subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl);
                            trackTimer.start();
                        }
                    }
                }// videoListScrollBar

                ///Subtitle area
            Container {
                id: subtitleArea
                layoutProperties: AbsoluteLayoutProperties {
                    positionX: 0
                    positionY: videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
                }

                layout: StackLayout {
                    orientation: LayoutOrientation.TopToBottom
                }
                preferredHeight: 200                
                Container {
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1.0
                    }

                }
                TextArea {                    
                    text: subtitleManager.text
                    textFormat: TextFormat.Html
                    backgroundVisible: false
                    textStyle.color: Color.White
                    textStyle.textAlign: TextAlign.Center
                    editable: false
                    overlapTouchPolicy: OverlapTouchPolicy.Allow
                    verticalAlignment: VerticalAlignment.Bottom
                    horizontalAlignment: HorizontalAlignment.Center                        
                    inputMode: TextAreaInputMode.Text     
                    onCreationCompleted: {
                        setImplicitLayoutAnimationsEnabled(false);
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
                        if (videoWindow.newScaleVal < appContainer.maxScreenScale && videoWindow.newScaleVal > appContainer.minScreenScale) {
                            videoWindow.scaleX = videoWindow.newScaleVal;
                            videoWindow.scaleY = videoWindow.newScaleVal;
                            videoWindow.translationX = 0;
                            videoWindow.translationY = 0;
                        }
                    } // onPinchUpdate
                } // PinchHandler
            ] // attachedObjects

            // Play image is transparent. It will become visible when the video
            // is played using tap event. It will be visible 1 sec.
            ImageView {
                id: screenPlayImage
                opacity: 0
                imageSource: "asset:///images/screenPlay.jpg"
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
            }

            // Pause image is transparent. It will become visible when the video
            // is paused using tap event. It will be visible 1 sec.
            ImageView {
                id: screenPauseImage
                opacity: 0
                imageSource: "asset:///images/screenPause.jpg"
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
            }

            Container
            {
                id: controlsContainer
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

                        onClickedByUserChanged: {
                            if(myPlayer.seekTime(durationSlider.clickedByUser) != MediaError.None) {
                                console.log("seekTime ERROR");
                            }
                          }
	                } //durationSlider
                }//sliderContainer

	            Container {
	                id: buttonContainer
	                objectName: buttonContainer

	                opacity: 0.5

	                layout: StackLayout {
	                    orientation: LayoutOrientation.LeftToRight
	                }

	                leftPadding: 40
	                rightPadding: 40
	                horizontalAlignment: HorizontalAlignment.Left
	                verticalAlignment: VerticalAlignment.Bottom

	                ImageButton {
	                    id:backButton
	                    defaultImageSource: "asset:///images/back.png"

	                    onClicked:{
	                        infoListModel.setVideoPosition(myPlayer.position);
	                        myPlayer.stop();
	                        appContainer.curVolume = bpsEventHandler.getVolume();
	                        console.log("CUR VOLUME ==== " + appContainer.curVolume);
                            navigationPane.pop();
                            pgPlayer.destroy();
	                    }
	                }

	                ImageButton {
	                    id:playButton
	                    defaultImageSource: "asset:///images/play.png"
	                    property int videoPos : 0
	                    
	                    onClicked:{
	                        if(myPlayer.mediaState == MediaState.Started) {
	                            appContainer.pauseMediaPlayer();
	                        }
	                        else if(myPlayer.mediaState == MediaState.Paused) {
	                            appContainer.playMediaPlayer();
	                        }
	                        else {
	                            myPlayer.setSourceUrl(infoListModel.getSelectedVideoPath());
	                            myPlayer.prepare();
	                            bpsEventHandler.onVolumeValueChanged(appContainer.curVolume);
	                            if (appContainer.playMediaPlayer() == MediaError.None) {
	                                videoPos = infoListModel.getVideoPosition();
	                                videoWindow.visible = true;
	                                contentContainer.visible = true;
	                                durationSlider.setEnabled(true);
	                                durationSlider.resetValue();
	                                subtitleManager.setSubtitleForVideo(myPlayer.sourceUrl);
	                                appContainer.changeVideoPosition = false;       
	                                if(myPlayer.seekTime(videoPos) != MediaError.None) {
	                                    console.log("seekTime ERROR");
	                                }
	                                appContainer.changeVideoPosition = true;
	                                trackTimer.start();	
	                            }
	                        }
	                    }
	                }
	            }//buttonContainer

            }//controlsContainer

        }//contentContainer

        function playMediaPlayer() {
            playButton.setDefaultImageSource("asset:///images/pause.png");            
            return myPlayer.play();
        }

        function pauseMediaPlayer() {
            playButton.setDefaultImageSource("asset:///images/play.png");           
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
                console.log("Trans YYYY = ", appContainer.currentTranslation)
                videoWindow.translationY = localY - appContainer.touchPositionY + contentContainer.startingY;
            }
        }

        attachedObjects: [
            Sheet {
                id: videoSheet
                objectName: "videoSheet"
                content:Page {

                }
           
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
                   durationSlider.time = position;
                   //Set correct subtitle positon
                   if (valueChangedBySeek) {
                       myPlayer.positionInMsecs = myPlayer.position;
                       subtitleManager.seek(myPlayer.positionInMsecs);
                       valueChangedBySeek = false;
                   }
               }
               onDurationChanged: {
                   durationSlider.totalTime = duration;
                   totalTime.text = infoListModel.getFormattedTime(duration)
               }

               // Investigate how the metadata can be retrieved without playing the video.
               onMetaDataChanged: {
                    console.log("player onMetaDataChanged");
                    console.log("--------------------------------bit_rate=" + myPlayer.metaData.bit_rate);
                    console.log("-----------------------------------genre=" + myPlayer.metaData.genre);
                    console.log("-----------------------------sample_rate=" + myPlayer.metaData.sample_rate);
                    console.log("-----------------------------------title=" + myPlayer.metaData.title);
                }
           },

           SubtitleManager {
               id: subtitleManager;
           },

           BpsEventHandler {
               id: bpsEventHandler
             
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
                       if (myPlayer.duration) {
                           durationSlider.setValue(myPlayer.positionInMsecs / myPlayer.duration)
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
               id: screenPlayImageTimer
               singleShot: true
               interval: 1000
               onTimeout: {
                   screenPlayImage.setOpacity(0)
                   screenPlayImageTimer.stop()
		       }
           },

           QTimer {
               id: screenPauseImageTimer
               singleShot: true
               interval: 1000
               onTimeout: {
                   screenPauseImage.setOpacity(0)
                   screenPauseImageTimer.stop()
		       }
           },

           OrientationHandler {
               onOrientationAboutToChange: {
                   if (orientation == UIOrientation.Landscape) {
                       videoWindow.preferredWidth = appContainer.landscapeWidth
                       videoWindow.preferredHeight = appContainer.landscapeHeight                       
                       subtitleArea.layoutProperties.positionY = videoWindow.preferredHeight - appContainer.subtitleAreaBottomPadding;
                   } else {
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
                videoPos = infoListModel.getVideoPosition();
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
        }

    }//appContainer
}// Page