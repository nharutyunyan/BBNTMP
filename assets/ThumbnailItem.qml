import bb.cascades 1.0
import "helpers.js" as Helpers

Container {
    layout: DockLayout {

    }

    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill

    property alias imageSource: thumbImage.imageSource
    property alias movieTitle: title.text
    property variant movieLength: ""

    property int height: orientationHandler.orientation == UIOrientation.Portrait ? 320 : 240
    property int width: orientationHandler.orientation == UIOrientation.Portrait ? 240 : 320
    property int sub: 60

    ImageView {
        id: thumbImage
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        scalingMethod: ScalingMethod.AspectFill
        preferredHeight: height
        preferredWidth: width
        maxHeight: height
        maxWidth: width
    }

    Container {
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Fill
        layout: StackLayout {

        }
        background: background.imagePaint

        maxHeight: sub
        preferredHeight: sub
        maxWidth: width
        preferredWidth: width

        Container {
            verticalAlignment: VerticalAlignment.Center
            horizontalAlignment: HorizontalAlignment.Fill
            Label {
                id: title
                text: ""
                textStyle.color: Color.White
                textStyle.base: SystemDefaults.TextStyles.SmallText
            }
        }

        Container {
            verticalAlignment: VerticalAlignment.Top
            horizontalAlignment: HorizontalAlignment.Fill
            Label {
                id: length
                text: Helpers.formatTime(movieLength)
                textStyle.color: Color.White
                textStyle.base: SystemDefaults.TextStyles.SmallText
            }
        }

    }

    attachedObjects: [
        OrientationHandler {
            id: orientationHandler
        },

        ImagePaintDefinition {
            id: background
            imageSource: "asset:///images/GridView/TitleFrame.amd"

        }
    ]
}
