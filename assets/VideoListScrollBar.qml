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
        dataModel: InfoListModel {
            id: dataModel
        }

        listItemComponents: [
            ListItemComponent {
                Container {
                    id: listItemtDef
                    verticalAlignment: VerticalAlignment.Fill
                    horizontalAlignment: HorizontalAlignment.Fill

                    Container {
                        verticalAlignment: VerticalAlignment.Bottom
                        maxWidth: 320

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

        layout: StackListLayout {
            orientation: LayoutOrientation.LeftToRight            
        }
    }
}