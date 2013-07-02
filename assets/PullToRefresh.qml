import bb.cascades 1.0

Container {
    id: refreshContainer

    property bool refreshing: false
    property bool released: true
    property bool refreshMode: false

	signal refreshTriggered

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
                if (layoutFrame.y >= 70) {
                    refreshMode = true;
                    refreshStatus.text = "Release to refresh";

                    if (released)
                    	refreshing = true;

                } else if (layoutFrame.y >= -70) {
                    refreshMode = true;
                    refreshStatus.text = "Pull to refresh"
                } else if (layoutFrame.y >= -100) {
                    refreshTriggered();
                }

            }
        }
    ]

}
