import bb.cascades 1.0
import nuttyPlayer 1.0
import bb.multimedia 1.0

ListView {
    id: listView
    objectName: "listView"
    layout: GridListLayout {
        id: videoGridView
        columnCount: orientationHandler.orientation == UIOrientation.Portrait ? 3 : 4
        verticalCellSpacing: orientationHandler.orientation == UIOrientation.Landscape ? - 60 : 6
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
            console.log("pushing detail " + page)
            //variable for passing selected video path to videoScrollList
            var currentPath = listView.dataModel.data(indexPath).path;
            page.currentPath = currentPath;
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
            id: orientationHandler
            onOrientationAboutToChange: {
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
