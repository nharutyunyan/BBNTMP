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
    property bool displayRemoveMessage: false
    property bool displayHideMessage: false
    property bool deleteDialogShowing : false
    property bool allowLoadingVideo : true
    property string numberOfItems: ""
    property string currentAction: ""
    property variant copyOfSelectedIndexes
    leadingVisualSnapThreshold: 0


	// Expose the menu to the rest of the application to check if it's open
    contextMenuHandler: ContextMenuHandler {
        id: myContext
        objectName:"contextHandlerObj"
        onVisualStateChanged:{
            if (myContext.visualState == ContextMenuVisualState.Hidden || myContext.visualState == ContextMenuVisualState.AnimatingToHidden)
            	allowLoadingVideo = true;
            else
            	allowLoadingVideo = false;
        }
    }
    multiSelectAction: MultiSelectActionItem {
    }

	// This function passes the selected videos to the C++ model.
	// I have no found how to send selectionList() in one shot, so i am passing all the 
	// videos one by one and store them in the model for easier access.
	function passSelectionToModel()
	{
	    // Make a copy to sort the array
        listView.copyOfSelectedIndexes = listView.selectionList();
        // Passing the indexes in descending order is important to
        // avoid invalidation of indexes during deletion of files
        listView.copyOfSelectedIndexes.sort();
        
        infoListModel.clearSelected();
        for (var i = listView.copyOfSelectedIndexes.length - 1; i >= 0; i --) {
            var index = listView.copyOfSelectedIndexes[i];
            infoListModel.addToSelected(index);
        }
    }

	function moveToFolder(folderName) {
        passSelectionToModel();
        if (folderName == infoListModel.value(listView.selected(), "folder")) 
        	currentAction = "removed from " + folderName.substr(1).toLowerCase() + ".";
        else 
        	currentAction = "added to " + folderName.substr(1).toLowerCase() + ".";
        infoListModel.toggleFolder(folderName);
        gridToast.show();
    }


    function deleteVideos() {
        currentAction = "deleted."
        infoListModel.deleteVideos();
        gridToast.show();
    }
    
    function showDeleteDialog()
    {
        listView.deleteDialogShowing = true;
        deleteDialog.confirmButton.label = "Delete";
        deleteDialog.show();
    }
    
    // Shrinks the list of thumbnails so the context menu isn't on top of them during multi selection
	function offsetList(isOrientationPortrait){
	    var offset = listView.isMultiSelecting ? Helpers.widthOfContextMenu : 0;
        if (isOrientationPortrait)
            listView.preferredWidth = displayInfo.height - offset;
        else
            listView.preferredWidth = displayInfo.width - offset;
    }

    multiSelectHandler {
        actions: [
            // Add the actions that should appear on the context menu
            // when multiple selection mode is enabled
            ActionItem {
                title: listView.displayRemoveMessage ? "Remove from favorites" : "Add to favorites"
                id: multiFavoriteOption
                //imageSource: "asset:///images/Favorite.png"
                onTriggered:{
                    listView.moveToFolder("0Favorites");
                }
            },
            ActionItem {
                title: listView.displayHideMessage ? "Move to original folder" : "Move to hidden"
                id: multiHiddenOption
                onTriggered:{
                    listView.moveToFolder("9Hidden");
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
            listView.isMultiSelecting = active;
            // Sometimes, the visualstate of myContext does not get updated correctly.
            // So we allow loading of videos after multi-select is cancelled as well
            if (!active)
            	listView.allowLoadingVideo = true;
            offsetList(orientationHandler.orientation == UIOrientation.Portrait)
        }
    }

    listItemComponents: [
        ListItemComponent {
            type: "header"
            Container{
                leftPadding: 5
	            Label {
	                text: qsTr(ListItemData).substring(1, ListItemData.toString().length)
	                textStyle.color: Color.create("#dddddd")
	            }
	            Container{
	                minHeight:3
	                background: Color.create("#ff8811")
	                Divider{}
	            }
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
                
                attachedObjects:[
                    ImagePaintDefinition {
                        id: frameImage
                        imageSource: "asset:///images/selected_frame.png"
                    }
                ]
                background: itemRoot.ListItem.selected ? frameImage.imagePaint : Color.Transparent
                
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
                                title: itemRoot.ListItem.view.displayRemoveMessage ? "Remove from favorites" : "Add to favorites"
                                //To do if UX design needs image here
                                //imageSource: "asset:///images/Favorite.png"
                                onTriggered: {
                                    itemRoot.ListItem.view.moveToFolder("0Favorites");
                                }
                            },
                            ActionItem {
                                title: itemRoot.ListItem.view.displayHideMessage ? "Move to original folder" : "Move to hidden"
                                id: individualHiddenOption
                                onTriggered:{
                                    itemRoot.ListItem.view.moveToFolder("9Hidden");
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
        if (listView.allowLoadingVideo) 
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
            numberOfItems = selectionList().length + " items ";
        } else if (selectionList().length == 1) {
            multiSelectHandler.status = "1 item selected";
            numberOfItems = "1 item ";
        } else {
            multiSelectHandler.status = "None selected";
            // Technically the selection is already empty, but calling this method 
            // seems to ensure that the context menu is in the correct state (hidden)
            clearSelection();
        }

        if (! listView.deleteDialogShowing) {
            listView.passSelectionToModel();
            var visibility = infoListModel.getButtonVisibility("0Favorites");
            multiFavoriteOption.enabled = visibility;
            
            multiHiddenOption.enabled = infoListModel.getButtonVisibility("9Hidden");
        }
            // change label and/or enability of favorite context menu item depending on selection
        if (!listView.deleteDialogShowing)
        {
	        listView.passSelectionToModel();
	        var visibility = infoListModel.getButtonVisibility("0Favorites");
	        switch (visibility){
	            // Both non-favs and favs selected
	        	case 0:{
	                multiFavoriteOption.enabled = false;
	        	    break;
	        	}
	        	case 1:{
	                multiFavoriteOption.enabled = true;
	                listView.displayRemoveMessage = false;
                    break;
	            }
	        	case 2:{
	                multiFavoriteOption.enabled = true;
	                listView.displayRemoveMessage = true;
                    break;
	            }
	        }
            visibility = infoListModel.getButtonVisibility("9Hidden");
            switch (visibility){
                case 0:{
                    multiHiddenOption.enabled = false;
                    break;
                }
                case 1:{
                    multiHiddenOption.enabled = true;
                    listView.displayHideMessage = false;
                    break;
                }
                case 2:{
                    multiHiddenOption.enabled = true;
                    listView.displayHideMessage = true;
                    break;
                }
            }     
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
                offsetList(orientationHandler.orientation != UIOrientation.Portrait);
            }
        },
        ComponentDefinition {
            id: secondPageDefinition
            source: "playerView.qml"
        },
        MediaPlayer {
            id: videoListScrollBar
        },
        SystemDialog {
            id: deleteDialog
            title: "File deletion..."
            body: "Are you sure you want to delete file(s)?"
            onFinished: {
               if (deleteDialog.result == SystemUiResult.ConfirmButtonSelection) 
                	listView.deleteVideos();
                listView.deleteDialogShowing = false;
            }
        },
        SystemToast {
            id: gridToast
            body: numberOfItems+currentAction
            position: SystemUiPosition.BottomCenter
        }
    ]
} // ListView
