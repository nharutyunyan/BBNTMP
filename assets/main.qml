import bb.cascades 1.0

import bb.multimedia 1.0

Page {
    Container {
        id: appContainer
        background: Color.create("#ff262626")
        
        layout: DockLayout {
        }
        
        property bool changeVideoPosition : true 
        Container {
            id: contentContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Bottom
            
            layout: DockLayout {}
            
                ForeignWindowControl {
                    id: videoWindow
                    objectName: "VideoWindow"
                    windowId: "VideoWindow"
                   
				    gestureHandlers: [
				        TapHandler {
				            onTapped: {
				                if(myPlayer.mediaState == MediaState.Started) {
	                                myPlayer.pause();
	                            }
	                            else if(myPlayer.mediaState == MediaState.Paused) {
	                                myPlayer.play();
	                            }

				            }
				        }
				    ]
				                       
                    preferredWidth:  1280
                    preferredHeight: 768
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
                    fromValue: 0.00000000
                    toValue: 1.00000000
                    enabled: false
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Bottom
                    
                    layoutProperties: StackLayoutProperties {
                        spaceQuota: 1
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
	                            myPlayer.pause();
	                        }
	                        else if(myPlayer.mediaState == MediaState.Paused) {
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
                
            }
            
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
               interval: 300
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
           }
           
        ] // Attached objects.
    
    }//appContainer
}// Page