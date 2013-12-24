import bb.cascades 1.0
import "helpers.js" as Helpers

Container {
    layout: DockLayout {
    }

    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    
    property bool isVideoBarItem: false

    property alias imageSource: thumbImage.imageSource
    property alias movieTitle: title.text
    property variant movieLength: ""
    property bool isWatched: true
    property bool haveSubtitle: false
    property bool isRemote: false

    property int height: orientationHandler.orientation == UIOrientation.Portrait ? 380 : 320
    property int width: orientationHandler.orientation == UIOrientation.Portrait ? 380 : 320
    property int sub: 70

    Container {
	    layout: StackLayout {
        }

        leftPadding: 5
        rightPadding: 5
        topPadding: 5
        bottomPadding: 5

	    Container {
	        layout: DockLayout {
	        }

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
                horizontalAlignment: HorizontalAlignment.Right
                background: background.imagePaint

                maxHeight: sub
                preferredHeight: sub
                maxWidth: width
                preferredWidth: width
                leftPadding: 6
                rightPadding: 6

                Container {
                    horizontalAlignment: HorizontalAlignment.Right
                    Label {
                        id: length
                        textStyle.fontSize: FontSize.XXSmall
                        text: Helpers.formatTime(movieLength)
                        textStyle.color: Color.White
                    }
                }

                Container {
                    verticalAlignment: VerticalAlignment.Bottom
                    horizontalAlignment: HorizontalAlignment.Fill
                    Label {
                        horizontalAlignment: HorizontalAlignment.Right
                        id: title
                        text: ""
                        textStyle.color: Color.White
                        textStyle.fontSize: isVideoBarItem == true ? FontSize.XXSmall : FontSize.XSmall
                    }
                }
            }
        }
    }
    Container {
        topPadding: 20
        leftPadding: 20
        ImageView{
            id: wathcedTag
            imageSource: "asset:///images/GridView/new.png"
            opacity: isWatched ? 0 : 1
            scaleX: 0.8
            scaleY: 0.8 
        }
    }
    
    Container {
        horizontalAlignment: HorizontalAlignment.Right        
        topPadding: 20
        rightPadding: 20
        ImageView{
            imageSource: "asset:///images/GridView/subtitleAvailible.png"
            opacity: haveSubtitle ? 1 : 0
        }
    }
    Container {
        verticalAlignment: VerticalAlignment.Bottom
        leftPadding: 20
        bottomPadding: 80
        ImageView {
            id: cloudImage
            imageSource: "asset:///images/GridView/cloud_icon.png"
            opacity: isRemote ? 1 : 0
        }
    }

    attachedObjects: [
        OrientationHandler {
            id: orientationHandler
        },

        ImagePaintDefinition {
            id: background
            imageSource: "asset:///images/GridView/TimeFrame.png"

        },

        ImagePaintDefinition {
            id: timeBackground
            imageSource: "asset:///images/GridView/TimeFrame.png"

        }
    ]

}
