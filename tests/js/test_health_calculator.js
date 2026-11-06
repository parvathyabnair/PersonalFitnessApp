/**
 * Unit Test Suite: HealthCalculator.js
 * Tests BMI (Body Mass Index) and BMR (Mifflin-St Jeor formula) calculations.
 */

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadHealthCalculator() {
    const filePath = path.resolve(__dirname, "../../qml/utilities/HealthCalculator.js");
    let code = fs.readFileSync(filePath, "utf8");
    code = code.replace(/^\s*\.pragma\s+library\s*;?/m, "");
    const context = {};
    vm.createContext(context);
    vm.runInContext(code, context);
    return context;
}

function runTests(runner) {
    const calc = loadHealthCalculator();

    runner.suite("HealthCalculator.js - calculateBMI", () => {
        runner.test("Normal BMI classification (70kg, 175cm)", () => {
            const res = calc.calculateBMI(70, 175);
            assert.strictEqual(res.bmi, "22.9");
            assert.strictEqual(res.status, "Normal");
            assert.strictEqual(res.color, "#34D399");
        });

        runner.test("Underweight BMI classification (48kg, 175cm)", () => {
            const res = calc.calculateBMI(48, 175);
            assert.strictEqual(res.bmi, "15.7");
            assert.strictEqual(res.status, "Underweight");
            assert.strictEqual(res.color, "#79cff2");
        });

        runner.test("Overweight BMI classification (80kg, 170cm)", () => {
            const res = calc.calculateBMI(80, 170);
            assert.strictEqual(res.bmi, "27.7");
            assert.strictEqual(res.status, "Overweight");
            assert.strictEqual(res.color, "#FBBF24");
        });

        runner.test("Obese BMI classification (105kg, 170cm)", () => {
            const res = calc.calculateBMI(105, 170);
            assert.strictEqual(res.bmi, "36.3");
            assert.strictEqual(res.status, "Obese");
            assert.strictEqual(res.color, "#EF4444");
        });

        runner.test("Boundary: exactly 25.0 BMI should be Overweight", () => {
            // 72.25kg at 170cm = 72.25 / 2.89 = 25.0
            const res = calc.calculateBMI(72.25, 170);
            assert.strictEqual(res.bmi, "25.0");
            assert.strictEqual(res.status, "Overweight");
        });

        runner.test("Boundary: exactly 30.0 BMI should be Obese", () => {
            // 86.7kg at 170cm = 86.7 / 2.89 = 30.0
            const res = calc.calculateBMI(86.7, 170);
            assert.strictEqual(res.bmi, "30.0");
            assert.strictEqual(res.status, "Obese");
        });

        runner.test("Edge case: zero or negative height returns safe normal fallback", () => {
            const resZero = calc.calculateBMI(70, 0);
            assert.strictEqual(resZero.bmi, "22.9");
            assert.strictEqual(resZero.status, "Normal");

            const resNeg = calc.calculateBMI(70, -170);
            assert.strictEqual(resNeg.status, "Normal");
        });

        runner.test("Edge case: non-numeric inputs handle gracefully", () => {
            const res = calc.calculateBMI("invalid", "data");
            assert.strictEqual(res.status, "Normal");
            assert.strictEqual(res.bmi, "22.9");
        });
    });

    runner.suite("HealthCalculator.js - calculateBMR", () => {
        runner.test("Mifflin-St Jeor formula for Male (70kg, 175cm, 25yo)", () => {
            // (10 * 70) + (6.25 * 175) - (5 * 25) + 5 = 700 + 1093.75 - 125 + 5 = 1673.75 -> 1674
            const bmr = calc.calculateBMR(70, 175, 25, "Male");
            assert.strictEqual(bmr, 1674);
        });

        runner.test("Mifflin-St Jeor formula for Male (85kg, 182cm, 35yo)", () => {
            // (10 * 85) + (6.25 * 182) - (5 * 35) + 5 = 850 + 1137.5 - 175 + 5 = 1817.5 -> 1818
            const bmr = calc.calculateBMR(85, 182, 35, "Male");
            assert.strictEqual(bmr, 1818);
        });

        runner.test("Mifflin-St Jeor formula for Female (60kg, 165cm, 30yo)", () => {
            // (10 * 60) + (6.25 * 165) - (5 * 30) - 161 = 600 + 1031.25 - 150 - 161 = 1320.25 -> 1320
            const bmr = calc.calculateBMR(60, 165, 30, "Female");
            assert.strictEqual(bmr, 1320);
        });

        runner.test("Mifflin-St Jeor formula for Female (52kg, 160cm, 22yo)", () => {
            // (10 * 52) + (6.25 * 160) - (5 * 22) - 161 = 520 + 1000 - 110 - 161 = 1249
            const bmr = calc.calculateBMR(52, 160, 22, "Female");
            assert.strictEqual(bmr, 1249);
        });

        runner.test("Gender distinction check (male BMR must be higher than female for identical stats)", () => {
            const maleBmr = calc.calculateBMR(65, 170, 28, "Male");
            const femaleBmr = calc.calculateBMR(65, 170, 28, "Female");
            // Difference should be 5 - (-161) = 166
            assert.strictEqual(maleBmr - femaleBmr, 166);
        });

        runner.test("Edge case: zero or missing parameters return safe fallback", () => {
            const bmr = calc.calculateBMR(0, 0, 0, "Male");
            assert.ok(bmr > 0, "BMR must be a positive integer");
        });
    });
}

module.exports = { runTests };

