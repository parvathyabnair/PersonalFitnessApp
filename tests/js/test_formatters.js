/**
 * Unit Test Suite: Formatters.js
 * Tests time duration, calories, and weight string formatting utilities.
 */

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

function loadFormatters() {
    const filePath = path.resolve(__dirname, "../../qml/utilities/Formatters.js");
    let code = fs.readFileSync(filePath, "utf8");
    code = code.replace(/^\s*\.pragma\s+library\s*;?/m, "");
    const context = {
        Qt: {
            formatDate: (d, fmt) => d.toISOString().split("T")[0],
            formatDateTime: (d, fmt) => d.toISOString().replace("T", " ").substring(0, 16)
        }
    };
    vm.createContext(context);
    vm.runInContext(code, context);
    return context;
}

function runTests(runner) {
    const fmt = loadFormatters();

    runner.suite("Formatters.js - formatDuration", () => {
        runner.test("Formats 0 seconds as mm:ss", () => {
            assert.strictEqual(fmt.formatDuration(0), "00:00");
        });

        runner.test("Formats seconds < 60 as mm:ss", () => {
            assert.strictEqual(fmt.formatDuration(5), "00:05");
            assert.strictEqual(fmt.formatDuration(45), "00:45");
        });

        runner.test("Formats minutes and seconds < 1 hour as mm:ss", () => {
            assert.strictEqual(fmt.formatDuration(65), "01:05");
            assert.strictEqual(fmt.formatDuration(600), "10:00");
            assert.strictEqual(fmt.formatDuration(1800), "30:00");
            assert.strictEqual(fmt.formatDuration(3599), "59:59");
        });

        runner.test("Formats durations >= 1 hour as hh:mm:ss", () => {
            assert.strictEqual(fmt.formatDuration(3600), "01:00:00");
            assert.strictEqual(fmt.formatDuration(3665), "01:01:05");
            assert.strictEqual(fmt.formatDuration(7320), "02:02:00");
            assert.strictEqual(fmt.formatDuration(36000), "10:00:00");
        });

        runner.test("Handles null, negative, or invalid input safely", () => {
            assert.strictEqual(fmt.formatDuration(null), "00:00");
            assert.strictEqual(fmt.formatDuration(-10), "00:00");
            assert.strictEqual(fmt.formatDuration("invalid"), "00:00");
        });
    });

    runner.suite("Formatters.js - formatCalories", () => {
        runner.test("Formats integer calories to 1 decimal place with kcal", () => {
            assert.strictEqual(fmt.formatCalories(250), "250.0 kcal");
            assert.strictEqual(fmt.formatCalories(0), "0.0 kcal");
        });

        runner.test("Formats floating point calories with rounding", () => {
            assert.strictEqual(fmt.formatCalories(12.34), "12.3 kcal");
            assert.strictEqual(fmt.formatCalories(12.36), "12.4 kcal");
        });

        runner.test("Handles null or invalid input safely", () => {
            assert.strictEqual(fmt.formatCalories(null), "0.0 kcal");
            assert.strictEqual(fmt.formatCalories("xyz"), "0.0 kcal");
        });
    });

    runner.suite("Formatters.js - formatWeight", () => {
        runner.test("Formats weight with 1 decimal place and kg unit", () => {
            assert.strictEqual(fmt.formatWeight(70), "70.0 kg");
            assert.strictEqual(fmt.formatWeight(82.5), "82.5 kg");
        });

        runner.test("Handles null or invalid weight input safely", () => {
            assert.strictEqual(fmt.formatWeight(null), "0.0 kg");
            assert.strictEqual(fmt.formatWeight(""), "0.0 kg");
        });
    });
}

module.exports = { runTests };

