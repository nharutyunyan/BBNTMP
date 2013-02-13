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
        background: Color.create("#ff262626")        
        layout: DockLayout {
        }
        ListView {
            id: listView
            objectName: "listView"
            layout: GridListLayout {}            
            horizontalAlignment: HorizontalAlignment.Center
            dataModel: InfoListModel {
                id: infoListModel
            }
        
                listItemComponents: [
                    // define component which will represent list item GUI appearence
                    ListItemComponent {
                        Container {
                            //Custom item for Grid view - can be modified later
                            verticalAlignment: VerticalAlignment.Fill
                            horizontalAlignment: HorizontalAlignment.Fill
                            // show image
                            ImageView {
                                imageSource: ListItemData.thumbURL
                                scalingMethod: ScalingMethod.AspectFit
                                layoutProperties: StackLayoutProperties {
                                    spaceQuota: 1.0
                                }
                                horizontalAlignment: HorizontalAlignment.Center
                                verticalAlignment: VerticalAlignment.Center
                            }
                            //and text below
                            Label {
                                text: ListItemData.title
                                textStyle.color: Color.White
                                textStyle.base: SystemDefaults.TextStyles.SmallText
                                horizontalAlignment: HorizontalAlignment.Center
                            }
                        }
                    }
                ]
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
