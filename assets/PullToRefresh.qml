import bb.cascades 1.0

Container {
    id: refreshContainer

    property int refreshMode: 0

    horizontalAlignment: HorizontalAlignment.Fill

    layout: StackLayout {

    }

    Container {
        id: refreshStatusContainer
        horizontalAlignment: HorizontalAlignment.Center
        bottomPadding: 5.0
        Label {
            id: refreshStatus
            text: "Pull to refresh"
            textStyle.color: Color.create("#ffffff")
            textStyle.textAlign: TextAlign.Center
        }
    }

    Container {
        bottomPadding: 20.0
        Divider {
            visible: true
        }
    }

    attachedObjects: [
        LayoutUpdateHandler {
            id: refreshHandler
            onLayoutFrameChanged: {
                if (!released && layoutFrame.y >= 70) {
                    refreshMode = 2;
                    refreshStatus.text = "Release to refresh";
                } else if (layoutFrame.y >= -70) {
                    released = false;
                    refreshMode = 1;
                    refreshStatus.text = "Pull to refresh";
                }
            }
        }
    ]

}
