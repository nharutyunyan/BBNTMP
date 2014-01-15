import bb.cascades 1.0
import nuttyPlayer 1.0

Page {
    id: subtitlePage
    Container {
        layout: DockLayout {}
        ListView {
            dataModel: SubtitleArrayDataModel {
                id: model
                onSubtitleRecieved: {
                    lIndicator.stop();
                    if(model.size() == 0)
                        noSubtitleContainer.setOpacity(1);
                }
            }
            listItemComponents: [
                ListItemComponent {
                    Container {
                        id: itemContainer
                        layout: DockLayout {}
                        Container {
                            id: selectContainer
                            opacity: 0
                            implicitLayoutAnimationsEnabled: false
                            verticalAlignment: VerticalAlignment.Fill
                            horizontalAlignment: HorizontalAlignment.Fill
                            background: Color.create("#aaaaaa")
                        }
                        Container {
                            property bool touchMode: false
                            layout: StackLayout {
                                orientation: LayoutOrientation.TopToBottom
                            }
                            horizontalAlignment: HorizontalAlignment.Fill
                            bottomPadding: 10
                            Container {
                                minHeight: 3
                                background: Color.create("#888888")
                                Divider {}
                            }
                            Label {
                                text: ListItemData.MovieReleaseName
                                multiline: true
                                textStyle.fontWeight: FontWeight.W500
                            }
                            Label {
                                text: "File name:  " + ListItemData.SubFileName
                                multiline: true
                            }
                            Label {
                                text: "Languige:  " + ListItemData.LanguageName
                            }
                            onTouch: {
                                if(event.touchType == TouchType.Down) {
                                    touchMode = true;
                                } else if(event.touchType == TouchType.Up) {
                                    touchMode = false;
                                } else if(event.touchType == TouchType.Cancel) {
                                    touchMode = false;
                                }
                            }
                            onTouchExit: {
                                touchMode = false;
                            }
                            onTouchModeChanged: {
                                if(touchMode)
                                    selectContainer.setOpacity(0.6);
                                else
                                    selectContainer.setOpacity(0);
                            }
                        }
                    }
                }
            ]
            onTriggered: {
                var data = dataModel.data(indexPath);
                model.downloadSubtitles(data.IDSubtitleFile);
                navigationPane.pop();
                subtitlePage.destroy();
            }
        }
        Container {
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            ActivityIndicator {
                id: lIndicator
                property int indicatorSize: 200
                preferredWidth: lIndicator.indicatorSize
                preferredHeight: lIndicator.indicatorSize
            }
        }
        Container {
            id: noSubtitleContainer
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            opacity: 0
            Label {
                text: "Couldn't find subtitles for this video";
                multiline: true
            }
        }
    }
    function setFilePath(path) {
        model.filePath = path;
        lIndicator.start();
    }
}
