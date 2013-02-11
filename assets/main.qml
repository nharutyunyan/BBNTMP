// Navigation pane with. The first page is the list view of videos. The second page is player view.
import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0

NavigationPane {
    id: navigationPane
    peekEnabled: false
    backButtonsVisible: false
Page {
    content: Container {
        layout: DockLayout {
        }
        ListView {
            id: listView
            objectName: "listView"
            horizontalAlignment: HorizontalAlignment.Center
            dataModel: InfoListModel {
                id: infoListModel
            }
        
            // Override default GroupDataModel::itemType() behaviour, which is to return item type "header"
            listItemComponents: [
                // define delegates for different item types here
                ListItemComponent {
                    // StandardListItem is a convivience component for lists with default cascades look and feel
                    StandardListItem {
                        //                    title: ListItemData.text
                        description: ListItemData.path
                        //                    status: ListItemData.status
                        //                    imageSource: ListItemData.image
                        imageSpaceReserved: true

                        // TODO Investigate how the metadata can be retrieved without playing the video.
                        //                    title: playerForMetadata.metaData.title
                    }
                }
            ] //listItemComponents
                onTriggered: {
                    clearSelection();
                    select(indexPath);
                }
                onSelectionChanged: {
                    // slot called when ListView emits selectionChanged signal
                    // A slot naming convention is used for automatic connection of list view signals to slots
                    if (selected) {
                        infoListModel.setSelectedIndex(listView.selectionList())
                        var page = getSecondPage();
                        console.debug("pushing detail " + page)
                        navigationPane.push(page);
                    }
                } // onSelectionChanged
                property Page secondPage
                function getSecondPage() {
                    if (! secondPage) {
                        secondPage = secondPageDefinition.createObject();
                    }
                    return secondPage;
                }
                attachedObjects: [
                    ComponentDefinition {
                        id: secondPageDefinition
                        source: "playerView.qml"
                    },
                    MediaPlayer {
                        id: playerForMetadata
                    }
                ]
            } // ListView
        } //Container
        onCreationCompleted: {
            // this slot is called when declarative scene is created
            // write post creation initialization here
            console.log("Page - onCreationCompleted()")

            // enable layout to adapt to the device rotation
            // don't forget to enable screen rotation in bar-bescriptor.xml (Application->Orientation->Auto-orient)
            OrientationSupport.supportedDisplayOrientation = SupportedDisplayOrientation.All;

            // Once this object is created, attach the signal to a Javascript function.
            application.manualExit.connect(onManualExit);
        }
        function onManualExit() {
            infoListModel.saveData();
            // This must exit the application.
            application.quit();
        }
    }
}
