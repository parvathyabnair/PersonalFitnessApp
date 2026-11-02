.pragma library
.import "../models/SettingsModel.js" as SettingsModel
.import "../models/WorkoutModel.js" as WorkoutModel
.import "HealthCalculator.js" as HealthCalculator
.import "Formatters.js" as Formatters

function escapePdf(text) {
    if (text === null || text === undefined) return "";
    var s = String(text);
    s = s.replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
    return s.replace(/[^\x20-\x7E]/g, " ");
}

function escapeCsv(text) {
    if (text === null || text === undefined) return '""';
    var s = String(text).replace(/"/g, '""');
    return '"' + s + '"';
}

function formatSessionDate(dateVal) {
    if (!dateVal) return "-";
    var str = String(dateVal).trim();
    var d = new Date(str);
    if (!isNaN(d.getTime())) {
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var y = d.getFullYear();
        var m = months[d.getMonth()];
        var day = d.getDate();
        var dayStr = (day < 10 ? "0" : "") + day;
        return m + " " + dayStr + ", " + y;
    }
    if (str.indexOf("T") !== -1) {
        return str.split("T")[0];
    }
    return str.substring(0, 12);
}

function formatSetsReps(setsVal, repsVal) {
    var sets = setsVal !== undefined && setsVal !== null ? String(setsVal).trim() : "";
    var repsArr = [];
    if (repsVal) {
        if (typeof repsVal === "string") {
            try {
                var parsed = JSON.parse(repsVal);
                if (Array.isArray(parsed)) {
                    repsArr = parsed.filter(function(r) {
                        return r !== null && r !== undefined && String(r).trim() !== "" && String(r).trim() !== '""';
                    });
                } else if (String(parsed).trim() !== "" && String(parsed).trim() !== '""') {
                    repsArr = [String(parsed).trim()];
                }
            } catch(e) {
                var clean = repsVal.replace(/[\[\]"']/g, "").trim();
                if (clean !== "") {
                    repsArr = [clean];
                }
            }
        } else if (Array.isArray(repsVal)) {
            repsArr = repsVal.filter(function(r) {
                return r !== null && r !== undefined && String(r).trim() !== "" && String(r).trim() !== '""';
            });
        }
    }

    var repsText = "";
    if (repsArr.length > 0) {
        var allSame = true;
        for (var i = 1; i < repsArr.length; i++) {
            if (repsArr[i] !== repsArr[0]) {
                allSame = false;
                break;
            }
        }
        if (allSame) {
            repsText = repsArr[0] + " reps";
        } else {
            repsText = repsArr.join("/") + " reps";
        }
    }

    var result = "";
    if (sets && sets !== "0") {
        result = sets + (parseInt(sets) === 1 ? " set" : " sets");
    }
    if (repsText) {
        result += (result ? " x " : "") + repsText;
    }
    return result || "-";
}

function buildReportData(timeframe, todayWaterMl, targetWaterMl) {
    var rawSettings = SettingsModel.getSettings() || {};
    var rawStats = WorkoutModel.getWorkoutStats() || {};
    var allSessions = WorkoutModel.getSessions() || [];

    var weight = rawSettings.weight ? String(rawSettings.weight) : "70";
    var goalWeight = rawSettings.goal_weight ? String(rawSettings.goal_weight) : "-";
    var height = rawSettings.height ? String(rawSettings.height) : "175";
    var age = rawSettings.age ? String(rawSettings.age) : "25";
    var gender = rawSettings.gender ? String(rawSettings.gender) : "Male";
    var kcalTarget = rawSettings.kcal_target ? String(rawSettings.kcal_target) : "500";

    var bmiInfo = HealthCalculator.calculateBMI(weight, height);
    var bmrVal = HealthCalculator.calculateBMR(weight, height, age, gender);

    // Filter sessions based on timeframe
    var today = new Date();
    var currentYear = today.getFullYear();
    var currentMonth = today.getMonth();

    var day = today.getDay();
    var diff = today.getDate() - day + (day === 0 ? -6 : 1);
    var startOfWeek = new Date(today.getFullYear(), today.getMonth(), diff);
    startOfWeek.setHours(0, 0, 0, 0);
    var endOfWeek = new Date(startOfWeek.getTime() + 7 * 24 * 60 * 60 * 1000);

    var filteredSessions = [];
    var totalSeconds = 0;
    var totalCalories = 0;

    for (var i = 0; i < allSessions.length; i++) {
        var sess = allSessions[i];
        var match = true;

        if (sess.date && timeframe !== "all") {
            var d = new Date(sess.date);
            if (!isNaN(d.getTime())) {
                if (timeframe === "month") {
                    match = (d.getFullYear() === currentYear && d.getMonth() === currentMonth);
                } else if (timeframe === "week") {
                    match = (d >= startOfWeek && d < endOfWeek);
                }
            }
        }

        if (match) {
            filteredSessions.push(sess);
            totalSeconds += (sess.duration || 0);
            totalCalories += (parseFloat(sess.calories) || 0);
        }
    }

    var totalHoursStr = (totalSeconds / 3600).toFixed(1) + "h";
    var avgCal = filteredSessions.length > 0 ? Math.round(totalCalories / filteredSessions.length) : 0;

    var timeframeTitle = "All Time";
    if (timeframe === "month") timeframeTitle = "This Month";
    if (timeframe === "week") timeframeTitle = "This Week";

    return {
        generatedDate: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"),
        timeframe: timeframe,
        timeframeTitle: timeframeTitle,
        user: {
            weight: weight,
            goal_weight: goalWeight,
            height: height,
            age: age,
            gender: gender,
            kcal_target: kcalTarget,
            bmi: bmiInfo.bmi || "22.9",
            bmi_status: bmiInfo.status || "Normal",
            bmr: String(bmrVal || "1650"),
            today_water: todayWaterMl ? String(todayWaterMl) : "0",
            target_water: targetWaterMl ? String(targetWaterMl) : "2000"
        },
        stats: {
            total_sessions: String(filteredSessions.length),
            total_hours: totalHoursStr,
            total_calories: String(Math.round(totalCalories)),
            avg_calories: String(avgCal),
            streak_days: String(rawStats.streakDays || 0)
        },
        sessions: filteredSessions
    };
}

function generatePdf(data) {
    var user = data.user;
    var stats = data.stats;
    var sessions = data.sessions;

    var PAGE_1_MAX = 22;
    var PAGE_N_MAX = 38;

    var sessP1 = sessions.slice(0, PAGE_1_MAX);
    var remSess = sessions.slice(PAGE_1_MAX);
    var pagesSess = [sessP1];
    while (remSess.length > 0) {
        pagesSess.push(remSess.slice(0, PAGE_N_MAX));
        remSess = remSess.slice(PAGE_N_MAX);
    }

    var totalPages = pagesSess.length;
    var pagesStreams = [];

    for (var pageNum = 1; pageNum <= totalPages; pageNum++) {
        var pageItems = pagesSess[pageNum - 1];
        var s = [];

        if (pageNum === 1) {
            // Header Banner in #fc5d5d
            s.push("0.988 0.365 0.365 rg 40 760 515 50 re f");
            s.push("BT /F2 18 Tf 1 1 1 rg 55 788 Td (PERSONAL FITNESS REPORT) Tj ET");
            s.push("BT /F1 9 Tf 1 1 1 rg 55 770 Td (" + escapePdf("Generated on " + data.generatedDate + " • Range: " + data.timeframeTitle) + ") Tj ET");

            // Profile & Health Card
            s.push("0.97 0.98 0.98 rg 40 660 515 85 re f");
            s.push("0.85 0.87 0.89 RG 1 w 40 660 515 85 re S");
            s.push("0.475 0.812 0.949 rg 40 742 515 3 re f"); // #79cff2 strip
            s.push("BT /F2 11 Tf 0.1 0.1 0.12 rg 55 725 Td (USER HEALTH & FITNESS PROFILE) Tj ET");

            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 55 705 Td (Current Weight: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.weight) + " kg) Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 220 705 Td (Goal Weight: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.goal_weight) + " kg) Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 380 705 Td (Daily Goal: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.kcal_target) + " kcal) Tj ET");

            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 55 682 Td (Height: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.height) + " cm) Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 220 682 Td (BMI: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.bmi + " - " + user.bmi_status) + ") Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 380 682 Td (Resting BMR: ) Tj /F2 9.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(user.bmr) + " kcal) Tj ET");

            // Lifetime Statistics Card
            s.push("0.97 0.98 0.98 rg 40 580 515 65 re f");
            s.push("0.85 0.87 0.89 RG 1 w 40 580 515 65 re S");
            s.push("0.988 0.365 0.365 rg 40 642 515 3 re f"); // #fc5d5d strip
            s.push("BT /F2 11 Tf 0.1 0.1 0.12 rg 55 625 Td (ACTIVITY SUMMARY STATISTICS) Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 55 600 Td (Total Sessions: ) Tj /F2 10.5 Tf 0.988 0.365 0.365 rg (" + escapePdf(stats.total_sessions) + ") Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 220 600 Td (Total Workout Time: ) Tj /F2 10.5 Tf 0.1 0.1 0.1 rg (" + escapePdf(stats.total_hours) + ") Tj ET");
            s.push("BT /F1 9.5 Tf 0.3 0.3 0.35 rg 380 600 Td (Total Calories: ) Tj /F2 10.5 Tf 0.988 0.365 0.365 rg (" + escapePdf(stats.total_calories) + " kcal) Tj ET");

            // Table Title
            s.push("BT /F2 11 Tf 0.1 0.1 0.12 rg 40 550 Td (WORKOUT SESSION LOGS) Tj ET");
            var tableTop = 540;
        } else {
            // Continued header on Page 2+
            s.push("0.988 0.365 0.365 rg 40 785 515 25 re f");
            s.push("BT /F2 11 Tf 1 1 1 rg 55 793 Td (PERSONAL FITNESS REPORT - CONTINUED) Tj ET");
            var tableTop = 770;
        }

        // Table Header Row
        // Table Header Row: Adjusted column positions to eliminate overlaps
        s.push("0.2 0.22 0.25 rg 40 " + (tableTop - 18) + " 515 18 re f");
        s.push("BT /F2 8.5 Tf 1 1 1 rg 48 " + (tableTop - 13) + " Td (DATE) Tj ET");
        s.push("BT /F2 8.5 Tf 1 1 1 rg 140 " + (tableTop - 13) + " Td (WORKOUT) Tj ET");
        s.push("BT /F2 8.5 Tf 1 1 1 rg 280 " + (tableTop - 13) + " Td (DURATION) Tj ET");
        s.push("BT /F2 8.5 Tf 1 1 1 rg 350 " + (tableTop - 13) + " Td (CALORIES) Tj ET");
        s.push("BT /F2 8.5 Tf 1 1 1 rg 425 " + (tableTop - 13) + " Td (SETS / REPS) Tj ET");

        var y = tableTop - 34;

        if (pageItems.length === 0 && pageNum === 1) {
            s.push("0.96 0.97 0.98 rg 40 " + (y - 3) + " 515 22 re f");
            s.push("0.88 0.90 0.92 RG 0.5 w 40 " + (y - 3) + " 515 22 re S");
            s.push("BT /F1 9 Tf 0.4 0.4 0.45 rg 180 " + (y + 3) + " Td (No workout sessions logged for this timeframe.) Tj ET");
        } else {
            for (var idx = 0; idx < pageItems.length; idx++) {
                var itm = pageItems[idx];
                if (idx % 2 === 1) {
                    s.push("0.96 0.97 0.98 rg 40 " + (y - 3) + " 515 16 re f");
                }
                s.push("0.88 0.90 0.92 RG 0.5 w 40 " + (y - 3) + " 515 16 re S");

                var dateText = formatSessionDate(itm.date);
                var workoutText = itm.workout || "Workout";
                if (workoutText.length > 26) {
                    workoutText = workoutText.substring(0, 24) + "..";
                }
                var durSec = parseInt(itm.duration) || 0;
                var durText = Formatters.formatDuration(durSec);
                var calText = (Math.round(parseFloat(itm.calories) || 0)) + " kcal";
                var setsRepsText = formatSetsReps(itm.sets, itm.reps);

                s.push("BT /F1 8 Tf 0.2 0.2 0.25 rg 48 " + (y + 1) + " Td (" + escapePdf(dateText) + ") Tj ET");
                s.push("BT /F2 8 Tf 0.1 0.1 0.12 rg 140 " + (y + 1) + " Td (" + escapePdf(workoutText) + ") Tj ET");
                s.push("BT /F1 8 Tf 0.2 0.2 0.25 rg 280 " + (y + 1) + " Td (" + escapePdf(durText) + ") Tj ET");
                s.push("BT /F2 8 Tf 0.988 0.365 0.365 rg 350 " + (y + 1) + " Td (" + escapePdf(calText) + ") Tj ET");
                s.push("BT /F1 8 Tf 0.3 0.3 0.35 rg 425 " + (y + 1) + " Td (" + escapePdf(setsRepsText) + ") Tj ET");
                y -= 17;
            }
        }

        // Footer
        s.push("0.85 0.87 0.89 RG 0.5 w 40 45 515 0.5 re S");
        s.push("BT /F1 8 Tf 0.5 0.5 0.55 rg 40 32 Td (Personal Fitness App - Keep moving, stay hydrated, achieve your goals.) Tj ET");
        s.push("BT /F1 8 Tf 0.5 0.5 0.55 rg 490 32 Td (Page " + pageNum + " of " + totalPages + ") Tj ET");

        pagesStreams.push(s.join("\n") + "\n");
    }

    var numPages = pagesStreams.length;
    var font1Idx = 3 + 2 * numPages;
    var font2Idx = font1Idx + 1;

    var pageRefsArr = [];
    for (var p = 0; p < numPages; p++) {
        pageRefsArr.push((3 + 2 * p) + " 0 R");
    }

    var objects = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [" + pageRefsArr.join(" ") + "] /Count " + numPages + " >>"
    ];

    for (var i = 0; i < numPages; i++) {
        var streamStr = pagesStreams[i];
        var pageObj = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents " + (4 + 2 * i) + " 0 R /Resources << /Font << /F1 " + font1Idx + " 0 R /F2 " + font2Idx + " 0 R >> >> >>";
        var contentObj = "<< /Length " + streamStr.length + " >>\nstream\n" + streamStr + "endstream";
        objects.push(pageObj);
        objects.push(contentObj);
    }

    objects.push("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");
    objects.push("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>");

    var pdf = "%PDF-1.4\n";
    var offsets = [];
    for (var j = 0; j < objects.length; j++) {
        offsets.push(pdf.length);
        pdf += (j + 1) + " 0 obj\n" + objects[j] + "\nendobj\n";
    }

    var xrefPos = pdf.length;
    pdf += "xref\n0 " + (objects.length + 1) + "\n0000000000 65535 f \n";
    for (var k = 0; k < offsets.length; k++) {
        var offStr = "0000000000" + offsets[k];
        pdf += offStr.substr(offStr.length - 10) + " 00000 n \n";
    }

    pdf += "trailer\n<< /Root 1 0 R /Size " + (objects.length + 1) + " >>\nstartxref\n" + xrefPos + "\n%%EOF";
    return pdf;
}

