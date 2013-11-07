import bb.cascades 1.0
import nuttyPlayer 1.0
import "helpers.js" as Helpers

Container {
    id: videoList
    background: Color.Black
    preferredHeight: 200
    signal videoSelected(variant item)
    property variant currentPath:""
    property bool isVisible: false

    ListView {
        id: videoListView
        property  alias currentPath: videoList.currentPath
        dataModel: infoListModel

        layout: StackListLayout {
            orientation: LayoutOrientation.LeftToRight
            headerMode: ListHeaderMode.Standard
        }

        function itemType(data, indexPath) {
            return (indexPath.length == 1 ? "header" : "item");
        }

        listItemComponents: [
            ListItemComponent {
                type: "header"
                Container {}
            },
            ListItemComponent {
                type: "item"
                Container {
                    id: listItemtDef
                    visible: ListItemData.folder == "0Favorites" ? false : true
                    verticalAlignment: VerticalAlignment.Fill
                    horizontalAlignment: HorizontalAlignment.Fill

                    Container {
                        verticalAlignment: VerticalAlignment.Bottom
                        maxWidth: 256

                        ThumbnailItem {
                            id: thumb
                            imageSource: ListItemData.thumbURL
                            movieTitle: ListItemData.title
                            movieLength: ListItemData.duration
                            isVideoBarItem: true
                            height: Helpers.videoListScrollBar_thumbHeight
                            width: Helpers.videoListScrollBar_thumbWidth
                        }
                        bottomPadding: 10
                    }

                    Container{
                        verticalAlignment: VerticalAlignment.Fill
                        horizontalAlignment: HorizontalAlignment.Fill
                        ImageView {
	                        id: selectionImg
	                        imageSource: "asset:///images/Player/MovieListItemSelectedBorder.png"
	                        visible: listItemtDef.ListItem.view.currentPath == ListItemData.path
                            verticalAlignment: VerticalAlignment.Fill
                            horizontalAlignment: HorizontalAlignment.Fill
                            preferredHeight: 400
                        }
                    }

                    leftMargin: 7
                    layout: DockLayout {
                    }
                }
            }
        ]
        onTriggered: {
            videoSelected(dataModel.data(indexPath));
        }
        onCreationCompleted: {
            videoListView.scrollToPosition(0, ScrollAnimation.None);
        }
    }
    function scrollItemToMiddle(index, isOrientationLandscape) {
        var realIndex = infoListModel.getRealIndex(index);
        if(isOrientationLandscape)
            videoListView.scrollToItem(infoListModel.before(infoListModel.before(realIndex)), ScrollAnimation.None);
        else
            videoListView.scrollToItem(infoListModel.before(realIndex), ScrollAnimation.None);
    }
}
