import bb.cascades 1.0
import nuttyPlayer 1.0
import bb.multimedia 1.0

ListView {
    id: listView
    objectName: "listView"
    layout: GridListLayout {
        id: videoGridView
        columnCount: orientationHandler.orientation == UIOrientation.Portrait ? 2 : 4
    }
    horizontalAlignment: HorizontalAlignment.Center

    property bool released: true
    leadingVisualSnapThreshold: 0

    leadingVisual: PullToRefresh {
        id: refreshHandler
    }

    listItemComponents: [
        // define component which will represent list item GUI appearence
        ListItemComponent {
            Container{
	            ThumbnailItem {
	                imageSource: ListItemData.thumbURL
	                movieTitle: " " + ListItemData.title
	                movieLength: ListItemData.duration
	                isVideoBarItem: false
	            }
                opacity: 0.0

                onCreationCompleted: {
                    appear.play();
                }

                animations: [
                    FadeTransition {
                        id: appear
                        duration: 3000
                        easingCurve: StockCurve.CubicOut
                        fromOpacity: 0.0
                        toOpacity: 1.0
                    }
                ]
            }
        }
    ]

    onTouch: {
        if (event.touchType == TouchType.Down) {
            released = false;
        } else if (event.touchType == TouchType.Up) {
            released = true;
            
            if(refreshHandler.refreshMode > 0) {
                if(refreshHandler.refreshMode == 2)
                    infoListModel.updateVideoList2();
                
            	scrollToPosition(ScrollPosition.Beginning, ScrollAnimation.Smooth);
                refreshHandler.refreshMode = 0;
            }
            
        }
    }

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
            //variables for passing selected video path and length to videoScrollList
            var currentPath = listView.dataModel.data(indexPath).path;
            page.currentPath = currentPath;
            var currentLenght = listView.dataModel.data(indexPath).duration;
            page.currentLenght = currentLenght;
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
                    videoGridView.columnCount = 2
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
