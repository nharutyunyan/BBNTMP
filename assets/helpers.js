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