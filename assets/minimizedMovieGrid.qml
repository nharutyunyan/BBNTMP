import bb.cascades 1.0
import nuttyPlayer 1.0
import "helpers.js" as Helpers

Container {
    layout: DockLayout {
    }
    id: minimizedMovieGrid
    property variant favorites: infoListModel.getFavoriteVideos()
    property int currentFrame: 0
    preferredHeight: 720  
    preferredWidth: 720    

    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        ImageView {
            id: frame
            imageSource: favorites[currentFrame]['thumbURL']
            scalingMethod: ScalingMethod.AspectFill
            preferredHeight: 400
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
                horizontalAlignment: HorizontalAlignment.Right
                id: title 
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
        InfoListModel {
            id: infoListModel
        },
        QTimer {
            id: updateFrame
            singleShot: false
            interval: 2000
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
