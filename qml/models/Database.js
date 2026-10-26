.pragma library
.import QtQuick.LocalStorage 2.0 as LS

var DB_NAME = "FitnessDB";
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Fitness Session Database";
var DB_SIZE = 1000000;

function getDatabase() {
    return LS.LocalStorage.openDatabaseSync(
        DB_NAME,
        DB_VERSION,
        DB_DESCRIPTION,
        DB_SIZE
    );
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
        );

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
        );

        // Create routines table if not exists
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS routines (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "name TEXT," +
            "exercises TEXT" +
            ")"
        );

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
        );

        // Create water tracking table
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS water_logs (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "date TEXT," +
            "amount INTEGER" +
            ")"
        );

        // Add new columns (if not exists)
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN duration INTEGER");
        } catch(e) {
            // Duration column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN calories REAL");
        } catch(e) {
            // Calories column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN goal_weight TEXT");
        } catch(e) {
            // Goal weight column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN gender TEXT");
        } catch(e) {
            // Gender column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE sessions ADD COLUMN reps TEXT");
        } catch(e) {
            // Reps column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN height TEXT");
        } catch(e) {
            // Height column may already exist
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN age TEXT");
        } catch(e) {
            // Age column may already exist
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
            console.log("Error checking/populating routines:", e);
        }
    });
}
