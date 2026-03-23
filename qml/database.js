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
            "date TEXT" +
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



function getSessions() {

    var db = getDatabase();
    var results = [];

    db.transaction(function(tx) {

        var rs = tx.executeSql("SELECT * FROM sessions ORDER BY id DESC");

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

function upsertSettings(weight, kcal, workouts, date) {
    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "INSERT OR REPLACE INTO settings (id, weight, kcal_target, num_workouts, date) VALUES (1, ?, ?, ?, ?)",
            [weight, kcal, workouts, date]
        )
    })
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