function generateCsv(data) {
    var user = data.user;
    var stats = data.stats;
    var sessions = data.sessions;

    var lines = [];
    lines.push(escapeCsv("PERSONAL FITNESS REPORT"));
    lines.push(escapeCsv("Generated") + "," + escapeCsv(data.generatedDate));
    lines.push(escapeCsv("Timeframe") + "," + escapeCsv(data.timeframeTitle));
    lines.push("");

    lines.push(escapeCsv("USER HEALTH & FITNESS PROFILE"));
    lines.push(escapeCsv("Current Weight (kg)") + "," + escapeCsv(user.weight));
    lines.push(escapeCsv("Goal Weight (kg)") + "," + escapeCsv(user.goal_weight));
    lines.push(escapeCsv("Daily Calorie Target (kcal)") + "," + escapeCsv(user.kcal_target));
    lines.push(escapeCsv("Height (cm)") + "," + escapeCsv(user.height));
    lines.push(escapeCsv("Gender") + "," + escapeCsv(user.gender));
    lines.push(escapeCsv("Age") + "," + escapeCsv(user.age));
    lines.push(escapeCsv("BMI") + "," + escapeCsv(user.bmi));
    lines.push(escapeCsv("BMI Status") + "," + escapeCsv(user.bmi_status));
    lines.push(escapeCsv("Resting BMR (kcal)") + "," + escapeCsv(user.bmr));
    lines.push("");

    lines.push(escapeCsv("ACTIVITY SUMMARY STATISTICS"));
    lines.push(escapeCsv("Total Sessions") + "," + escapeCsv(stats.total_sessions));
    lines.push(escapeCsv("Total Workout Time") + "," + escapeCsv(stats.total_hours));
    lines.push(escapeCsv("Total Calories Burned (kcal)") + "," + escapeCsv(stats.total_calories));
    lines.push(escapeCsv("Average Calories per Session") + "," + escapeCsv(stats.avg_calories));
    lines.push("");

    lines.push(escapeCsv("WORKOUT SESSION HISTORY"));
    lines.push(
        escapeCsv("Session ID") + "," +
        escapeCsv("Date") + "," +
        escapeCsv("Workout Name") + "," +
        escapeCsv("Duration") + "," +
        escapeCsv("Calories Burned (kcal)") + "," +
        escapeCsv("Sets") + "," +
        escapeCsv("Reps") + "," +
        escapeCsv("Weight (kg)")
    );

    for (var i = 0; i < sessions.length; i++) {
        var itm = sessions[i];
        var dateText = formatSessionDate(itm.date);
        var durSec = parseInt(itm.duration) || 0;
        var durText = Formatters.formatDuration(durSec);
        var calText = String(Math.round(parseFloat(itm.calories) || 0));
        var setsRepsText = formatSetsReps(itm.sets, itm.reps);

        lines.push(
            escapeCsv(itm.id) + "," +
            escapeCsv(dateText) + "," +
            escapeCsv(itm.workout || "Workout") + "," +
            escapeCsv(durText) + "," +
            escapeCsv(calText) + "," +
            escapeCsv(itm.sets || "-") + "," +
            escapeCsv(setsRepsText) + "," +
            escapeCsv(itm.weight || "-")
        );
    }

    return lines.join("\r\n") + "\r\n";
}

