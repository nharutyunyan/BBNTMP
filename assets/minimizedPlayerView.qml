import bb.cascades 1.0
import nuttyPlayer 1.0

Container {    
    layout: DockLayout {
    }
    property bool isQ10: displayInfo.height == 720 ? true : false
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        ImageView {
            imageSource: infoListModel.getSelectedVideoThumbnail();
            scalingMethod: ScalingMethod.AspectFill
            preferredHeight: isQ10 ? 215 : 400
        }
    }
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        ImageView {
            id: minimizedPlay
            opacity: 0.7
            scaleX: isQ10 ? 0.6 : 0.8  
            scaleY: isQ10 ? 0.6 : 0.8
            imageSource: "asset:///images/Player/Play.png"
        }
    }
}
