.pragma library
.import "Database.js" as DBModule

function insertMediaVaultItem(sessionId, exercise, title, mediaType, fileName, fileUrl, date, duration, notes) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
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
    DBModule.createTable();
    var db = DBModule.getDatabase();
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
    DBModule.createTable();
    var db = DBModule.getDatabase();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM media_vault WHERE id = ?", [id]);
    });
}

function updateMediaVaultItem(id, title, exercise, notes) {
    DBModule.createTable();
    var db = DBModule.getDatabase();
    db.transaction(function(tx) {
        tx.executeSql(
            "UPDATE media_vault SET title = ?, exercise = ?, notes = ? WHERE id = ?",
            [title, exercise, notes, id]
        );
    });
}
