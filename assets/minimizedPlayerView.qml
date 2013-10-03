import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    layout: DockLayout {
    }
    background: backgroundImage.imagePaint
    Container {
        ImageView {
            imageSource: infoListModel.getSelectedVideoThumbnail();
            scalingMethod: ScalingMethod.AspectFill
        }
    }
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        topPadding: 40
        ImageView {
            id: minimizedPlay
            opacity: 0.7
            scaleX: 0.8
            scaleY: 0.8
            imageSource: "asset:///images/Player/Play.png"
        }
    }
    attachedObjects: [
        ImagePaintDefinition {
            id: backgroundImage
            imageSource: "asset:///images/Player/VideoBG.png"
        }
    ]
}
