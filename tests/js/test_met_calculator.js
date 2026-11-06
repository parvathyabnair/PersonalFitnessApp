/**
 * Unit Test Suite: MetCalculator.js
 * Tests Compendium of Physical Activities MET engine, calorie calculations, and intensity categorizations.
 */

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadMetCalculator() {
    const filePath = path.resolve(__dirname, "../../qml/utilities/MetCalculator.js");
    let code = fs.readFileSync(filePath, "utf8");
    code = code.replace(/^\s*\.pragma\s+library\s*;?/m, "");
    const context = {};
    vm.createContext(context);
    vm.runInContext(code, context);
    return context;
}

function runTests(runner) {
    const met = loadMetCalculator();

    runner.suite("MetCalculator.js - getMetValue", () => {
        runner.test("Exact exercise lookup", () => {
            assert.strictEqual(met.getMetValue("Push Ups"), 3.8);
            assert.strictEqual(met.getMetValue("Squats"), 6.0);
            assert.strictEqual(met.getMetValue("Zumba"), 6.5);
            assert.strictEqual(met.getMetValue("Running"), 9.8);
            assert.strictEqual(met.getMetValue("Jump Rope"), 11.5);
            assert.strictEqual(met.getMetValue("Resting"), 1.0);
            assert.strictEqual(met.getMetValue("Stretching"), 2.5);
            assert.strictEqual(met.getMetValue("General Workout"), 4.5);
        });

        runner.test("Case-insensitive and partial match lookup", () => {
            assert.strictEqual(met.getMetValue("push ups"), 3.8);
            assert.strictEqual(met.getMetValue("squats"), 6.0);
            assert.strictEqual(met.getMetValue("bicep curls"), 3.2);
            assert.strictEqual(met.getMetValue("running"), 9.8);
        });

        runner.test("Keyword categorization fallback", () => {
            assert.strictEqual(met.getMetValue("Outdoor Trail Run"), 9.8);
            assert.strictEqual(met.getMetValue("HIIT Fat Burner"), 8.0);
            assert.strictEqual(met.getMetValue("Morning Jump Session"), 11.5);
            assert.strictEqual(met.getMetValue("Heavy Squat Set"), 6.0);
            assert.strictEqual(met.getMetValue("Park Walk"), 4.3);
            assert.strictEqual(met.getMetValue("Vinyasa Yoga Flow"), 2.5);
        });

        runner.test("Unknown or empty exercise fallback to 4.5 METs", () => {
            assert.strictEqual(met.getMetValue("Unlisted Activity XYZ"), 4.5);
            assert.strictEqual(met.getMetValue(""), 4.5);
            assert.strictEqual(met.getMetValue(null), 4.5);
            assert.strictEqual(met.getMetValue(undefined), 4.5);
        });
    });

    runner.suite("MetCalculator.js - getMetIntensityInfo", () => {
        runner.test("Relaxed pace (< 3.0 METs)", () => {
            const info = met.getMetIntensityInfo(2.0);
            assert.strictEqual(info.category, "Relaxed Pace");
            assert.strictEqual(info.level, "light");
            assert.strictEqual(info.color, "#79cff2");
            assert.strictEqual(info.badge, "< 3.0 METs");
        });

        runner.test("Standard pace (3.0 - 6.0 METs)", () => {
            const info = met.getMetIntensityInfo(4.5);
            assert.strictEqual(info.category, "Standard Pace");
            assert.strictEqual(info.level, "moderate");
            assert.strictEqual(info.color, "#34D399");
            assert.strictEqual(info.badge, "3.0 - 6.0 METs");
        });

        runner.test("Intense pace (> 6.0 METs)", () => {
            const info = met.getMetIntensityInfo(8.0);
            assert.strictEqual(info.category, "Intense Pace");
            assert.strictEqual(info.level, "vigorous");
            assert.strictEqual(info.color, "#EF4444");
            assert.strictEqual(info.badge, "> 6.0 METs");
        });

        runner.test("Boundary values (3.0 and 6.0)", () => {
            const at3 = met.getMetIntensityInfo(3.0);
            assert.strictEqual(at3.category, "Standard Pace");

            const at6 = met.getMetIntensityInfo(6.0);
            assert.strictEqual(at6.category, "Standard Pace");
        });
    });

    runner.suite("MetCalculator.js - calculateMetCalories", () => {
        runner.test("1 hour General Workout (4.5 METs) for 70kg user at standard pace (1.0x)", () => {
            // 4.5 * 1.0 * 70kg * 1.0 hr = 315 kcal
            const cal = met.calculateMetCalories("General Workout", 70, 3600, 1.0);
            assert.strictEqual(cal, 315.0);
        });

        runner.test("30 min Zumba (6.5 METs) for 80kg user at standard pace (1.0x)", () => {
            // 6.5 * 1.0 * 80kg * 0.5 hr = 260 kcal
            const cal = met.calculateMetCalories("Zumba", 80, 1800, 1.0);
            assert.strictEqual(cal, 260.0);
        });

        runner.test("Pace multipliers scaling (Relaxed 0.85x, Standard 1.0x, Intense 1.2x)", () => {
            // Zumba 6.5 METs, 80kg, 1800s (0.5 hr)
            const relaxed = met.calculateMetCalories("Zumba", 80, 1800, 0.85);
            // 6.5 * 0.85 * 80 * 0.5 = 221 kcal
            assert.strictEqual(Math.round(relaxed * 10) / 10, 221.0);

            const standard = met.calculateMetCalories("Zumba", 80, 1800, 1.0);
            assert.strictEqual(Math.round(standard * 10) / 10, 260.0);

            const intense = met.calculateMetCalories("Zumba", 80, 1800, 1.2);
            // 6.5 * 1.2 * 80 * 0.5 = 312 kcal
            assert.strictEqual(Math.round(intense * 10) / 10, 312.0);
        });

        runner.test("Zero duration produces 0 kcal", () => {
            const cal = met.calculateMetCalories("Running", 75, 0, 1.0);
            assert.strictEqual(cal, 0);
        });

        runner.test("Defaults applied when weight or multiplier omitted", () => {
            // Default weight is 70kg, default multiplier is 1.0
            const cal = met.calculateMetCalories("General Workout", null, 3600, null);
            assert.strictEqual(cal, 315.0);
        });
    });
}

module.exports = { runTests };
