import bb.cascades 1.0
import nuttyPlayer 1.0
import bb.multimedia 1.0
import bb.system 1.0
import "helpers.js" as Helpers

Page {
    property alias groupDataModel: drillDownList.dataModel
    property string selectedFolder
    Container {
        background: Color.Black
        ListView {
            id: drillDownList
            dataModel: ArrayDataModel {
                id: groupDataModel
            }

            listItemComponents: [
                ListItemComponent {
                    type: "header"
                    Container {
                        visible: ListItem.view.getSelectedFolder() == ListItemData ? true : false
                        id: topCont
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
                },

                ListItemComponent {
                    type: "item"
                    Container {
                        visible: ListItem.view.getSelectedFolder() == ListItemData.folder ? true : false
                        id: itemRoot
                        Container {
                            id: itemContainer
                            topPadding: 5
                            bottomPadding: topPadding
                            leftPadding: topPadding
                            rightPadding: topPadding
                            minWidth: orientationHandler.orientation == UIOrientation.Portrait ? 768 : 1280
                            Container {
                                layout: StackLayout {
                                    orientation: LayoutOrientation.LeftToRight
                                }
                                minWidth: orientationHandler.orientation == UIOrientation.Portrait ? 768 : 1280
                                background: bg.imagePaint
                                Container {
                                    id: thumbnailContainer
                                    property int imageDimension: orientationHandler.orientation == UIOrientation.Portrait ? 280 : 220
                                    ImageView {
                                        imageSource: ListItemData.thumbURL
                                        scalingMethod: ScalingMethod.AspectFill
                                        minWidth: thumbnailContainer.imageDimension
                                        minHeight: thumbnailContainer.imageDimension
                                        preferredHeight: thumbnailContainer.imageDimension
                                        preferredWidth: thumbnailContainer.imageDimension
                                    }
                                }

                                Container {
                                    verticalAlignment: VerticalAlignment.Center
                                    leftPadding: 5
                                    Container {
                                        Label {
                                            multiline: true
                                            autoSize.maxLineCount: 3
                                            text: ListItemData.title
                                            textStyle.color: Color.White
                                        }
                                        Label {
                                            text: Helpers.formatTime(ListItemData.duration)
                                            textStyle.color: Color.White
                                        }
                                    }
                                }
                            }

                            onTouch: {
                                if (event.touchType == TouchType.Down || event.touchType == TouchType.Move)
                                    background = Color.create("#ff8811");
                                else
                                    background = Color.Transparent
                            }
                        }
                        attachedObjects: [
                            OrientationHandler {
                                id: orientationHandler
                            },
                            ImagePaintDefinition {
                                id: bg
                                imageSource: "asset:///images/GridView/TimeFrame.png"

                            }
                        ]
                    }
                }
            ]
            function getSelectedFolder() {
                return selectedFolder
            }

            function getSecondPage() {
                var page = moviePlayer.createObject()
                return page
            }

            onTriggered: {
                clearSelection();
                select(indexPath);
            }
            onSelectionChanged: {
                // Don't load a video if a context menu is showing
                // slot called when ListView emits selectionChanged signal
                // A slot naming convention is used for automatic connection of list view signals to slots
                if (selected && drillDownList.selected().length != 1) {
                    infoListModel.setSelectedIndex(drillDownList.selected())
                    var page = getSecondPage();
                    console.log("pushing detail " + page)
                    //variables for passing selected video path and length to videoScrollList
                    var currentPath = drillDownList.dataModel.data(indexPath).path;
                    page.currentPath = currentPath;
                    var currentLenght = drillDownList.dataModel.data(indexPath).duration;
                    page.currentLenght = currentLenght;
                    navigationPane.push(page);
                    clearSelection();
                }
            }
            attachedObjects: [
                ComponentDefinition {
                    id: moviePlayer
                    source: "playerView.qml"
                }
            ]
        } //listview
    } //container
}//page
