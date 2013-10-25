// Navigation pane with. The first page is the list view of videos. The second page is player view.
import bb.cascades 1.0
import bb.multimedia 1.0
import bb.system 1.0
import nuttyPlayer 1.0
import system 1.0
import "helpers.js" as Helpers


NavigationPane {
    id: navigationPane
    peekEnabled: false
    Menu.definition: AppMenu {
    }
    Page {
        id: mainPage
        property variant currentMoviePosition
        content: Container {
            id: globalContainer
            layout: DockLayout {
            }

            Container {
                id: movieGridPage
                layout: StackLayout {
                }

                Container {
                    layout: DockLayout {
                    }
                    ImageView {
                        id: headerImage
                        imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
                    }
                }

                Container {
                    layout: DockLayout {
                    }

                    Container {
                        id: movieGridContainer
                        objectName: "movGrid_obj"
                        visible: true
                        layout: DockLayout {
                        }
                        attachedObjects: [
                            ComponentDefinition {
                                id: movieGrid
                                source: "movieGrid.qml"
                            },
                            ImagePaintDefinition {
                                id: backgroundImage
                                imageSource: "asset:///images/Player/VideoBG.png"
                            }
                        ]
                        background: backgroundImage.imagePaint
                    }
                    Container {
                        id: noVidContainer
                        objectName: "noVidLabel_obj"
                        visible: true
                        rightPadding: 17
                        leftPadding: 17
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Center

                        Label {
                            id: noVidLabel
                            textStyle.textAlign: TextAlign.Center
                            text: "No video files found.\n All video files from Videos, Downloads and Camera directories will be shown here.\n\n If you have video files but can't see them there might be problem with permissions. To check the settings"
                            textStyle.color: Color.White
                            multiline: true
                            preferredWidth: 700
                            verticalAlignment: VerticalAlignment.Center
                            horizontalAlignment: HorizontalAlignment.Center
                        }
                        
                        Label {
                            id: link
                            text: "Click Here"
                            textStyle.color: Color.create("#33CCFF")
                            textStyle.textAlign: TextAlign.Center
                            verticalAlignment: VerticalAlignment.Center
                            horizontalAlignment: HorizontalAlignment.Center
                            
                            onTouch: {
                               textStyle.color = Color.create("#1A6680");
                               linkAnimation.start();  
                           }
                           
                           attachedObjects: [
                               System {
                                   id: system
                               },  
                               QTimer {
                                   id: linkAnimation
                                   singleShot: true
                                   interval: 70
                                   onTimeout: {
                                       link.textStyle.color = Color.create("#33CCFF");

                                       if(!system.OpenSettings())
                                       		error.show();
                                   }
                               },
                               SystemToast {
                                   id: error
                                   body: "Unkown error occured."
                                   position: SystemUiPosition.MiddleCenter
                               }
                           ]
                        } 
                    }

                    
                    ImageView {
                        id: headerShadow
                        objectName: "headShad_obj"
                        visible: true
                        imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/shadow.png" : "asset:///images/shadow_landscape.png"
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Top
                    }
                }
                NowPlaying {
                    id: nowPlayingBar
                    // If the video is playing on the 2nd screen,
                    // this display the information
                }
            }

            // Busy indicator when thumbs are loading, on top of the grid
            ActivityIndicator {
                id: loadingIndicator
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                objectName: "LoadingIndicator"
                preferredWidth: 250
            }
        } // global container

        property variant movieGridObj
        onCreationCompleted: {
            // this slot is called when declarative scene is created
            // write post creation initialization here
            console.log("Page - onCreationCompleted()")
            if (! movieGridObj)
                movieGridObj = movieGrid.createObject();
            movieGridObj.dataModel = infoListModel.get();
            movieGridContainer.add(movieGridObj);
            // enable layout to adapt to the device rotation
            // don't forget to enable screen rotation in bar-bescriptor.xml (Application->Orientation->Auto-orient)
            OrientationSupport.supportedDisplayOrientation = SupportedDisplayOrientation.All;

            // Once this object is created, attach the signal to a Javascript function.
            application.manualExit.connect(onManualExit);
            settings.setValue("inPlayerView", false);
        }
        function onManualExit() {
            infoListModel.setVideoPosition(mainPage.currentMoviePosition);
            infoListModel.saveData();
            // This must exit the application.
            application.quit();
        }

        attachedObjects: [
            OrientationHandler {
                id: orientationHandlerMain
                onOrientationAboutToChange: {
                    headerImage.imageSource = orientationHandlerMain.orientation != UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
                    headerShadow.imageSource = orientationHandlerMain.orientation != UIOrientation.Portrait ? "asset:///images/shadow.png" : "asset:///images/shadow_landscape.png"
                }
            },
            Settings {
                id: settings
            }
        ]
    }
    onPopTransitionEnded: {
        Application.setMenuEnabled(true)
        if(mainPage.movieGridObj.secondPage)
            mainPage.movieGridObj.secondPage.popPage()
    }
}
