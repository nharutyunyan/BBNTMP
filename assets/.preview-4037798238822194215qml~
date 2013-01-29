import bb.cascades 1.0

Sheet {
    objectName: "videoSheet"
    content: Page {
        content: Container {
            layout: AbsoluteLayout {}
            ForeignWindowControl {
                id: videoWindow
                objectName: "videoWindow"
                windowId: "VideoWindow"
                layoutProperties: AbsoluteLayoutProperties {
                    positionX: 0
                    positionY: 0
                }
                preferredWidth: 768
                preferredHeight: 1280
                visible:  boundToWindow                        
                
                onVisibleChanged: {
                    console.log("foreignwindow visible = " + visible);
                }
                onBoundToWindowChanged: {
                    console.log("VideoWindow bound to mediaplayer!");
                }
            }
        }
    }
}