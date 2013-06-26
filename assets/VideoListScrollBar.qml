import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    background: Color.LightGray
    preferredHeight: 150
    signal videoSelected(variant item)
   
    ListView {
        id: videoListView
        dataModel: InfoListModel {
            id: dataModel
        }
        
        listItemComponents: [
            ListItemComponent {
                Container {
                    background: Color.Black
                    verticalAlignment: VerticalAlignment.Bottom
                    maxWidth: 200
                    id: listItemtDef
                    ThumbnailItem {
                        imageSource: ListItemData.thumbURL
                        movieTitle: ListItemData.title
                        movieLength: ListItemData.duration
                    }

                    leftMargin: 7
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