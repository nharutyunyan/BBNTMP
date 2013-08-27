import bb.cascades 1.0
import nuttyPlayer 1.0
import bb.multimedia 1.0
import bb.system 1.0
import "helpers.js" as Helpers

ListView {
    id: listView
    objectName: "listView"
    dataModel: GroupDataModel {
    }
    layout: GridListLayout {
        id: videoGridView
        headerMode: ListHeaderMode.Standard
        columnCount: orientationHandler.orientation == UIOrientation.Portrait ? 2 : 4
        spacingAfterHeader: 5
        verticalCellSpacing: 0
    }
    horizontalAlignment: HorizontalAlignment.Center

    property bool released: true
    property bool isMultiSelecting: false
    property variant copyOfSelectedIndexes
    leadingVisualSnapThreshold: 0


	// Expose the menu to the rest of the application to check if it's open
    contextMenuHandler: ContextMenuHandler {
        id: myContext
    }
    multiSelectAction: MultiSelectActionItem {
    }

	function addVidsToFavorites(){
	    for (var i = 0; i < listView.selectionList().length;i++){
	        var index = listView.selectionList()[i];
            infoListModel.setValue(index, "folder", "favorites");
        }
        infoListModel.saveData();
	}

    function addVidsToRemoved(selected) {
        for (var i = 0; i < selected.length; i++) {
            var index = selected[i];
            infoListModel.addVideoToRemoved(index);
        }
        infoListModel.saveData();
    }
    
    function deleteVideos(selected) {
        for (var i = selected.length-1; i >= 0; i--) {
            var index = selected[i];
            infoListModel.deleteVideos(index);
        }
        infoListModel.saveData();
    }
    
    function showDeleteDialog()
    {
        // When confirmation dialog gains focus, selection is cleared, thus we must copy it first
        listView.copyOfSelectedIndexes = listView.selectionList();
        // We must sort the list to delete files in descending order.  Otherwise deleting an earlier index invalidates all later indexes
        listView.copyOfSelectedIndexes.sort();
        deleteDialog.showCustom("Delete from device","Move to hidden","Cancel");
    }
    
    // Shrinks the list of thumbnails so the context menu isn't on top of them during multi selection
	function offsetListBy(offset){
	    if (orientationHandler.orientation == UIOrientation.Portrait)
            listView.preferredWidth = displayInfo.width - offset;
        else
        	listView.preferredWidth = displayInfo.Height - offset;
    }

    multiSelectHandler {
        actions: [
            // Add the actions that should appear on the context menu
            // when multiple selection mode is enabled
            ActionItem {
                title: "Add to favorites"
                //imageSource: "asset:///images/Favorite.png"
                onTriggered:{
                    listView.addVidsToFavorites();
                }
            },
            ActionItem {
                title: "Delete"
                //imageSource: "asset:///images/Delete.png"
                onTriggered: {
                   listView.showDeleteDialog();
                }
            }
        ]

        // Set the initial status text of multiple selection mode. 
        status: "None selected"
        onActiveChanged: {
            if (active==true)
               listView.offsetListBy(Helpers.widthOfContextMenu);
           else
               listView.offsetListBy(0);           
        }
    }

    listItemComponents: [
        ListItemComponent {
            type: "header"
            Header {
                title: qsTr(ListItemData).substring(1, ListItemData.toString().length)
            }
        },

        ListItemComponent {
            type: "item"
            Container{
                id: itemRoot
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
                background: itemRoot.ListItem.selected ? Color.Cyan : Color.Transparent
                onTouch: {
                    if (event.touchType == TouchType.Down) 
                    	sinkIn.play();
                    else if(event.touchType == TouchType.Cancel || event.touchType == TouchType.Up)
                    	popOut.play();
                }
                
                contextActions: [
                    ActionSet {
                        title: "Menu Action Set"
                        subtitle: "Menu Action Set."

                        actions: [
                            ActionItem {
                                title: "Add to favorites"
                                //To do if UX design needs image here
                                //imageSource: "asset:///images/Favorite.png"
                                onTriggered: {
                                    itemRoot.ListItem.view.addVidsToFavorites();
                                }
                            },
                            ActionItem {
                                 title: "Delete"
                                 //To do if UX design needs image here
                                 //imageSource: "asset:///images/Delete.png"
                                 onTriggered: {
                                    itemRoot.ListItem.view.showDeleteDialog();
                                }
                            }
                        ]                   
                    } // end of ActionSet
                ] // end of contextActions list

                animations: [
                    FadeTransition {
                        id: appear
                        duration: 3000
                        easingCurve: StockCurve.CubicOut
                        fromOpacity: 0.0
                        toOpacity: 1.0
                    },
                    //This makes the thumbnail "sink in" when tapped before loading the video
                    ScaleTransition {
                        id : sinkIn                    
                        toX: 0.95
                        toY: 0.95
                        easingCurve: StockCurve.Linear
                        duration: 100
                    },
                    ScaleTransition {
                        id : popOut
                        fromX: 0.95
                        fromY: 0.95
                        toX: 1
                        toY: 1
                        easingCurve: StockCurve.Linear
                        duration: 100
                    }
                ]
            }
        }
    ]

    onTriggered: {
        clearSelection();
        select(indexPath);
    }
    onSelectionChanged: {
        // Don't load a video if a context menu is showing
        if (myContext.visualState == ContextMenuVisualState.Hidden) 
        {
	        // slot called when ListView emits selectionChanged signal
	        // A slot naming convention is used for automatic connection of list view signals to slots
	        if (selected) {
	            infoListModel.setSelectedIndex(listView.selected())
	            var page = getSecondPage();
	            console.log("pushing detail " + page)
	            //variables for passing selected video path and length to videoScrollList
	            var currentPath = listView.dataModel.data(indexPath).path;
	            page.currentPath = currentPath;
	            var currentLenght = listView.dataModel.data(indexPath).duration;
	            page.currentLenght = currentLenght;
	            navigationPane.push(page);
	            clearSelection();
	        }
        }
        
        // Display on the screen number of selected items
        if (selectionList().length > 1) {
            multiSelectHandler.status = selectionList().length + " items selected";
        } else if (selectionList().length == 1) {
            multiSelectHandler.status = "1 item selected";
        } else {
            multiSelectHandler.status = "None selected";
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
        },
        CustomDialog {
            id: deleteDialog
            title: "File deletion..."
            body: "Are you sure you want to remove file(s)?"
            onFinished: {
                if (deleteDialog.result == SystemUiResult.CustomButtonSelection) 
                	listView.addVidsToRemoved(listView.copyOfSelectedIndexes);
                else if (deleteDialog.result == SystemUiResult.ConfirmButtonSelection) 
                	listView.deleteVideos(listView.copyOfSelectedIndexes);
            }
        }
    ]
} // ListView
