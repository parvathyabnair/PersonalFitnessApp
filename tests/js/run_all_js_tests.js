#!/usr/bin/env node
/**
 * Test Runner: JavaScript Unit Tests
 * Executes all JS unit test suites and outputs test execution metrics.
 */

const path = require("path");

class TestRunner {
    constructor() {
        this.currentSuite = "";
        this.totalTests = 0;
        this.passed = 0;
        this.failed = 0;
        this.errors = [];
    }

    suite(name, fn) {
        this.currentSuite = name;
        console.log(`\n\x1b[36m▶ Suite: ${name}\x1b[0m`);
        fn();
    }

    test(name, fn) {
        this.totalTests++;
        try {
            fn();
            this.passed++;
            console.log(`  \x1b[32m✔\x1b[0m ${name}`);
        } catch (err) {
            this.failed++;
            console.error(`  \x1b[31m✖\x1b[0m ${name}`);
            console.error(`    \x1b[31m${err.message}\x1b[0m`);
            this.errors.push({ suite: this.currentSuite, test: name, error: err });
        }
    }

    summary() {
        console.log("\n==========================================");
        console.log("\x1b[1mJavaScript Unit Test Results\x1b[0m");
        console.log("==========================================");
        console.log(`Total Tests Run: ${this.totalTests}`);
        console.log(`\x1b[32mPassed:          ${this.passed}\x1b[0m`);
        if (this.failed > 0) {
            console.log(`\x1b[31mFailed:          ${this.failed}\x1b[0m`);
            console.log("\nFailure Details:");
            this.errors.forEach(e => {
                console.log(` - [${e.suite}] ${e.test}: ${e.error.message}`);
            });
            return false;
        } else {
            console.log(`\x1b[32mAll JavaScript unit test suites passed successfully!\x1b[0m`);
            return true;
        }
    }
}

function main() {
    console.log("==========================================");
    console.log("Starting PersonalFitnessApp JS Unit Tests");
    console.log("==========================================");

    const runner = new TestRunner();

    const testSuites = [
        require("./test_health_calculator.js"),
        require("./test_met_calculator.js"),
        require("./test_formatters.js"),
        require("./test_database_models.js"),
        require("./test_session_conflict.js")
    ];

    for (const suite of testSuites) {
        suite.runTests(runner);
    }

    const success = runner.summary();
    process.exit(success ? 0 : 1);
}

if (require.main === module) {
    main();
}

module.exports = { TestRunner };

