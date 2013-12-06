function formatTime(msecs)
{
    var seconds = msecs/1000;
    function format(number) {
        var t = Math.floor(number);
        if(t < 10)
            t = "0" + t;

        return t;
    }

    var hours = format(seconds / 3600);
    var reminder = seconds - hours * 3600;
    var mins = format(reminder / 60);
    reminder = reminder - mins * 60;
    var secs = format(reminder);

    return hours + ":" + mins + ":" + secs;
}
var seekTimeInSlide = 10*1000;
var distanceFromSubtitleToBottomOfScreen = 30;
var widthOfSubtitleButton = 150;
var differentScreenWidthAndSubtitleWidth = 300;
// 112 magic number is my estimated width of the context menu, this is based on Q10. 
// TODO : find real size for all platforms ?
var widthOfContextMenu = 112;
var splashScreenForAnimationPortrait = "asset:///images/SplashScreenAnimationPortrait.png";
var splashScreenForAnimationLandscape = "asset:///images/SplashScreenAnimationLandscape.png";
var animatedLogoPositionXPortrait = 172;
var animatedLogoPositionYPortrait = 537;
var animatedLogoPositionXLandscape = 413;
var animatedLogoPositionYLandscape = 300;
var volumeIndicatorLength = 231;
var volumeBarIndicatorsCount = 13;
var actionBarPortraitHeight = 115;
var actionBarLandscapeHeight = 93;
