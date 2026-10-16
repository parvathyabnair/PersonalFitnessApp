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
            "reps TEXT," +
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

        // Create routines table if not exists
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS routines (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "name TEXT," +
            "exercises TEXT" +
            ")"
        )

        // Create media vault table for private form-checks & progress photos
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS media_vault (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "session_id INTEGER," +
            "exercise TEXT," +
            "title TEXT," +
            "media_type TEXT," +
            "file_name TEXT," +
            "file_url TEXT," +
            "date TEXT," +
            "duration INTEGER," +
            "notes TEXT," +
            "is_private INTEGER DEFAULT 1" +
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
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN reps TEXT")
        } catch(e) {
            console.log("Reps column may already exist")
        }

        // Pre-populate default routines if table is empty
        try {
            var rs = tx.executeSql("SELECT COUNT(*) as count FROM routines");
            if (rs.rows.item(0).count === 0) {
                tx.executeSql("INSERT INTO routines (name, exercises) VALUES (?, ?)", ["Push Day", JSON.stringify(["Dumbbell Bench Press", "Push Ups"])]);
                tx.executeSql("INSERT INTO routines (name, exercises) VALUES (?, ?)", ["Legs", JSON.stringify(["Squats", "Deadlift"])]);
                tx.executeSql("INSERT INTO routines (name, exercises) VALUES (?, ?)", ["Full Body", JSON.stringify(["Squats", "Deadlift", "Push Ups"])]);
            }
        } catch (e) {
            console.log("Error checking/populating routines:", e)
        }
    })
}


function insertSession(workout, sets, reps, weight, date) {
     var db = getDatabase();
    var insertedId = -1

    db.transaction(function(tx) {
        var rs = tx.executeSql(
            "INSERT INTO sessions (workout, sets, reps, weight, date) VALUES (?, ?, ?, ?, ?)",
            [workout, sets, reps, weight, date]
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
function updateSession(id, workout, sets, reps, weight, date) {

    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE sessions SET workout=?, sets=?, reps=?, weight=?, date=? WHERE id=?",
            [workout, sets, reps, weight, date, id]
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

function getRoutines() {
    var db = getDatabase();
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
    var db = getDatabase();
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
    var db = getDatabase();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM routines WHERE id = ?", [id]);
    });
}

// PRIVACY MEDIA VAULT FUNCTIONS (Form-checks & Progress Photos)
function insertMediaVaultItem(sessionId, exercise, title, mediaType, fileName, fileUrl, date, duration, notes) {
    var db = getDatabase();
    var insertedId = -1;
    db.transaction(function(tx) {
        var rs = tx.executeSql(
            "INSERT INTO media_vault (session_id, exercise, title, media_type, file_name, file_url, date, duration, notes, is_private) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)",
            [sessionId, exercise, title, mediaType, fileName, fileUrl, date, duration, notes]
        );
        insertedId = rs.insertId;
    });
    return insertedId;
}

function getMediaVaultItems(sessionId, mediaType) {
    var db = getDatabase();
    var results = [];
    db.transaction(function(tx) {
        var query = "SELECT * FROM media_vault WHERE 1=1";
        var params = [];
        if (sessionId && sessionId !== -1) {
            query += " AND session_id = ?";
            params.push(sessionId);
        }
        if (mediaType && mediaType !== "all") {
            query += " AND media_type = ?";
            params.push(mediaType);
        }
        query += " ORDER BY id DESC";
        var rs = tx.executeSql(query, params);
        for (var i = 0; i < rs.rows.length; i++) {
            results.push(rs.rows.item(i));
        }
    });
    return results;
}

function deleteMediaVaultItem(id) {
    var db = getDatabase();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM media_vault WHERE id = ?", [id]);
    });
}

