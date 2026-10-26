.pragma library

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
