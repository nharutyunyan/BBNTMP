
import bb.cascades 1.0
import bb.multimedia 1.0
import "helpers.js" as Helpers

NavigationPane {
    Page {
        Container {
        layout: AbsoluteLayout {
        }    
        
        ImageView {
            id : splashScreen
            imageSource: OrientationSupport.orientation == UIOrientation.Portrait ? Helpers.splashScreenForAnimationPortrait : Helpers.splashScreenForAnimationLandscape
        }
        
        Container {
        	id : animatedLogoContainer
            layout: AbsoluteLayout {
                
        }
            
        layoutProperties: AbsoluteLayoutProperties {
            positionX: OrientationSupport.orientation == UIOrientation.Portrait ? Helpers.animatedLogoPositionXPortrait : Helpers.animatedLogoPositionXLandscape
            positionY: OrientationSupport.orientation == UIOrientation.Portrait ? Helpers.animatedLogoPositionYPortrait : Helpers.animatedLogoPositionYLandscape
        }
        
        preferredHeight: 160  
        
        ImageView {
            layoutProperties: AbsoluteLayoutProperties {
            	positionY: -9
            }
            
            implicitLayoutAnimationsEnabled: false 
            id: animatedLogo
            imageSource:  "asset:///images/splashAnimation.png"
            animations: [
                TranslateTransition {
                    id: anim
                    fromY: 0
                    toY: 0
                    duration: 300
                    easingCurve: StockCurve.SineIn
                    onEnded: {
                        anim1.play()
                    }
                },
                TranslateTransition {
                    id : anim1
                    fromY: 0
                    toY: -30
                    duration: 600
                    repeatCount: AnimationRepeatCount.Forever
                    easingCurve: StockCurve.Linear
                }
            ]
        }
    }
        
        onCreationCompleted: {
            anim.play()
        }
    }
        attachedObjects: [
            OrientationHandler {
                id: orientationHandlerMain
                onOrientationAboutToChange: {
                    
                    if(orientation == UIOrientation.Portrait)
                    {
                        splashScreen.imageSource = Helpers.splashScreenForAnimationPortrait;
                        animatedLogoContainer.layoutProperties.positionX = Helpers.animatedLogoPositionXPortrait;
                        animatedLogoContainer.layoutProperties.positionY = Helpers.animatedLogoPositionYPortrait;
                    }
                    else
                    {
                        splashScreen.imageSource = Helpers.splashScreenForAnimationLandscape;
                        animatedLogoContainer.layoutProperties.positionX = Helpers.animatedLogoPositionXLandscape;
                        animatedLogoContainer.layoutProperties.positionY = Helpers.animatedLogoPositionYLandscape;
                    }
                }
            }
        ]
    }
}