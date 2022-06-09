CREATE PROCEDURE msqta.spPurgeData
@sessionObject	msqta.TuningSessionType		READONLY,
@queryObject	msqta.TuningQueryType		READONLY,
@databaseName								varchar(256),
@mode										tinyint
AS

/*
------------------------------------------------------------
Copyright (c) Microsoft Corporation.  All rights reserved.
Licensed under the Source EULA. See License.txt in the project root for license information.
------------------------------------------------------------

Deletes persisted Session and Query data from database. It operates in multiple modes as defined below

case @mode = 0:
    Purge queries and its properties from database.
    This operation might leave an empty session in database. If queries getting purged
    are part of some session.
    Caller needs to pass in @queryObject

case @mode = 1: 
    Purge session and its properties from database.
    Query belonging to this session remains in the database.
    Caller needs to pass in @sessionObject

case @mode = 2:
    Purge session and its properties from database.
    This also purges query which are part of this session.
    Caller needs to pass in @sessionObject

case @mode = 3:
    Purge all sessions and its properties from database except current active session.
    Query belonging to this session remains in the database.
    Caller needs to pass @databaseName

case @mode = 4:
    Purge all sessions and its properties from database except current active session.
    This also purges query which are part of this session.
    Caller needs to pass @databaseName
*/

BEGIN TRANSACTION

BEGIN TRY

    IF @mode = 0 AND (SELECT COUNT(*) FROM @queryObject) > 0
    BEGIN
        DELETE query 
        FROM msqta.TuningQuery query 
        INNER JOIN @queryObject queryObject ON queryObject.QueryID = query.QueryID AND DB_ID(queryObject.DatabaseName) = query.DatabaseID
        -- delete cascade  will take care of foreign keys
    END
    IF @mode = 1 AND (SELECT COUNT(*) FROM @sessionObject) > 0
    BEGIN
        DELETE session
        FROM msqta.TuningSession session
        INNER JOIN @sessionObject sessionObject ON sessionObject.TuningSessionID = session.TuningSessionID
        WHERE session.Status != 0
        -- delete cascade  will take care of foreign keys
    END
    IF @mode = 2 AND (SELECT COUNT(*) FROM @sessionObject) > 0
    BEGIN
        DELETE query 
        FROM msqta.TuningQuery query 
        INNER JOIN msqta.TuningSession_TuningQuery session_query ON session_query.TuningQueryID = query.TuningQueryID
        INNER JOIN msqta.TuningSession session ON session.TuningSessionID = session_query.TuningSessionID
        INNER JOIN @sessionObject sessionObject ON sessionObject.TuningSessionID = session_query.TuningSessionID
        WHERE session.Status != 0

        DELETE session
        FROM msqta.TuningSession session
        INNER JOIN @sessionObject sessionObject ON sessionObject.TuningSessionID = session.TuningSessionID
        WHERE session.Status != 0
        -- delete cascade  will take care of foreign keys
    END
    IF @mode = 3
    BEGIN
        DELETE session
        FROM msqta.TuningSession session WHERE session.DatabaseID = DB_ID(@databaseName) AND session.Status != 0
        -- delete cascade  will take care of foreign keys
    END
    IF @mode = 4
    BEGIN
        DELETE query 
        FROM msqta.TuningQuery query 
        INNER JOIN msqta.TuningSession_TuningQuery session_query ON session_query.TuningQueryID = query.TuningQueryID
        INNER JOIN msqta.TuningSession session ON session.TuningSessionID = session_query.TuningSessionID
        WHERE session.DatabaseID = DB_ID(@databaseName) AND session.Status != 0

        DELETE session
        FROM msqta.TuningSession session WHERE session.DatabaseID = DB_ID(@databaseName) AND session.Status != 0
        -- delete cascade  will take care of foreign keys
    END
END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW

END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;