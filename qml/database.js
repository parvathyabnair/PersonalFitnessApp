.pragma library
.import QtQuick.LocalStorage 2.0 as LS
var ACTIVE_SESSION_ID = -1
var ACTIVE_WORKOUT = ""

function getDatabase() {

    return LS.LocalStorage.openDatabaseSync(
                "FitnessDB",
                "1.0",
                "Fitness Session Database",
                1000000);
}


function createTable() {
    var db = getDatabase();

    db.transaction(function(tx) {

        // Create table if not exists
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS sessions (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "workout TEXT," +
            "sets TEXT," +
            "weight TEXT," +
            "date TEXT," +
            "duration INTEGER," +
            "calories REAL" +
            ")"
        )

        // Create settings table if not exists
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS settings (" +
            "id INTEGER PRIMARY KEY," +
            "weight TEXT," +
            "kcal_target TEXT," +
            "num_workouts TEXT," +
            "date TEXT," +
            "goal_weight TEXT," +
            "gender TEXT" +
            ")"
        )

        //  Add new column (if not exists)
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN duration INTEGER")
        } catch(e) {
            console.log("Duration column may already exist")
        }
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN calories REAL")
        } catch(e) {
            console.log("Calories column may already exist")
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN goal_weight TEXT")
        } catch(e) {
            console.log("Goal weight column may already exist")
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN gender TEXT")
        } catch(e) {
            console.log("Gender column may already exist")
        }
    })
}


function insertSession(workout, sets, weight, date) {
     var db = getDatabase();
    var insertedId = -1

    db.transaction(function(tx) {
        var rs = tx.executeSql(
            "INSERT INTO sessions (workout, sets, weight, date) VALUES (?, ?, ?, ?)",
            [workout, sets, weight, date]
        )
        insertedId = rs.insertId    
    })

    return insertedId
}



function getSessions(searchQuery) {

    var db = getDatabase();
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

    var db = getDatabase();

    db.transaction(function(tx) {

        tx.executeSql(
            "DELETE FROM sessions WHERE id= ?",
            [id]
        );

    });
}
function updateSession(id, workout, sets, weight, date) {

    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET workout=?, sets=?, weight=?, date=? WHERE id=?",
            [workout, sets, weight, date, id]
        );
    });
}



function updateSessionTime(id, time) {
    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET duration = ? WHERE id = ?",
            [time, id]
        )
    })
}

function updateSessionCalories(id, calories) {
    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET calories = ? WHERE id = ?",
            [calories, id]
        )
    })
}

function upsertSettings(weight, kcal, workouts, date, goal_weight, gender) {
    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "INSERT OR REPLACE INTO settings (id, weight, kcal_target, num_workouts, date, goal_weight, gender) VALUES (1, ?, ?, ?, ?, ?, ?)",
            [weight, kcal, workouts, date, goal_weight, gender]
        )
    })
}

function getTodaysCalories() {
    var db = getDatabase();
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

function getSettings() {
    var db = getDatabase();
    var settings = null;

    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT * FROM settings WHERE id = 1");
        if (rs.rows.length > 0) {
            settings = rs.rows.item(0);
        }
    });

    return settings;
}

function getWeeklyCalories() {
    var db = getDatabase();
    var results = [];
    var today = new Date();
    var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    var weekStart = new Date(todayStart.getTime() - today.getDay() * 24 * 60 * 60 * 1000);
    
    // Create entries for this week (Sunday to Saturday)
    for (var d = 0; d < 7; d++) {
        var dayDate = new Date(weekStart.getTime() + d * 24 * 60 * 60 * 1000);
        
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var label = dayDate.getDate().toString();
        if (d === 0) { // first day in chart
             label = monthNames[dayDate.getMonth()] + " " + label;
        }
        
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
