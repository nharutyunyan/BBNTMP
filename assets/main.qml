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
        
        Container {
            id: contentContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom
            
            layout: DockLayout {}
            
	        preferredWidth:  appContainer.landscapeWidth
	        preferredHeight: appContainer.landscapeHeight 
	        
	        onTouch: {
	        	if (event.touchType == TouchType.Down)
	        	{
	        	     appContainer.touchPositionX =  event.localX;
	        	     appContainer.touchPositionY =  event.localY;
	            }
	            else if (event.touchType == TouchType.Up)
	            {
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
            
	        ForeignWindowControl {
                id: videoWindow
                objectName: "VideoWindow"
                windowId: "VideoWindow"
	                
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