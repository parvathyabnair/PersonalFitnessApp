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

        tx.executeSql(
        "CREATE TABLE IF NOT EXISTS sessions \
        (id INTEGER PRIMARY KEY AUTOINCREMENT, \
        workout TEXT, \
        sets TEXT, \
        weight TEXT, \
        date DATE)"
        );

    });
}


function insertSession(workout, sets, weight, date) {

    var db = getDatabase();

    db.transaction(function(tx) {

        tx.executeSql(
        "INSERT INTO sessions (workout, sets, weight, date) VALUES (?,?,?,?)",
        [workout, sets, weight, date]);

    });

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
