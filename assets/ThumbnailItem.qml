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

    property int height: 320
    property int width: 240
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
            onOrientationAboutToChange: {
                if (orientation == UIOrientation.Portrait) {
                    height = 320;
                    width = 240;
                } else if (orientation == UIOrientation.Landscape) {
                    height = 240;
                    width = 320;
                }

            }
        },

        ImagePaintDefinition {
            id: background
            imageSource: "asset:///images/GridView/TitleFrame.amd"

        }
    ]
}
