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
                id :movieGridPage
                layout: StackLayout{}

				// Add container to prevent white-background bug on z10
				Container {
                    ImageView {
                        id: headerImage
                        imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
                        onTouch: {
                            // TODO : Code for issue 14?
                        }
                    }
                }

                Container {
                    id: movieGridContainer
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


                } //moviegrid Container  
            } //moviegridPage Container

			// I can't manage to translate it 72 units from the top without making another container
			Container{
			    topPadding:72
                ImageView {
                    id: headerShadow
                    imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/shadow.png" : "asset:///images/shadow_landscape.png"
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
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
            }
        ]
    }
}
