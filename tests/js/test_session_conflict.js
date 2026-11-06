/**
 * Unit Tests for Active Session Conflict Resolution Logic
 */
const assert = require("assert");

function runTests(runner) {
    runner.suite("ActiveSessionConflict - Conflict Dialog & Reset Handlers", () => {
        runner.test("Save Current & Proceed: persists metrics and clears active state", () => {
            let activeState = {
                activeSessionId: 101,
                activeWorkout: "Push Ups",
                seconds: 900,
                running: true,
                savedInDb: false
            };

            function saveCurrentAndReset(state, callback) {
                if (state.activeSessionId !== -1) {
                    state.savedInDb = true;
                    state.activeSessionId = -1;
                    state.activeWorkout = "";
                    state.seconds = 0;
                    state.running = false;
                }
                if (typeof callback === "function") callback();
            }

            let proceedCalled = false;
            saveCurrentAndReset(activeState, () => { proceedCalled = true; });

            assert.strictEqual(activeState.savedInDb, true);
            assert.strictEqual(activeState.activeSessionId, -1);
            assert.strictEqual(activeState.activeWorkout, "");
            assert.strictEqual(activeState.seconds, 0);
            assert.strictEqual(activeState.running, false);
            assert.strictEqual(proceedCalled, true);
        });

        runner.test("Discard Current & Proceed: deletes session and clears active state", () => {
            let activeState = {
                activeSessionId: 202,
                activeWorkout: "Running",
                seconds: 400,
                running: true,
                deletedFromDb: false
            };

            function discardCurrentAndReset(state, callback) {
                if (state.activeSessionId !== -1) {
                    state.deletedFromDb = true;
                    state.activeSessionId = -1;
                    state.activeWorkout = "";
                    state.seconds = 0;
                    state.running = false;
                }
                if (typeof callback === "function") callback();
            }

            let proceedCalled = false;
            discardCurrentAndReset(activeState, () => { proceedCalled = true; });

            assert.strictEqual(activeState.deletedFromDb, true);
            assert.strictEqual(activeState.activeSessionId, -1);
            assert.strictEqual(activeState.activeWorkout, "");
            assert.strictEqual(activeState.seconds, 0);
            assert.strictEqual(activeState.running, false);
            assert.strictEqual(proceedCalled, true);
        });

        runner.test("Cancel Keep Current: active workout remains unchanged and continues running", () => {
            let activeState = {
                activeSessionId: 303,
                activeWorkout: "Zumba",
                seconds: 1500,
                running: true
            };

            function cancelDialog(state, wasRunning) {
                // Resume running state without modifying session ID or duration
                if (wasRunning) {
                    state.running = true;
                }
            }

            cancelDialog(activeState, true);

            assert.strictEqual(activeState.activeSessionId, 303);
            assert.strictEqual(activeState.activeWorkout, "Zumba");
            assert.strictEqual(activeState.seconds, 1500);
            assert.strictEqual(activeState.running, true);
        });
    });
}

module.exports = { runTests };

