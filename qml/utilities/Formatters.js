.pragma library

function formatDuration(totalSeconds) {
    var secs = parseInt(totalSeconds) || 0;
    var hours = Math.floor(secs / 3600);
    var mins = Math.floor((secs % 3600) / 60);
    var remainingSecs = secs % 60;

    var pad = function(num) {
        return (num < 10 ? "0" : "") + num;
    };

    if (hours > 0) {
        return pad(hours) + ":" + pad(mins) + ":" + pad(remainingSecs);
    } else {
        return pad(mins) + ":" + pad(remainingSecs);
    }
}

function formatCalories(calories) {
    var val = parseFloat(calories) || 0;
    return val.toFixed(1) + " kcal";
}

function formatWeight(weightKg) {
    var val = parseFloat(weightKg) || 0;
    return val.toFixed(1) + " kg";
}

function formatDate(date) {
    if (!date) return "";
    var d = (date instanceof Date) ? date : new Date(date);
    if (isNaN(d.getTime())) return String(date);
    return Qt.formatDate(d, "yyyy-MM-dd");
}

function formatDateTime(date) {
    if (!date) return "";
    var d = (date instanceof Date) ? date : new Date(date);
    if (isNaN(d.getTime())) return String(date);
    return Qt.formatDateTime(d, "yyyy-MM-dd hh:mm");
}
