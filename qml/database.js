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

        // Create water tracking table
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS water_logs (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "date TEXT," +
            "amount INTEGER" +
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
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN height TEXT")
        } catch(e) {
            console.log("Height column may already exist")
        }
        try {
            tx.executeSql("ALTER TABLE settings ADD COLUMN age TEXT")
        } catch(e) {
            console.log("Age column may already exist")
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

function upsertSettings(weight, kcal, workouts, date, goal_weight, gender, height, age) {
    var db = getDatabase();

    db.transaction(function(tx) {
        tx.executeSql(
            "INSERT OR REPLACE INTO settings (id, weight, kcal_target, num_workouts, date, goal_weight, gender, height, age) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)",
            [weight, kcal, workouts, date, goal_weight, gender, height || "175", age || "25"]
        )
    })
}

// ==========================================
// COMPENDIUM OF PHYSICAL ACTIVITIES - MET ENGINE
// Formula: Calories Burned = MET Value × Weight (in kg) × Duration (in hours)
// Standard reference: Compendium of Physical Activities
// ==========================================
var MET_DATA = {
    // Light Activity (< 3.0 METs)
    "Sitting quietly / Resting": 1.0,
    "Resting": 1.0,
    "Stretching (Hatha Yoga)": 2.5,
    "Stretching": 2.5,
    "Yoga": 2.5,
    "Walking slowly (strolling)": 2.0,
    "Walking slowly": 2.0,
    "Light calisthenics": 2.8,

    // Moderate Activity (3.0 to 6.0 METs)
    "Weightlifting (light/moderate)": 3.5,
    "Weightlifting (light to moderate effort, typical gym workout)": 3.5,
    "Dumbbell Bench Press": 3.5,
    "Shoulder Press": 3.5,
    "Triceps": 3.2,
    "Lateral Raises": 3.2,
    "Leg Extensions and Curls": 3.5,
    "Calf Raises": 3.0,
    "Bicep Curls": 3.2,
    "Push Ups": 3.8,
    "Planks": 3.8,
    "Lunges": 4.0,
    "Walking briskly": 4.3,
    "Walking briskly (3.0 mph / 4.8 km/h)": 4.3,
    "Treadmill Walk": 4.3,
    "Bicycling (leisurely)": 4.0,
    "Bicycling (leisurely, < 10 mph)": 4.0,
    "Cycling": 4.0,
    "Power Yoga / Vinyasa": 4.0,
    "Calisthenics (moderate)": 3.8,
    "Calisthenics (moderate effort - e.g., crunches, pushups in sets)": 3.8,
    "Swimming": 5.5,
    "Rowing": 5.8,
    "Elliptical": 5.0,
    "Push": 5.0,
    "Pull": 5.0,
    "General Workout": 4.5,
    "Workout": 4.5,
    "Custom Workout": 4.5,

    // Vigorous Activity (> 6.0 METs)
    "Weightlifting (heavy resistance)": 6.0,
    "Weightlifting (heavy resistance, powerlifting, bodybuilding)": 6.0,
    "Squats": 6.0,
    "Deadlift": 6.0,
    "Bench Press": 6.0,
    "Pull-ups and Chin-ups": 6.0,
    "Full Body": 6.0,
    "Zumba": 6.5,
    "Circuit training": 8.0,
    "Circuit training (kettlebells, high heart rate)": 8.0,
    "Jogging": 8.3,
    "Jogging (5.0 mph / 8 km/h)": 8.3,
    "Running": 9.8,
    "Running (6.0 mph / 9.6 km/h)": 9.8,
    "Bicycling (vigorous)": 10.0,
    "Bicycling (vigorous, 14-15 mph)": 10.0,
    "Stair Climber": 8.5,
    "HIIT Workout": 8.5,
    "Jump Rope": 11.5,
    "Jumping rope (moderate pace)": 11.5
};

function getMetValue(exerciseName) {
    if (!exerciseName) return 4.5;
    // Exact match
    if (MET_DATA[exerciseName] !== undefined) {
        return MET_DATA[exerciseName];
    }
    // Partial search
    var lower = exerciseName.toLowerCase();
    for (var key in MET_DATA) {
        if (lower.indexOf(key.toLowerCase()) !== -1 || key.toLowerCase().indexOf(lower) !== -1) {
            return MET_DATA[key];
        }
    }
    // Keyword categorization
    if (lower.indexOf("run") !== -1 || lower.indexOf("sprint") !== -1) return 9.8;
    if (lower.indexOf("jump") !== -1 || lower.indexOf("rope") !== -1) return 11.5;
    if (lower.indexOf("hiit") !== -1 || lower.indexOf("circuit") !== -1) return 8.0;
    if (lower.indexOf("squat") !== -1 || lower.indexOf("deadlift") !== -1 || lower.indexOf("bench") !== -1) return 6.0;
    if (lower.indexOf("cycle") !== -1 || lower.indexOf("bike") !== -1) return 6.0;
    if (lower.indexOf("walk") !== -1) return 4.3;
    if (lower.indexOf("yoga") !== -1 || lower.indexOf("stretch") !== -1) return 2.5;

    return 4.5;
}

function getMetIntensityInfo(met) {
    var m = parseFloat(met) || 1.0;
    if (m < 3.0) {
        return {
            category: "Light Activity",
            label: "Light Activity",
            color: "#38BDF8", // Vibrant Sky Blue
            badge: "< 3.0 METs",
            level: "light",
            description: "Low exertion baseline (e.g. stretching, casual walking)"
        };
    } else if (m <= 6.0) {
        return {
            category: "Moderate Activity",
            label: "Moderate Activity",
            color: "#34D399", // Emerald Green
            badge: "3.0 - 6.0 METs",
            level: "moderate",
            description: "Aerobic / gym resistance effort (e.g. lifting, brisk walking)"
        };
    } else {
        return {
            category: "Vigorous Activity",
            label: "Vigorous Activity",
            color: "#EF4444", // Crimson / Red
            badge: "> 6.0 METs",
            level: "vigorous",
            description: "High intensity exertion (e.g. heavy lifting, running, jump rope)"
        };
    }
}

function calculateMetCalories(exerciseName, weightKg, durationSeconds, intensityMultiplier) {
    var met = getMetValue(exerciseName);
    var mult = (intensityMultiplier !== undefined && intensityMultiplier > 0) ? intensityMultiplier : 1.0;
    var w = (weightKg && weightKg > 0) ? parseFloat(weightKg) : 70.0;
    var durationHours = (durationSeconds && durationSeconds > 0) ? (durationSeconds / 3600.0) : 0;
    return (met * mult) * w * durationHours;
}

// Health Metrics: BMI & BMR (Mifflin-St Jeor formula)
function calculateBMI(weightKg, heightCm) {
    var w = parseFloat(weightKg) || 70;
    var h = (parseFloat(heightCm) || 175) / 100.0;
    if (h <= 0) return { bmi: "22.9", status: "Normal", color: "#34D399" };
    var bmiVal = w / (h * h);
    if (isNaN(bmiVal) || bmiVal <= 0) return { bmi: "22.9", status: "Normal", color: "#34D399" };
    var status = "Normal";
    var color = "#34D399";
    if (bmiVal < 18.5) {
        status = "Underweight";
        color = "#38BDF8";
    } else if (bmiVal >= 25.0 && bmiVal < 30.0) {
        status = "Overweight";
        color = "#FBBF24";
    } else if (bmiVal >= 30.0) {
        status = "Obese";
        color = "#EF4444";
    }
    return {
        bmi: bmiVal.toFixed(1),
        status: status,
        color: color
    };
}

function calculateBMR(weightKg, heightCm, age, gender) {
    var w = parseFloat(weightKg) || 70;
    var h = parseFloat(heightCm) || 175;
    var a = parseInt(age) || 25;
    var isMale = (gender !== "Female");
    // BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + (5 for male, -161 for female)
    var bmr = (10 * w) + (6.25 * h) - (5 * a) + (isMale ? 5 : -161);
    if (isNaN(bmr) || bmr <= 0) return 1650;
    return Math.round(bmr);
}

// Water / Hydration Tracker Functions
function getTodaysWater() {
    createTable();
    var db = getDatabase();
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
    createTable();
    var db = getDatabase();
    var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
    db.transaction(function(tx) {
        tx.executeSql("INSERT INTO water_logs (date, amount) VALUES (?, ?)", [todayStr, amount]);
    });
    return getTodaysWater();
}

function resetTodaysWater() {
    createTable();
    var db = getDatabase();
    var todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM water_logs WHERE date = ?", [todayStr]);
    });
    return 0;
}

// Workout Stats & Streaks
function getWorkoutStats() {
    createTable();
    var db = getDatabase();
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
    createTable();
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
    createTable();
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

function updateMediaVaultItem(id, title, exercise, notes) {
    createTable();
    var db = getDatabase();
    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE media_vault SET title = ?, exercise = ?, notes = ? WHERE id = ?",
            [title, exercise, notes, id]
        );
    });
}

