.pragma library

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
