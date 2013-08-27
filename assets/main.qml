// Navigation pane with. The first page is the list view of videos. The second page is player view.
import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0
import "helpers.js" as Helpers

NavigationPane {
    id: navigationPane
    peekEnabled: false
    backButtonsVisible: false
    Page {
        id : mainPage
        property variant currentMoviePosition;
        content: Container {
            id: globalContainer
            layout: DockLayout{}
		        
                Container {
                id: movieGridPage
                layout: StackLayout{}

				Container {
                    layout: DockLayout {
                    }
                    ImageView {
                        id: headerImage
                        imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
                    }
                    Container {
                        verticalAlignment: VerticalAlignment.Top
                        horizontalAlignment: HorizontalAlignment.Right
                        topPadding: 3
                        ImageButton {
                            id: info
                            defaultImageSource: "asset:///images/appInfo.png"
                            onClicked : {
                                linkInvocation.trigger("bb.action.OPEN");
                            }
                            attachedObjects: [
                                Invocation {
                                    id: linkInvocation
                                    query {
                                        uri: "http://www.macadamian.com/"
                                   }
                                }
                            ]
                        }
                    }
                }

                Container {
                    layout: DockLayout {
                    }

                    Container {
                        id: movieGridContainer
                        topPadding: 10
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
                    ImageView {
                        id: headerShadow
                        imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/shadow.png" : "asset:///images/shadow_landscape.png"
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Top
                    }
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
        
        property variant movieGridObj;
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
}
