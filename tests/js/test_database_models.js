/**
 * Unit Test Suite: Database & Models (WorkoutModel, SettingsModel, MediaVaultModel)
 * Tests SQLite persistence layer operations using a lightweight transactional mock.
 */

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

// Mock LocalStorage SQLite environment
function createMockDb() {
    const tables = {
        sessions: [],
        settings: [],
        water_logs: [],
        routines: [],
        media_vault: []
    };
    let nextId = 1;

    const db = {
        transaction: (callback) => {
            const tx = {
                executeSql: (sql, params = []) => {
                    const normalized = sql.trim().toUpperCase();

                    if (normalized.startsWith("CREATE TABLE")) {
                        return { rows: { length: 0 } };
                    }

                    if (normalized.startsWith("INSERT INTO SESSIONS")) {
                        const row = {
                            id: nextId++,
                            workout: params[0],
                            sets: params[1],
                            reps: params[2],
                            weight: params[3],
                            date: params[4],
                            duration: 0,
                            calories: 0.0
                        };
                        tables.sessions.push(row);
                        return { insertId: row.id, rowsAffected: 1, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("SELECT * FROM SESSIONS WHERE ID =")) {
                        const id = params[0];
                        const found = tables.sessions.filter(s => s.id === id);
                        return {
                            rows: {
                                length: found.length,
                                item: (i) => found[i]
                            }
                        };
                    }

                    if (normalized.startsWith("UPDATE SESSIONS SET DURATION =") || normalized.startsWith("UPDATE SESSIONS SET TIME =")) {
                        const time = params[0];
                        const id = params[1];
                        const s = tables.sessions.find(x => x.id === id);
                        if (s) s.duration = time;
                        return { rowsAffected: s ? 1 : 0, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("UPDATE SESSIONS SET CALORIES =")) {
                        const cal = params[0];
                        const id = params[1];
                        const s = tables.sessions.find(x => x.id === id);
                        if (s) s.calories = cal;
                        return { rowsAffected: s ? 1 : 0, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("DELETE FROM SESSIONS WHERE ID")) {
                        const id = params[0];
                        const idx = tables.sessions.findIndex(s => s.id === id);
                        if (idx !== -1) tables.sessions.splice(idx, 1);
                        return { rowsAffected: 1, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("INSERT OR REPLACE INTO SETTINGS")) {
                        const setting = {
                            id: 1,
                            weight: params[0],
                            kcal_target: params[1],
                            num_workouts: params[2],
                            date: params[3],
                            goal_weight: params[4],
                            gender: params[5],
                            height: params[6] || "175",
                            age: params[7] || "25"
                        };
                        tables.settings = [setting];
                        return { rowsAffected: 1, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("SELECT * FROM SETTINGS")) {
                        return {
                            rows: {
                                length: tables.settings.length,
                                item: (i) => tables.settings[i]
                            }
                        };
                    }

                    if (normalized.startsWith("INSERT INTO WATER_LOGS")) {
                        tables.water_logs.push({ date: params[0], amount: params[1] });
                        return { rowsAffected: 1, rows: { length: 0 } };
                    }

                    if (normalized.startsWith("SELECT SUM(AMOUNT) AS TOTAL FROM WATER_LOGS")) {
                        const date = params[0];
                        const logs = tables.water_logs.filter(w => w.date === date);
                        const total = logs.reduce((sum, item) => sum + Number(item.amount), 0);
                        return {
                            rows: {
                                length: 1,
                                item: () => ({ total: total })
                            }
                        };
                    }

                    if (normalized.startsWith("DELETE FROM WATER_LOGS")) {
                        const date = params[0];
                        tables.water_logs = tables.water_logs.filter(w => w.date !== date);
                        return { rowsAffected: 1, rows: { length: 0 } };
                    }

                    return { rows: { length: 0 } };
                }
            };
            callback(tx);
        }
    };

    return db;
}

function runTests(runner) {
    const mockDb = createMockDb();

    // Create sandbox with mock DB module
    const dbModuleContext = {
        getDatabase: () => mockDb,
        createTable: () => {}
    };

    function loadWorkoutModel() {
        const filePath = path.resolve(__dirname, "../../qml/models/WorkoutModel.js");
        let code = fs.readFileSync(filePath, "utf8");
        code = code.replace(/^\s*\.pragma\s+library\s*;?/m, "");
        code = code.replace(/^\s*\.import\s+.*$/mg, "");

        const context = {
            DBModule: dbModuleContext,
            Qt: { formatDate: (d, fmt) => d.toISOString().split("T")[0] }
        };
        vm.createContext(context);
        vm.runInContext(code, context);
        return context;
    }

    function loadSettingsModel() {
        const filePath = path.resolve(__dirname, "../../qml/models/SettingsModel.js");
        let code = fs.readFileSync(filePath, "utf8");
        code = code.replace(/^\s*\.pragma\s+library\s*;?/m, "");
        code = code.replace(/^\s*\.import\s+.*$/mg, "");

        const context = {
            DBModule: dbModuleContext,
            Qt: { formatDate: (d, fmt) => d.toISOString().split("T")[0] }
        };
        vm.createContext(context);
        vm.runInContext(code, context);
        return context;
    }

    const workoutModel = loadWorkoutModel();
    const settingsModel = loadSettingsModel();

    runner.suite("WorkoutModel.js - Session CRUD", () => {
        let createdSessionId = -1;

        runner.test("insertSession creates a session with valid autoincrement ID", () => {
            createdSessionId = workoutModel.insertSession(
                "Bench Press",
                "3",
                JSON.stringify(["10", "10", "8"]),
                JSON.stringify(["60", "70", "75"]),
                "2026-11-06"
            );
            assert.ok(createdSessionId > 0, "Inserted ID should be > 0");
        });

        runner.test("getSessionById returns the created session data", () => {
            const s = workoutModel.getSessionById(createdSessionId);
            assert.ok(s !== null, "Session should exist");
            assert.strictEqual(s.workout, "Bench Press");
            assert.strictEqual(s.sets, "3");
        });

        runner.test("updateSessionCalories updates burned calorie metric", () => {
            workoutModel.updateSessionCalories(createdSessionId, 245.5);
            const s = workoutModel.getSessionById(createdSessionId);
            assert.strictEqual(s.calories, 245.5);
        });

        runner.test("deleteSession removes the session from SQLite", () => {
            workoutModel.deleteSession(createdSessionId);
            const s = workoutModel.getSessionById(createdSessionId);
            assert.strictEqual(s, null);
        });
    });

    runner.suite("SettingsModel.js - Profile & Hydration", () => {
        runner.test("upsertSettings saves user metrics", () => {
            settingsModel.upsertSettings("75", "2200", "4", "2026-11-06", "70", "Male", "180", "28");
            const s = settingsModel.getSettings();
            assert.ok(s !== null);
            assert.strictEqual(s.weight, "75");
            assert.strictEqual(s.gender, "Male");
            assert.strictEqual(s.height, "180");
        });

        runner.test("addWater logs water intake and sums daily total", () => {
            settingsModel.resetTodaysWater();
            settingsModel.addWater(250);
            settingsModel.addWater(500);
            const total = settingsModel.getTodaysWater();
            assert.strictEqual(total, 750);
        });

        runner.test("resetTodaysWater clears water logs for the day", () => {
            settingsModel.resetTodaysWater();
            const total = settingsModel.getTodaysWater();
            assert.strictEqual(total, 0);
        });
    });
}

module.exports = { runTests };

