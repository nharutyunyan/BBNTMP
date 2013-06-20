import bb.cascades 1.0
import nuttyPlayer 1.0

Container {
    layout: StackLayout {
        orientation: LayoutOrientation.TopToBottom
    }
    preferredHeight: 200
    Container {
        layoutProperties: StackLayoutProperties {
            spaceQuota: 1.0
        }
    }
    TextArea {
        text: subtitleManager.text
        textFormat: TextFormat.Html
        backgroundVisible: false
        textStyle.color: Color.White
        textStyle.textAlign: TextAlign.Center
        editable: false
        overlapTouchPolicy: OverlapTouchPolicy.Allow
        verticalAlignment: VerticalAlignment.Bottom
        horizontalAlignment: HorizontalAlignment.Center
        inputMode: TextAreaInputMode.Text
        input.flags: TextInputFlag.SpellCheckOff
        
        onCreationCompleted: {
            
            setImplicitLayoutAnimationsEnabled(false);
        }
    }
}
