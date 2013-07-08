import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    id: videoList
    background: Color.Black
    preferredHeight: 150
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
                    verticalAlignment: VerticalAlignment.Bottom
                    maxWidth: 200
                    id: listItemtDef
                    ThumbnailItem {
                        id: thumb
                        imageSource: ListItemData.thumbURL
                        movieTitle: ListItemData.title
                        movieLength: ListItemData.duration
                        bottomPadding: 30.0
                        topPadding: 5.0
                    }
                    Container{
                        verticalAlignment: VerticalAlignment.Fill
                        horizontalAlignment: HorizontalAlignment.Fill
                        ImageView {
	                        id: selectionImg
	                        imageSource: "asset:///images/Player/MovieListItemSelectedBorder.png"
	                        visible: listItemtDef.ListItem.view.currentPath === ListItemData.path
                            scalingMethod: ScalingMethod.AspectFill
                            verticalAlignment: VerticalAlignment.Fill
                            horizontalAlignment: HorizontalAlignment.Fill
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