import bb.cascades 1.0
import nuttyPlayer 1.0
import "helpers.js" as Helpers

Container {
    layout: DockLayout {
    }
    id: minimizedMovieGrid

    property bool isQ10: displayInfo.height == 720 ? true : false

    property variant favorites: infoListModel.getFavoriteVideos()
    property int currentFrame: 0

    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        ImageView {
            id: frame
            implicitLayoutAnimationsEnabled: false
            imageSource: favorites[currentFrame]['thumbURL']
            scalingMethod: ScalingMethod.AspectFill
            preferredHeight: isQ10 ? 215 : 400
        }
    }
    Container {
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Right
        background: titleBackground.imagePaint

        preferredHeight: 70
        preferredWidth: 380
        leftPadding: 6
        rightPadding: 6
        Container {
            horizontalAlignment: HorizontalAlignment.Right
            Label {
                id: length
                textStyle.fontSize: FontSize.XXSmall
                text: Helpers.formatTime(favorites[currentFrame]['duration'])
                textStyle.color: Color.White
            }
        }
        Container {
            verticalAlignment: VerticalAlignment.Bottom
            horizontalAlignment: HorizontalAlignment.Fill
            Label {                
                id: title
                implicitLayoutAnimationsEnabled: false
                horizontalAlignment: HorizontalAlignment.Right
                text: favorites[currentFrame]['title'] 
                textStyle.color: Color.White
                textStyle.fontSize: FontSize.XSmall
            }
        }
    }
    attachedObjects: [
        ImagePaintDefinition {
            id: titleBackground
            imageSource: "asset:///images/GridView/TimeFrame.png"
        },        
        QTimer {
            id: updateFrame
            singleShot: false
            interval: 4000
            onTimeout: {                
                if (currentFrame == favorites.length - 1) {
                    currentFrame = 0;
                } else {
                    currentFrame = currentFrame + 1;
                }
            }
        }
    ]
    onCreationCompleted: {   
        if (favorites.length > 1) {
            updateFrame.start();
        }
    }
}
