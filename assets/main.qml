import bb.cascades 1.0

import bb.multimedia 1.0

Page {
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
        
        property int touchPositionX: 0
        property int touchPositionY: 0
        property bool playerStarted: false
        
        property double minScreenScale: 0.5        //THIS IS THE MINIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double maxScreenScale: 2.0        //THIS IS THE MAXIMUM SCALE FACTOR THAT WILL BE APPLIED TO THE SCREEN SIZE
        property double initialScreenScale: 1.0  // Starts the video with original dimensions (that is, scale factor 1.0)
                                                 // NOTE: this is not to be confused with the "initialScale" property of the ForeignWindow below
                                                 // They both start with the same value but the "initialScale" value is different for every new pinch 
        
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
	        	     appContainer.touchPositionX =  event.localX;
	        	     appContainer.touchPositionY =  event.localY;
	        	     contentContainer.startingX = videoWindow.translationX
	        	     contentContainer.startingY = videoWindow.translationY
	            }
	            else if (event.touchType == TouchType.Up)
	            {
	                if (videoWindow.newScaleVal <= videoWindow.initialScale) 
	                {
	                    videoWindow.translationX = 0;
        	                    videoWindow.translationY = 0;

	                     if (appContainer.touchPositionX  > event.localX + 30) {
	                         appContainer.changeVideoPosition = true;
	                         if (durationSlider.immediateValue + 5000/myPlayer.duration < 1) {
	                             durationSlider.setValue(durationSlider.immediateValue + 5000/myPlayer.duration);
	                         } else {
	                             durationSlider.setValue(1);
	                             myPlayer.pause();
	                         }
	                } else if (appContainer.touchPositionX + 30  < event.localX) {
	                     appContainer.changeVideoPosition = true;
	                     durationSlider.setValue(durationSlider.immediateValue - 5000/myPlayer.duration);
	                } else {
	                       if(myPlayer.mediaState != MediaState.Started) {
	                        	myPlayer.play();
	                            playImage.setOpacity(0.5)
	                            pauseImage.setOpacity(0)
	                            playImageTimer.start()
	                        } else {
	                            myPlayer.pause();
	                            pauseImage.setOpacity(0.5)
	                            playImage.setOpacity(0)
	                            pauseImageTimer.start()
	                        }
	                    }
	                 }
	            } 
	            else if (event.touchType == TouchType.Move)
	            {
	                if (videoWindow.newScaleVal > videoWindow.initialScale) 
	                {	
	                    videoWindow.translationX = event.localX - appContainer.touchPositionX + contentContainer.startingX;
	                    videoWindow.translationY = event.localY - appContainer.touchPositionY + contentContainer.startingY;
	                }
	
	            }
	        }// onTouch
            
	        ForeignWindowControl {
                id: videoWindow
                objectName: "VideoWindow"
                windowId: "VideoWindow"
	             
	              layoutProperties: AbsoluteLayoutProperties {
	                             positionX: 0
	                             positionY: 0
	                         }
	            property double initialScale: appContainer.initialScreenScale   
	            
	           // This custom property determines how quickly the ForeignWindow grows
               // or shrinks in response to the pinch gesture
               property double scaleFactor: 0.3
            
               // Temporary variable, used in computation for pinching everytime
               property double newScaleVal
               
				gestureHandlers: [
				        
				]
				    				    
	            preferredWidth:  appContainer.landscapeWidth
	            preferredHeight: appContainer.landscapeHeight 
//		        layoutProperties: AbsoluteLayoutProperties {
//		            positionX: 0
//		            positionY: 500
//		        }
	            //  visible:  boundToWindow
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
                        console.log ("onPinchUpdate: videoWindow.initialScale = " + videoWindow.initialScale + ": event.pinchRatio-1= " + event.pinchRatio-1 + " : newScaleVal = " + videoWindow.newScaleVal);
                      
                        if ( videoWindow.newScaleVal < appContainer.maxScreenScale &&  videoWindow.newScaleVal > appContainer.minScreenScale ) {
                            videoWindow.scaleX = videoWindow.newScaleVal;
                            videoWindow.scaleY = videoWindow.newScaleVal;
                            // align this with the zoomSlider as well
                           // zoomSlider.value = videoWindow.newScaleVal;
                        }
                    }// onPinchUpdate
                }// PinchHandler
            ]// attachedObjects
            
            // Used for controlling zoom level of the window
          /* Slider {
                id: zoomSlider
                property double requestedValue
                layoutProperties: DockLayoutProperties {
                    verticalAlignment: VerticalAlignment.Top
                    horizontalAlignment: HorizontalAlignment.Center
                }
                fromValue: appContainer.minScreenScale
                toValue: appContainer.maxScreenScale
                //NOTE: Using absolute value here
                value: appContainer.initialScreenScale     // starting with the default size of the video
                onValueChanged: {
                    requestedValue = value;
                    
                    videoWindow.preferredWidth = myPlayer.videoDimensions.width * value;
                    videoWindow.minWidth = myPlayer.videoDimensions.width  * value;
                    videoWindow.maxWidth = myPlayer.videoDimensions.width  * value;
                    videoWindow.preferredHeight = myPlayer.videoDimensions.height  * value;
                    videoWindow.minHeight = myPlayer.videoDimensions.height * value;
                    videoWindow.maxHeight = myPlayer.videoDimensions.height * value;
                } // onValueChanged
                    
            } // ZoomSlider*/
	                            
	                            
            // Play image is transparent. It will become visible when the video
            // is played using tap event. It will be visible 1 sec.
            ImageView {
                id: playImage
                opacity: 0
                imageSource: "asset:///images/play.jpg"
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                touchPropagationMode: TouchPropagationMode.PassThrough
                overlapTouchPolicy: OverlapTouchPolicy.Allow
            }
   
            // Pause image is transparent. It will become visible when the video
            // is paused using tap event. It will be visible 1 sec.
            ImageView {
                id: pauseImage
                opacity: 0
                imageSource: "asset:///images/pause.jpg"
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

                Slider {
                    id: durationSlider
                    objectName: durationSlider
                    leftMargin: 20
                    rightMargin: 20
                    fromValue: 0.0
                    toValue: 1.0
                    enabled: false
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Bottom
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
                    }
                    onTouch: {
                        if (event.touchType == TouchType.Down) {  
                            if(myPlayer.mediaState == MediaState.Started) {
                        	     myPlayer.pause();
                        	     appContainer.playerStarted = true;
                        	 }
                        } else if (event.touchType == TouchType.Up) { 
                            if(appContainer.playerStarted == true) {
                                if ( appContainer.playerStarted == true) {
                                    myPlayer.play();
                        	       	appContainer.playerStarted = false;
                        	    }
                            }
                        }
                    }
                    onImmediateValueChanged: {
                        if(myPlayer.mediaState == MediaState.Started ||
                            myPlayer.mediaState == MediaState.Paused) {
                                if(appContainer.changeVideoPosition == true) {
                                    myPlayer.seekPercent(durationSlider.immediateValue);
                                }
                        }
                    }
                } //durationSlider
            
                Container {
	                id: buttonContainer
	                objectName: buttonContainer

	                layout: StackLayout {
	                    orientation: LayoutOrientation.LeftToRight
	                }
	                
	                leftPadding: 20
	                rightPadding: 20
	                horizontalAlignment: HorizontalAlignment.Center
	                verticalAlignment: VerticalAlignment.Bottom
	                
/*	                Button {
	                    id:stopButton
	                    text: "Stop"
	                    
	                    onClicked:{
	                        videoWindow.visible = false;
	                        myPlayer.stop()
	                        trackTimer.stop()	                        
	                        durationSlider.resetValue()
	                        durationSlider.setEnabled(false)
	                    }
	                }
*/
	                Button {
	                    id:backButton
	                    text: "Back"
	                    
	                    onClicked:{
	                        // TODO Implement Back functionality
	                    }
	                }
	                
	                Button {
	                    id:previousButton
	                    text: "Previous"
	                    
	                    onClicked:{
	                        myPlayer.stop()
	                        myPlayer.setSourceUrl(mycppPlayer.getPreviousVideoPath())
	                        if (myPlayer.play() == MediaError.None) {
	                          videoWindow.visible = true;
	                          contentContainer.visible = true;
	                          durationSlider.resetValue()
	                          durationSlider.setEnabled(true)
	                          trackTimer.start();
	                        }
	                    }
	                }
	                
	                Button {
	                    id:playButton
	                    text: "Play/Pause"
	                    onClicked:{	                       
	                        if(myPlayer.mediaState == MediaState.Started) {
	                            console.log("\n\n\n\nPAUUUSSSEEE\n\n\n\n")
	                            myPlayer.pause();
	                        }
	                        else if(myPlayer.mediaState == MediaState.Paused) {
	                            console.log("\n\n\n\nPLLLAYYYY\n\n\n\n")
	                            myPlayer.play();
	                        }
	                        else {
	                            console.log("CURRENT VIDEO PATH")
	                            console.log(mycppPlayer.getVideoPath())
	                            myPlayer.setSourceUrl(mycppPlayer.getVideoPath())
	                            if (myPlayer.play() == MediaError.None) {
	                                videoWindow.visible = true;
	                                contentContainer.visible = true;
	                                durationSlider.setEnabled(true)
	                                durationSlider.resetValue()
	                                trackTimer.start();
	                            }
	                        }
	                    }
	                }
	                
	                Button {
	                    id:nextButton
	                    text: "Next"
	                    
	                    onClicked:{
	                        myPlayer.stop();
	                        myPlayer.setSourceUrl(mycppPlayer.getNextVideoPath())
	                        if (myPlayer.play() == MediaError.None) {
	                          videoWindow.visible = true;
	                          contentContainer.visible = true;
	                          durationSlider.resetValue()
	                          durationSlider.setEnabled(true)
	                          trackTimer.start();
	                        }
	                    }
	                }
	                
	                Button {
	                    id:muteButton
	                    text: "Mute"
	                    
	                    onClicked:{}
	                }
	               
	            }//buttonContainer
                
            }//controlsContainer
            
        }//contentContainer
        
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
               onVideoDimensionsChanged: {
                                /*   console.log ("onVideoDimensionsChanged: width = " + videoDimensions.width + " : height = " + videoDimensions.height + " : videoSurface.windowHandle = " + videoWindow.windowHandle);
                                   
                                  // videoWindow.preferredWidth = videoDimensions.width;
                                   videoWindow.minWidth = videoDimensions.width;
                                   videoWindow.maxWidth = videoDimensions.width;
                                   
                                  // videoWindow.preferredHeight = videoDimensions.height;
                                   videoWindow.minHeight = videoDimensions.height;
                                   videoWindow.maxHeight = videoDimensions.height;
                                  
                                   videoWindow.translationY = appContainer.preferredHeight / 2 - (videoWindow.preferredHeight / 2);
                                   videoWindow.translationX = appContainer.preferredWidth / 2 - (videoWindow.preferredWidth / 2);
                             */ }          
           },
           
           QTimer {
               id: trackTimer
               singleShot: false
               //Investigate why the onTimeout is called after 1000 msec
               interval: 500
               onTimeout: {
                   console.log("\n\n\n\nASTDYFYTSFDYATFSDYA\n")
//                   console.log("POS = " + myPlayer.position + "\n")
//                   console.log("DUR = " + myPlayer.duration + "\n\n\n\n")
//                   property float myPlayer.position / myPlayer.duration
		           if(myPlayer.mediaState == MediaState.Started) {
		               appContainer.changeVideoPosition = false;
		               durationSlider.setValue(myPlayer.position / myPlayer.duration)
		               appContainer.changeVideoPosition = true;
		           }
		           else if(myPlayer.mediaState == MediaState.Stopped) {
		               console.log("\n\n\n\nSTOP STOP STOP\n\n\n\n")
		               appContainer.changeVideoPosition = false;
		               durationSlider.setValue(durationSlider.toValue)
		               appContainer.changeVideoPosition = true;		                
		               trackTimer.stop();
		           }
		       }
           },
           
           QTimer {
               id: playImageTimer
               singleShot: true
               interval: 1000
               onTimeout: {
                   playImage.setOpacity(0)
                   playImageTimer.stop()
		       }
           },
           
           QTimer {
               id: pauseImageTimer
               singleShot: true
               interval: 1000
               onTimeout: {
                   pauseImage.setOpacity(0)
                   pauseImageTimer.stop()
		       }
           },
           
           OrientationHandler {
               onOrientationAboutToChange: {
                   if (orientation == UIOrientation.Landscape) {
                       
                       console.log("\n UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU \n")
                       
                       videoWindow.preferredWidth = appContainer.landscapeWidth
                       videoWindow.preferredHeight = appContainer.landscapeHeight
                   } else {
                       console.log("\n PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP \n")
                       videoWindow.preferredWidth = appContainer.landscapeHeight
                       videoWindow.preferredHeight = (appContainer.landscapeHeight * appContainer.landscapeHeight) / appContainer.landscapeWidth
                   }
               }
           }
           
        ] // Attached objects.
    
	    onCreationCompleted: {
	        OrientationSupport.supportedDisplayOrientation =
	            SupportedDisplayOrientation.All;
	            
            if (OrientationSupport.orientation == UIOrientation.Landscape) {
                videoWindow.preferredWidth = appContainer.landscapeWidth
                videoWindow.preferredHeight = appContainer.landscapeHeight
                
            } else {
                videoWindow.preferredWidth = appContainer.landscapeHeight
                videoWindow.preferredHeight = (appContainer.landscapeHeight * appContainer.landscapeHeight) / appContainer.landscapeWidth
                
            }
        }
	    
    }//appContainer
}// Page