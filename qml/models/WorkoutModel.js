.pragma library
.import "Database.js" as DBModule

function insertSession(workout, sets, reps, weight, date) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var insertedId = -1;

    db.transaction(function(tx) {
        var rs = tx.executeSql(
            "INSERT INTO sessions (workout, sets, reps, weight, date) VALUES (?, ?, ?, ?, ?)",
            [workout, sets, reps, weight, date]
        );
        insertedId = rs.insertId;
    });

    return insertedId;
}

function getSessions(searchQuery) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var results = [];

    db.transaction(function(tx) {
        var sql = "SELECT * FROM sessions";
        var params = [];
        if (searchQuery) {
            sql += " WHERE workout LIKE ? OR date LIKE ?";
            params.push("%" + searchQuery + "%");
            params.push("%" + searchQuery + "%");
        }
        sql += " ORDER BY id DESC";

        var rs = tx.executeSql(sql, params);

        for (var i = 0; i < rs.rows.length; i++) {
            results.push(rs.rows.item(i));
        }
    });

    return results;
}

function deleteSession(id) {
    DBModule.createTable();
    var db = DBModule.getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "DELETE FROM sessions WHERE id= ?",
            [id]
        );
    });
}

function updateSession(id, workout, sets, reps, weight, date) {
    DBModule.createTable();
    var db = DBModule.getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET workout=?, sets=?, reps=?, weight=?, date=? WHERE id=?",
            [workout, sets, reps, weight, date, id]
        );
    });
}

function updateSessionTime(id, time) {
    DBModule.createTable();
    var db = DBModule.getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET duration = ? WHERE id = ?",
            [time, id]
        );
    });
}

function updateSessionCalories(id, calories) {
    DBModule.createTable();
    var db = DBModule.getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET calories = ? WHERE id = ?",
            [calories, id]
        );
    });
}

function getRoutines() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var results = [];
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT * FROM routines ORDER BY name ASC");
        for (var i = 0; i < rs.rows.length; i++) {
            results.push(rs.rows.item(i));
        }
    });
    return results;
}

function insertRoutine(name, exercises) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var insertedId = -1;
    db.transaction(function(tx) {
        var rs = tx.executeSql(
            "INSERT INTO routines (name, exercises) VALUES (?, ?)",
            [name, JSON.stringify(exercises)]
        );
        insertedId = rs.insertId;
    });
    return insertedId;
}

function deleteRoutine(id) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM routines WHERE id = ?", [id]);
    });
}

function getWorkoutStats() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var stats = {
        totalWorkouts: 0,
        totalDurationSeconds: 0,
        totalCalories: 0,
        streakDays: 0,
        thisMonthWorkouts: 0
    };
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT date, duration, calories FROM sessions ORDER BY date DESC");
        stats.totalWorkouts = rs.rows.length;
        
        var today = new Date();
        var currentYear = today.getFullYear();
        var currentMonth = today.getMonth();
        
        var datesSet = {};
        for (var i = 0; i < rs.rows.length; i++) {
            var item = rs.rows.item(i);
            stats.totalDurationSeconds += (item.duration || 0);
            stats.totalCalories += (parseFloat(item.calories) || 0);
            
            if (item.date) {
                var d = new Date(item.date);
                if (!isNaN(d.getTime())) {
                    if (d.getFullYear() === currentYear && d.getMonth() === currentMonth) {
                        stats.thisMonthWorkouts++;
                    }
                    var dateKey = Qt.formatDate(d, "yyyy-MM-dd");
                    datesSet[dateKey] = true;
                }
            }
        }
        
        // Calculate consecutive active days streak
        var checkDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        var todayKey = Qt.formatDate(checkDate, "yyyy-MM-dd");
        var streak = 0;
        if (!datesSet[todayKey]) {
            checkDate.setDate(checkDate.getDate() - 1);
        }
        while (datesSet[Qt.formatDate(checkDate, "yyyy-MM-dd")]) {
            streak++;
            checkDate.setDate(checkDate.getDate() - 1);
        }
        stats.streakDays = streak;
    });
    return stats;
}

function getTodaysCalories() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var totalCalories = 0;
    
    var today = new Date();
    var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    var todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    db.transaction(function(tx) {
        var sql = "SELECT date, calories FROM sessions";
        var rs = tx.executeSql(sql, []);
        
        for (var i = 0; i < rs.rows.length; i++) {
            var s = rs.rows.item(i);
            
            if (!s.date) continue;
            
            var sessionDate = new Date(s.date);
            if (isNaN(sessionDate.getTime())) continue;

            var sessionDateStart = new Date(sessionDate.getFullYear(), sessionDate.getMonth(), sessionDate.getDate());
            
            var include = true;
            if (sessionDateStart < todayStart || sessionDateStart >= todayEnd) {
                include = false;
            }
            
            if (include && s.calories) {
                totalCalories += parseFloat(s.calories) || 0;
            }
        }
    });

    return totalCalories || 0;
}

function getWeeklyCalories() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var results = [];
    var today = new Date();
    var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    var weekStart = new Date(todayStart.getTime() - today.getDay() * 24 * 60 * 60 * 1000);
    
    // Create entries for this week (Sunday to Saturday)
    var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    for (var d = 0; d < 7; d++) {
        var dayDate = new Date(weekStart.getTime() + d * 24 * 60 * 60 * 1000);
        var label = dayNames[dayDate.getDay()];
        
        results.push({
            dateObj: dayDate,
            dateLabel: label,
            calories: 0
        });
    }

    db.transaction(function(tx) {
        var sql = "SELECT date, calories FROM sessions";
        var rs = tx.executeSql(sql, []);
        
        for (var i = 0; i < rs.rows.length; i++) {
            var s = rs.rows.item(i);
            if (!s.date) continue;
            
            var sessionDate = new Date(s.date);
            if (isNaN(sessionDate.getTime())) continue;

            var sYear = sessionDate.getFullYear();
            var sMonth = sessionDate.getMonth();
            var sDate = sessionDate.getDate();
            
            for (var j = 0; j < 7; j++) {
                var dObj = results[j].dateObj;
                if (dObj.getFullYear() === sYear && 
                    dObj.getMonth() === sMonth && 
                    dObj.getDate() === sDate) {
                    
                    if (s.calories) {
                        results[j].calories += parseFloat(s.calories);
                    }
                    break;
                }
            }
        }
    });

    return results;
}
