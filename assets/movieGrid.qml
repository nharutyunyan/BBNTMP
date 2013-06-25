import bb.cascades 1.0
import nuttyPlayer 1.0
import bb.multimedia 1.0

ListView {
    id: listView
    objectName: "listView"
    layout: GridListLayout {
        id: videoGridView
    }
    horizontalAlignment: HorizontalAlignment.Center
    listItemComponents: [
        // define component which will represent list item GUI appearence
        ListItemComponent {
            Container{
	            ThumbnailItem {
	                imageSource: ListItemData.thumbURL
	                movieTitle: ListItemData.title
	                movieLength: ListItemData.duration
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
        OrientationHandler {
            onOrientationChanged: {
                // can update the UI after the orientation changed
                if (orientation == UIOrientation.Portrait) {
                    // make some ui changes related to portrait
                    videoGridView.columnCount = 3
                } else if (orientation == UIOrientation.Landscape) {
                    // make some ui changes related to landscape
                    videoGridView.columnCount = 4
                }
            }
        },
        ComponentDefinition {
            id: secondPageDefinition
            source: "playerView.qml"
        },
        MediaPlayer {
            id: videoListScrollBar
        }
    ]
} // ListView
