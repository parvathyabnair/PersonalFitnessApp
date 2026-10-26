.pragma library
.import "Database.js" as DBModule

function upsertSettings(weight, kcal, workouts, date, goal_weight, gender, height, age) {
    DBModule.createTable();
    var db = DBModule.getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "INSERT OR REPLACE INTO settings (id, weight, kcal_target, num_workouts, date, goal_weight, gender, height, age) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)",
            [weight, kcal, workouts, date, goal_weight, gender, height || "175", age || "25"]
        );
    });
}

function getSettings() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var settings = null;

    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT * FROM settings WHERE id = 1");
        if (rs.rows.length > 0) {
            settings = rs.rows.item(0);
        }
    });

    return settings;
}

function getTodaysWater() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
    var total = 0;
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT SUM(amount) as total FROM water_logs WHERE date = ?", [todayStr]);
        if (rs.rows.length > 0 && rs.rows.item(0).total) {
            total = rs.rows.item(0).total;
        }
    });
    return total;
}

function addWater(amount) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
    db.transaction(function(tx) {
        tx.executeSql("INSERT INTO water_logs (date, amount) VALUES (?, ?)", [todayStr, amount]);
    });
    return getTodaysWater();
}

function resetTodaysWater() {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM water_logs WHERE date = ?", [todayStr]);
    });
    return 0;
}
