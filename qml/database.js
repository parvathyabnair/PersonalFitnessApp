.pragma library
.import QtQuick.LocalStorage 2.0 as LS

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
            "duration INTEGER" +
            ")"
        )

        //  Add new column (if not exists)
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN duration INTEGER")
        } catch(e) {
            console.log("Column may already exist")
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