function exportReport(format, timeframe, todayWaterMl, targetWaterMl) {
    var data = buildReportData(timeframe, todayWaterMl, targetWaterMl);
    var content = "";
    var extension = format === "csv" ? "csv" : "pdf";

    if (format === "csv") {
        content = generateCsv(data);
    } else {
        content = generatePdf(data);
    }

    var now = new Date();
    var timeStamp = Qt.formatDateTime(now, "yyyyMMdd_HHmmss");
    var fileName = "Fitness_Report_" + timeStamp + "." + extension;

    var targetPaths = [
        "/home/phablet/.local/share/personalfitnessapp.parvathy/" + fileName,
        "/tmp/" + fileName
    ];

    var writtenPath = "";
    var writtenUrl = "";

    for (var i = 0; i < targetPaths.length; i++) {
        var path = targetPaths[i];
        var fileUrl = "file://" + path;
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("PUT", fileUrl, false);
            xhr.send(content);
            if (xhr.status === 200 || xhr.status === 0 || xhr.status === 204) {
                writtenPath = path;
                writtenUrl = fileUrl;
                break;
            }
        } catch (e) {
            console.log("Failed writing to", fileUrl, e);
        }
    }

    // If writing to specific path failed, fallback to /tmp
    if (!writtenPath) {
        writtenPath = "/tmp/" + fileName;
        writtenUrl = "file://" + writtenPath;
        try {
            var fallbackXhr = new XMLHttpRequest();
            fallbackXhr.open("PUT", writtenUrl, false);
            fallbackXhr.send(content);
        } catch (err) {
            console.log("Fallback write failed:", err);
        }
    }

    return {
        success: true,
        fileName: fileName,
        filePath: writtenPath,
        fileUrl: writtenUrl,
        format: extension,
        fileSize: content.length,
        data: data
    };
}
