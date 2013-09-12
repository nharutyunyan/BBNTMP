//Animated logo shown before thumbnails load
import bb.cascades 1.0
import bb.multimedia 1.0
import nuttyPlayer 1.0
import "helpers.js" as Helpers

NavigationPane {
    Page {
        ImageView {
            id: animatedLogo
            imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/SplashAnimPortrait.gif" : "asset:///images/SplashAnimLandscape.gif"
            attachedObjects: [
                ImageAnimator {
                    animatedImage: animatedLogo.image
                    started: true
                }
            ]
        }
        attachedObjects: [
            OrientationHandler {
                id: orientationHandlerMain
                onOrientationAboutToChange: {
                    animatedLogo.imageSource = orientationHandlerMain.orientation != UIOrientation.Portrait ? "asset:///images/SplashAnimPortrait.gif" : "asset:///images/SplashAnimLandscape.gif"
                }
            }
        ]
    }
}