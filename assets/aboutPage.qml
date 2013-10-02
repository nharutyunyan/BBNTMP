import bb.cascades 1.0
import "helpers.js" as Helpers

Page {
    id: aboutPage
    paneProperties: NavigationPaneProperties {
        backButton: ActionItem {
            onTriggered: {
                navigationPane.isAboutPage = false;
                navigationPane.backButtonsVisible = false;
                navigationPane.pop();
            }
        }
    }
    Container {
        layout: StackLayout {
    	   orientation: LayoutOrientation.TopToBottom    
    	}
        background: Color.White

        ImageView {
            minHeight: 72
            id: headerImage
            imageSource: orientationHandlerMain.orientation == UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
        }

        Label {
        id: aboutText
        text: "<html> \t Nutty Player is a video player applicatio
        	 that supports a wide range of formats. 
        	 Offers custom movie library filters, Subtitles, 
        	 Captions, Touch Screen navigation and an 
        	 intuitive user interface.
 
         	<a style = 'color:black;' href='http://macadamian.com' > www.macadamian.com </a>
         	1-877-779-6336
         	
         	Version: 1.0.0.1 </html>"
               
               textStyle {
            
                base: SystemDefaults.TextStyles.SubtitleText
                textAlign: TextAlign.Left
                fontStyle: FontStyle.Default
                color: Color.Black
                lineHeight: orientationHandlerMain.orientation == UIOrientation.Portrait ? Helpers.aboutPageLinesHeightInPortrait : Helpers.aboutPageLinesHeightInLandscape

            }
        multiline: true   
    }
}
    
    attachedObjects: [
        OrientationHandler {
            id: orientationHandlerMain
            onOrientationAboutToChange: {
                headerImage.imageSource = orientationHandlerMain.orientation != UIOrientation.Portrait ? "asset:///images/title.png" : "asset:///images/title_landscape.png"
                aboutText.textStyle.lineHeight = orientationHandlerMain.orientation != UIOrientation.Portrait ? Helpers.aboutPageLinesHeightInPortrait : Helpers.aboutPageLinesHeightInLandscape
            }
        }
    ]

}
