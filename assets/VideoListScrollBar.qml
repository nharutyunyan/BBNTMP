import bb.cascades 1.0
import nuttyPlayer 1.0

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
    function scrollItemToMiddle(index, isOrientationLandscape, size) {
        index = updateValue(index, isOrientationLandscape);
        size = updateValue(size, isOrientationLandscape);
        if(isOrientationLandscape) size--;
        if(index > size - 3) {
            // if selected video is near to end
            videoListView.scrollToPosition(1, ScrollAnimation.None);
            return;
        }
        var a = index * 263; // 263 is amount of pixels to scroll 1 item. 256 comes from item size.
        // 7 pixels come from paddings between items(I'm not 100% sure)
        // function scrollToItem doesn't work in this case
        // function scroll works only for little values that is why I am scrolling in while
        // Scrolling with numbers higher than 100 are scrolling list to the end. I choose 50 for safety
        videoListView.scrollToPosition(0, ScrollAnimation.None);
        while(a > 0) {
            if(a < 50) {
                videoListView.scroll(a, ScrollAnimation.None);
                a = 0;
                continue;
            }
            videoListView.scroll(50, ScrollAnimation.None);
            a -= 50;
        }
    }

    function updateValue(val, isOrientationLandscape) {
        if (val > 0)
            val--;
        if (isOrientationLandscape && val > 0)
            val --;
        return val;
    }
}
