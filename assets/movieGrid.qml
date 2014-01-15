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
        verticalCellSpacing: 5

    }
    horizontalAlignment: HorizontalAlignment.Center

    property Page videoPlayerPage
    property bool released: true
    property bool isMultiSelecting: false
    property bool displayRemoveMessage: false
    property bool displayHideMessage: false
    property bool deleteDialogShowing: false
    property bool allowLoadingVideo: true
    property string numberOfItems: ""
    property string currentAction: ""
    property bool isQ10: displayInfo.height == 720 ? true : false
    property variant copyOfSelectedIndexes
    leadingVisualSnapThreshold: 0

    property variant favorites: infoListModel.getFrameVideos()
    property string firstFolder: infoListModel.getFirstFolder()
    property int currentFrame: 0
    property bool checkForUpdateFrame: false
    property bool isRemovingFavorites: false
    property variant removingFromFavoritesIndexes
    
    multiSelectAction: MultiSelectActionItem {
    }

	function isInMovieGrid() {
        return (navigationPane.top == navigationPane.at(0)); 
    }	    
	
    function itemType(data, indexPath) {        
        listView.firstFolder = infoListModel.getFirstFolder();
        if(indexPath.length == 1) {
            return "header";
        }
        return "item";
	}

    function updateFavorites() {
        listView.favorites = infoListModel.getFrameVideos();
    }

    function openVideoPlayPage (path, duration){
        listView.selectAll();
        var indexes = listView.selectionList();
        listView.clearSelection();
        for (var i = indexes.length - 1; i >= 0; i --) {
            var data = listView.dataModel.data(indexes[i]);
            if (data.path == listView.favorites[listView.currentFrame]['path']) {
                infoListModel.setSelectedIndex(indexes[i]);
            }
        }

        var page = listView.getVideoPlayerPage();
        page.currentPath = path;
        page.currentLenght = duration;
        navigationPane.push(page);
    }

    // This function passes the selected videos to the C++ model.
    // I have no found how to send selectionList() in one shot, so i am passing all the
    // videos one by one and store them in the model for easier access.
    function passSelectionToModel() {
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

    function addToFavorites() {
        passSelectionToModel();
        var count = infoListModel.addToFavorites();
        if (count == 1) {
            numberOfItems = "1 item ";
        } else if (count > 1) {
            numberOfItems = count + " items ";
        }     
        if (count != 0) {
            currentAction = "added to Favorites.";
            gridToast.show();
        }
    }

    function removeFromFavorites() {
        infoListModel.clearSelected();
        for (var i = listView.removingFromFavoritesIndexes.length - 1; i >= 0; i --) {
            var index = listView.removingFromFavoritesIndexes[i];
            infoListModel.addToSelected(index);
        }
        var count = infoListModel.removeFromFavorites();
        listView.firstFolder = infoListModel.getFirstFolder();
        if (count == 1) {
            numberOfItems = "1 item ";
        } else if (count > 1) {
            numberOfItems = count + " items ";
        }
        if (count != 0) {
            currentAction = "removed from Favorites.";
            gridToast.show();
        }
        
    }

    function prepareToRemoveFromFavorites() {
        listView.removingFromFavoritesIndexes = listView.selectionList();
        listView.removingFromFavoritesIndexes.sort();        
        listView.isRemovingFavorites = true;
        listView.scrollToPosition(scrollStateHandler.atBeginning, ScrollAnimation.None);
    }

    function deleteVideos() {        
        var count = infoListModel.deleteVideos();        
        if (count == 1) {
            numberOfItems = "1 item ";
        } else if (count > 1) {
            numberOfItems = count + " items ";
        }
        if (count != 0) {
            currentAction = "deleted.";
            gridToast.show();
        }
    }

    function showDeleteDialog() {
        listView.deleteDialogShowing = true;
        deleteDialog.confirmButton.label = "Delete";
        deleteDialog.show();
    }

    function getFavorites() {
        return infoListModel.getFavorites();
    }

    // Shrinks the list of thumbnails so the context menu isn't on top of them during multi selection
    function offsetList(isOrientationPortrait) {
        var offset = listView.isMultiSelecting ? Helpers.widthOfContextMenu : 0;
        if (isOrientationPortrait)
            listView.preferredWidth = displayInfo.height - offset;
        else
            listView.preferredWidth = displayInfo.width - offset;
    }

    function favoriteIcon() {
        if (! listView.displayRemoveMessage)
            return  Helpers.favoriteIconAdd;
        return  Helpers.favoriteIconRemove; 
    }
    
    function getDisplayWidth() {
        return displayInfo.width;
    }
    
    function getDisplayHeight() {
        return displayInfo.height;
    }

    multiSelectHandler {
        actions: [
            // Add the actions that should appear on the context menu
            // when multiple selection mode is enabled
            ActionItem {
                id: multiShareOption
                title: qsTr("Share")
                imageSource: "asset:///images/GridView/ic_share.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                onTriggered: {
                    shareInvocation.query.data = "These movie are great: ";
                    for (var i = listView.copyOfSelectedIndexes.length - 1; i >= 0; i --) {
                        shareInvocation.query.data += infoListModel.data(listView.copyOfSelectedIndexes[i]).title
                        if (i != 0)
                            shareInvocation.query.data += ",  ";
                    }
                    shareInvocation.query.updateQuery()
                }
            },
            ActionItem {
                id: multiFavoriteOption
                title: listView.displayRemoveMessage ? "Remove from favorites" : "Add to favorites"                
                imageSource: favoriteIcon()
                onTriggered: {
                    if (listView.displayRemoveMessage) {                       
                        listView.prepareToRemoveFromFavorites();                        
                    } else {
                        listView.addToFavorites();
                    }                    
                    listView.updateFavorites();
                }
            },
            //            ActionItem {
            //                title: listView.displayHideMessage ? "Move to original folder" : "Move to hidden"
            //                id: multiHiddenOption
            //                imageSource: listView.isQ10 ? "asset:///images/GridView/hideIcon_Q10.png" : "asset:///images/GridView/hideIcon_Z10.png"
            //                onTriggered:{
            //                    listView.moveToFolder("9Hidden");
            //                }
            //            },
            DeleteActionItem {
                id: multiDeleteOption
                title: "Delete"
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
            if (! active)
                listView.allowLoadingVideo = true;
            offsetList(orientationHandler.orientation == UIOrientation.Portrait)
        }
        attachedObjects: [
            Invocation {
                id:shareInvocation
                query.mimeType: "text/plain"
                query.invokeActionId: "bb.action.SHARE"
                onArmed: {
                    if (query.data !="")
                    trigger("bb.action.SHARE")
                }
            }
        ]
    }

    listItemComponents: [
        ListItemComponent {
            type: "header" 
            Container {
                id: activeFrame
                Container {
                    id: frameContainer
                    property bool checkForUpdateFrame: activeFrame.ListItem.view.checkForUpdateFrame
                    onCheckForUpdateFrameChanged: {
                        if (frameContainer.visible) {
                            activeFrame.ListItem.view.updateFavorites();
                            activeFrame.ListItem.view.currentFrame = activeFrame.ListItem.view.currentFrame + 1;
                            if (activeFrame.ListItem.view.currentFrame > activeFrame.ListItem.view.favorites.length - 1) {
                                activeFrame.ListItem.view.currentFrame = 0;
                            }
                        }
                    }
                    visible: (activeFrame.ListItem.view.firstFolder == ListItemData) ? true : false
                    topPadding: 10
	                layout: DockLayout {
	                }
                    leftPadding: checkOrientation.orientation == UIOrientation.Portrait ? 0 : (activeFrame.ListItem.view.getDisplayWidth() - activeFrame.ListItem.view.getDisplayHeight())/2
                    Container {
                        layout: DockLayout {
                        }
	                    horizontalAlignment: HorizontalAlignment.Center
	                    verticalAlignment: VerticalAlignment.Center
	                    ImageView {
	                        id: frame
	                        implicitLayoutAnimationsEnabled: false
	                        imageSource: activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['thumbURL']
	                        scalingMethod: ScalingMethod.AspectFill
                            preferredWidth: activeFrame.ListItem.view.getDisplayHeight()          // 16x
                            preferredHeight: (activeFrame.ListItem.view.getDisplayHeight()*9)/16  // 9x
	                        gestureHandlers: [
	                            TapHandler {
	                                onTapped: {
	                                    if (!activeFrame.ListItem.view.isMultiSelecting) {
	                                    	var path = activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['path'];
                                        	var duration = activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['duration'];
                                        	activeFrame.ListItem.view.openVideoPlayPage(path, duration);
                                        }
                                    }
	                            }
	                        ]
	                    }
                        Container {
                           topPadding: 20
                           leftPadding: 20
                            ImageView {
                                imageSource: "asset:///images/GridView/new.png"
                                opacity: activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['isWatched'] ? 0 : 1
                                scaleX: 0.8
                                scaleY: 0.8
                            }
                       }
	                }
	                Container {
	                    verticalAlignment: VerticalAlignment.Bottom
	                    horizontalAlignment: HorizontalAlignment.Center
	                    background: titleBackground.imagePaint
	
	                    preferredHeight: 70
                        preferredWidth: activeFrame.ListItem.view.getDisplayHeight()
	                    rightPadding: 10  
	                    leftPadding: 10   
	
	                    Container {
	                        horizontalAlignment: HorizontalAlignment.Right
                            Label {
	                            id: length
	                            implicitLayoutAnimationsEnabled: false
	                            textStyle.fontSize: FontSize.XSmall
	                            text: Helpers.formatTime(activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['duration'])
	                            textStyle.color: Color.White
	                        }
	                    }
	                    Container {
	                        verticalAlignment: VerticalAlignment.Bottom
	                        horizontalAlignment: HorizontalAlignment.Fill
	                        Label {
	                            id: title
	                            implicitLayoutAnimationsEnabled: false
	                            horizontalAlignment: HorizontalAlignment.Right
	                            text: activeFrame.ListItem.view.favorites[activeFrame.ListItem.view.currentFrame]['title']
	                            textStyle.color: Color.White
	                            textStyle.fontSize: FontSize.Medium
	                        }
	                    }
	                }
                }
                Container {
                    Container {
                        leftPadding: 5
                        Label {
                            text: qsTr(ListItemData).substring(1, ListItemData.toString().length)
                            textStyle.color: Color.create("#dddddd")
                        }
                        Container {
                            minHeight: 3
                            background: Color.create("#ff8811")
                            Divider {
                            }
                        }
                    }
                }

                attachedObjects: [
                    ImagePaintDefinition {
                        id: titleBackground
                        imageSource: "asset:///images/GridView/TimeFrame.png"
                    },
                    OrientationHandler {
                        id: checkOrientation
                    }
                ]

                function updateActiveFrame() {
                    activeFrame.ListItem.view.updateFavorites();
                    updateFrame.start();
                }
            }
        }, 
        ListItemComponent {
            type: "item"
            Container {
                id: itemRoot
                contextMenuHandler: ContextMenuHandler {
                    id: myContext
                    objectName: "contextHandlerObj"
                    onPopulating: {
                        if (!itemRoot.ListItem.view.isInMovieGrid()) {
                            event.abort();
                        }
                    }
                    onVisualStateChanged: {
                        if (myContext.visualState == ContextMenuVisualState.Hidden || myContext.visualState == ContextMenuVisualState.AnimatingToHidden) 
                        	itemRoot.ListItem.view.allowLoadingVideo = true;
                        else 
                        	itemRoot.ListItem.view.allowLoadingVideo = false;
                    }
                }
                ThumbnailItem {
                    imageSource: ListItemData.thumbURL
                    movieTitle: " " + ListItemData.title
                    movieLength: ListItemData.duration
                    isVideoBarItem: false
                    isWatched: ListItemData.isWatched
                    haveSubtitle: ListItemData.haveSubtitle
                }
                opacity: 0.0

                onCreationCompleted: {
                    appear.play();
                }
                gestureHandlers: [
                    LongPressHandler {
                        onLongPressed: {
                            if(ListItemData.folder == "0Favorites")
                            {
                                individualFavoriteOption.imageSource = Helpers.favoriteIconRemove;    
                            }
                            else 
                            {
                                individualFavoriteOption.imageSource = Helpers.favoriteIconAdd;
                                var favorites = itemRoot.ListItem.view.getFavorites();
                                for (var i = 0; i < favorites.length; ++i) {
                                    if (favorites[i]["path"] == ListItemData.path) {
                                        individualFavoriteOption.imageSource = Helpers.favoriteIconRemove;
                                        break;
                                    }
                                }                                
                            }                         
                       }
                    }
                ]
                attachedObjects: [
                    ImagePaintDefinition {
                        id: frameImage
                        imageSource: "asset:///images/selected_frame.png"
                    }
                ]
                
                background: itemRoot.ListItem.selected ? frameImage.imagePaint : Color.Transparent

                onTouch: {
                    if (event.touchType == TouchType.Down)
                        sinkIn.play();
                    else if (event.touchType == TouchType.Cancel || event.touchType == TouchType.Up)
                        popOut.play();
                }

                contextActions: [
                    ActionSet {
                        title: ListItemData.title
                        subtitle: Helpers.formatTime(ListItemData.duration)

                        actions: [
                            InvokeActionItem {
                                title: qsTr("Share")
                                ActionBar.placement: ActionBarPlacement.OnBar
                                query {
                                    mimeType: "text/plain"
                                    invokeActionId: "bb.action.SHARE"
                                }
                                onTriggered: {
                                    data = " This movie is great: " + ListItemData.title;
                                }
                            },
                            ActionItem {
                                title: itemRoot.ListItem.view.displayRemoveMessage ? "Remove from favorites" : "Add to favorites"
                                id: individualFavoriteOption
                                onTriggered: {
                                    if (itemRoot.ListItem.view.displayRemoveMessage) {
                                        //itemRoot.ListItem.view.prepareToRemoveFromFavorites();
                                        itemRoot.ListItem.view.removingFromFavoritesIndexes = itemRoot.ListItem.view.selectionList();
                                        itemRoot.ListItem.view.removeFromFavorites();                                        
                                    } else {
                                        itemRoot.ListItem.view.addToFavorites();
                                    }
                                    itemRoot.ListItem.view.updateFavorites();
                                }
                            },
                            //                            ActionItem {
                            //                                title: itemRoot.ListItem.view.displayHideMessage ? "Move to original folder" : "Move to hidden"
                            //                                id: individualHiddenOption
                            //                                imageSource: itemRoot.ListItem.view.isQ10 ? "asset:///images/GridView/hideIcon_Q10.png" : "asset:///images/GridView/hideIcon_Z10.png"
                            //                                onTriggered:{
                            //                                    itemRoot.ListItem.view.moveToFolder("9Hidden");
                            //                                }
                            //                            },
                            DeleteActionItem {
                                title: "Delete"
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
                        id: sinkIn
                        toX: 0.95
                        toY: 0.95
                        easingCurve: StockCurve.Linear
                        duration: 100
                    },
                    ScaleTransition {
                        id: popOut
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
        if (selected) { 
            var allSelected = listView.selectionList();
            for (var i = listView.selectionList().length - 1; i >= 0; i --) {
                if (allSelected[i].length == 1) {
                    listView.toggleSelection(allSelected[i]);
                }
            }         
        }
     
        // Don't load a video if a context menu is showing
        if (listView.allowLoadingVideo) {
            // slot called when ListView emits selectionChanged signal
            // A slot naming convention is used for automatic connection of list view signals to slots
            if (selected && listView.selected().length != 1) {
                infoListModel.setSelectedIndex(listView.selected())
                infoListModel.prepareForPlay(infoListModel.getSelectedIndex());
                if(videoPlayerPage) {
                    HDMIPlayer.stop();
                    videoPlayerPage.startListening = false
                    videoPlayerPage.destroy();
                    videoPlayerPage = null;
                }
                var page = getVideoPlayerPage();
                console.log("pushing detail " + page)
                //variables for passing selected video path and length to videoScrollList
                var currentPath = listView.dataModel.data(indexPath).path;
                page.currentPath = currentPath;
                var currentLenght = listView.dataModel.data(indexPath).duration;
                page.currentLenght = currentLenght;
                if(HDMIScreen.connection) {
                    nowPlayingBar.playerPage = page;
                }
                navigationPane.push(page);
                Application.setMenuEnabled(false);
                clearSelection();
            }
        }

        // change label and/or enability of favorite context menu item depending on selection
        if (! listView.deleteDialogShowing) {
            listView.passSelectionToModel();
            var visibility = infoListModel.getButtonVisibility("0Favorites");
            switch (visibility) {
                // Both non-favs and favs selected
                case 0:
                    {
                        multiFavoriteOption.enabled = true;
                        listView.displayRemoveMessage = false;
                        break;
                    }
                case 1:
                    {
                        multiFavoriteOption.enabled = true;
                        listView.displayRemoveMessage = false;
                        break;
                    }
                case 2:
                    {
                        multiFavoriteOption.enabled = true;
                        listView.displayRemoveMessage = true;
                        break;
                    }
            }
            if (!listView.displayRemoveMessage) {
	            var favorites = listView.getFavorites();
	            var selectedVideos = listView.selectionList();
	            for (var j = 0; j < selectedVideos.length; ++j) {
	                var data = listView.dataModel.data(selectedVideos[j]);               
	                var isFavorite = false; 
	                for (var i = 0; i < favorites.length; ++i) {
	                    if (favorites[i]["path"] == data.path) {
	                        isFavorite = true;
	                        break;
	                    }
	                }
	                if (!isFavorite) {
	                   	break;
	                } else if (j == selectedVideos.length - 1) {
                        listView.displayRemoveMessage = true;
	                }                   
	            }           
            }          
            
            //            visibility = infoListModel.getButtonVisibility("9Hidden");
            //            switch (visibility) {
            //                case 0:
            //                    {
            //                        multiHiddenOption.enabled = false;
            //                        break;
            //                    }
            //                case 1:
            //                    {
            //                        multiHiddenOption.enabled = true;
            //                        listView.displayHideMessage = false;
            //                        break;
            //                    }
            //                case 2:
            //                    {
            //                        multiHiddenOption.enabled = true;
            //                        listView.displayHideMessage = true;
            //                        break;
            //                    }
            //            }
        }

        // Display on the screen number of selected items
        if (selectionList().length > 1) {
            multiSelectHandler.status = selectionList().length + " items selected";
            numberOfItems = selectionList().length + " items ";
            multiShareOption.enabled = true;
            multiDeleteOption.enabled = true;
        } else if (selectionList().length == 1) {
            multiSelectHandler.status = "1 item selected";
            numberOfItems = "1 item ";
            multiShareOption.enabled = true;
            multiDeleteOption.enabled = true;
        } else {
            multiSelectHandler.status = "None selected";
            // Technically the selection is already empty, but calling this method
            // seems to ensure that the context menu is in the correct state (hidden)
            multiFavoriteOption.enabled = false;
            multiShareOption.enabled = false;
            multiDeleteOption.enabled = false;
            clearSelection();
        }

    } // onSelectionChanged

    function getVideoPlayerPage() {
        if (! videoPlayerPage) {
            videoPlayerPage = playerPageDef.createObject();
        }
        return videoPlayerPage;
    }

    onCreationCompleted: {
        updateFrame.start();
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
                
                var allSelected = listView.selectionList();
                if (allSelected.length > 0) {
                    listView.scrollToItem(allSelected[0],ScrollAnimation.None);
                } else {
                    listView.scrollToItem(scrollStateHandler.firstVisibleItem, ScrollAnimation.None);                    
                }
                offsetList(orientationHandler.orientation != UIOrientation.Portrait);
            }
        },
        ListScrollStateHandler {
            id: scrollStateHandler
            onAtBeginningChanged: {
                if (listView.isRemovingFavorites) {
                    listView.removeFromFavorites();
                    listView.isRemovingFavorites = false;
                }                
            }
        },
        ComponentDefinition {
            id: playerPageDef
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
            body: numberOfItems + currentAction
            position: SystemUiPosition.MiddleCenter
        },
        QTimer {
            id: updateFrame
            singleShot: false
            interval: 4000
            onTimeout: {
                listView.checkForUpdateFrame = ! listView.checkForUpdateFrame;
            }
        }
    ]
}// ListView
