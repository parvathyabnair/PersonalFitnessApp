.pragma library
.import "models/Database.js" as CoreDB
.import "models/WorkoutModel.js" as WorkoutModel
.import "models/MediaVaultModel.js" as MediaVaultModel
.import "models/SettingsModel.js" as SettingsModel
.import "utilities/MetCalculator.js" as MetCalc
.import "utilities/HealthCalculator.js" as HealthCalc
.import "utilities/Formatters.js" as Formatters

// Global active session state constants
var ACTIVE_SESSION_ID = -1;
var ACTIVE_WORKOUT = "";

// Database core lifecycle
function getDatabase() {
    return CoreDB.getDatabase();
}

function createTable() {
    return CoreDB.createTable();
}

// Workout session operations (delegated to WorkoutModel)
function insertSession(workout, sets, reps, weight, date) {
    return WorkoutModel.insertSession(workout, sets, reps, weight, date);
}

function getSessions(searchQuery) {
    return WorkoutModel.getSessions(searchQuery);
}

function deleteSession(id) {
    return WorkoutModel.deleteSession(id);
}

function updateSession(id, workout, sets, reps, weight, date) {
    return WorkoutModel.updateSession(id, workout, sets, reps, weight, date);
}

function updateSessionWorkoutName(id, workout) {
    return WorkoutModel.updateSessionWorkoutName(id, workout);
}

function updateSessionTime(id, time) {
    return WorkoutModel.updateSessionTime(id, time);
}

function updateSessionCalories(id, calories) {
    return WorkoutModel.updateSessionCalories(id, calories);
}

function getRoutines() {
    return WorkoutModel.getRoutines();
}

function insertRoutine(name, exercises) {
    return WorkoutModel.insertRoutine(name, exercises);
}

function deleteRoutine(id) {
    return WorkoutModel.deleteRoutine(id);
}

function getWorkoutStats() {
    return WorkoutModel.getWorkoutStats();
}

function getTodaysCalories() {
    return WorkoutModel.getTodaysCalories();
}

function getWeeklyCalories() {
    return WorkoutModel.getWeeklyCalories();
}

// Settings & Hydration operations (delegated to SettingsModel)
function upsertSettings(weight, kcal, workouts, date, goal_weight, gender, height, age) {
    return SettingsModel.upsertSettings(weight, kcal, workouts, date, goal_weight, gender, height, age);
}

function getSettings() {
    return SettingsModel.getSettings();
}

function getTodaysWater() {
    return SettingsModel.getTodaysWater();
}

function addWater(amount) {
    return SettingsModel.addWater(amount);
}

function resetTodaysWater() {
    return SettingsModel.resetTodaysWater();
}

// Privacy Media Vault operations (delegated to MediaVaultModel)
function insertMediaVaultItem(sessionId, exercise, title, mediaType, fileName, fileUrl, date, duration, notes) {
    return MediaVaultModel.insertMediaVaultItem(sessionId, exercise, title, mediaType, fileName, fileUrl, date, duration, notes);
}

function getMediaVaultItems(sessionId, mediaType) {
    return MediaVaultModel.getMediaVaultItems(sessionId, mediaType);
}

function deleteMediaVaultItem(id) {
    return MediaVaultModel.deleteMediaVaultItem(id);
}

function updateMediaVaultItem(id, title, exercise, notes) {
    return MediaVaultModel.updateMediaVaultItem(id, title, exercise, notes);
}

// Metabolic & Calorie calculations (delegated to MetCalculator)
var MET_DATA = MetCalc.MET_DATA;

function getMetValue(exerciseName) {
    return MetCalc.getMetValue(exerciseName);
}

function getMetIntensityInfo(met) {
    return MetCalc.getMetIntensityInfo(met);
}

function calculateMetCalories(exerciseName, weightKg, durationSeconds, intensityMultiplier) {
    return MetCalc.calculateMetCalories(exerciseName, weightKg, durationSeconds, intensityMultiplier);
}

// Health metrics (delegated to HealthCalculator)
function calculateBMI(weightKg, heightCm) {
    return HealthCalc.calculateBMI(weightKg, heightCm);
}

function calculateBMR(weightKg, heightCm, age, gender) {
    return HealthCalc.calculateBMR(weightKg, heightCm, age, gender);
}

// Formatters (delegated to Formatters)
function formatDuration(totalSeconds) {
    return Formatters.formatDuration(totalSeconds);
}

function formatCalories(calories) {
    return Formatters.formatCalories(calories);
}
