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
        } //Container
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
        }
        function onManualExit() {
            infoListModel.setVideoPosition(mainPage.currentMoviePosition);
            infoListModel.saveData();
            // This must exit the application.
            application.quit();
        }
    }
}
