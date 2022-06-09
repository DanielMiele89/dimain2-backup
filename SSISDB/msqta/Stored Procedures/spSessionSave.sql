CREATE PROCEDURE msqta.spSessionSave
@sessionObject				msqta.TuningSessionType		READONLY,
@queryObject				msqta.TuningQueryType		READONLY,
@queryOptionGroupObject		msqta.QueryOptionGroupType	READONLY,
@queryExecutionStatObject	msqta.ExecutionStatType		READONLY
AS

/*
------------------------------------------------------------
Copyright (c) Microsoft Corporation.  All rights reserved.
Licensed under the Source EULA. See License.txt in the project root for license information.
------------------------------------------------------------

Persist tuning Session into database. 
@sessionObject				- UDT for TuningSession
@queryObject				- UDT for TuningQuery
@queryOptionGroupObject		- UDT from QueryOptionObject
@queryExecutionStatObject	- UDT for ExecutionStat

*/

BEGIN TRANSACTION

BEGIN TRY

    -- Verify Database name is valid for query records
    IF (SELECT COUNT(*) FROM @sessionObject WHERE DB_ID(DatabaseName) IS NULL) > 0
    BEGIN
        THROW 51000, 'Cannot find database against which session is saved.', 1
    END

    -- we only handle single session update for now
    IF (SELECT COUNT(*) FROM @sessionObject) > 1
    BEGIN
        THROW 51000, 'Cannot process multiple sessions.', 1
    END

    DECLARE @sessionId AS int
    SET @sessionId = (SELECT TOP(1) TuningSessionID FROM @sessionObject)

    DECLARE @databaseId AS int
    SET @databaseId = (SELECT TOP(1) DB_ID(DatabaseName) FROM @sessionObject)
        
    IF @sessionId > 0
    BEGIN
        /*
        If session already exists, (this is update session request)
            - Update session properties
            - Update Queries
            - Drop existing session-query mappings 
            - Add new session-query mappings
        */
            
        -- Update session properties
        UPDATE session
        SET DatabaseID = DB_ID(sessionObject.DatabaseName),
        Name = sessionObject.Name,
        Description = sessionObject.Description,
        Status = sessionObject.Status,
        CreateDate = sessionObject.CreateDate,
        LastModifyDate = GETUTCDATE(),
        BaselineEndDate = sessionObject.BaselineEndDate,
        UpgradeDate = sessionObject.UpgradeDate,
        TargetCompatLevel = sessionObject.TargetCompatLevel,
        WorkloadDurationDays = sessionObject.WorkloadDurationDays
        FROM msqta.TuningSession session		
        INNER JOIN @sessionObject sessionObject ON sessionObject.TuningSessionID = session.TuningSessionID

        IF (SELECT COUNT(*) FROM @queryObject) > 0
        BEGIN
            -- Update queries with update flag
            exec msqta.spQuerySave @queryObject, @queryOptionGroupObject, @queryExecutionStatObject, 2
        END

        -- Delete all existing session-query mapping
        DELETE session_query
        FROM msqta.TuningSession_TuningQuery session_query
        WHERE session_query.TuningSessionID = @sessionId
        
        -- Add session-query mapping
        INSERT INTO msqta.TuningSession_TuningQuery (TuningSessionID, TuningQueryID)
        SELECT @sessionId, query.TuningQueryID 
        FROM @queryObject queryObject
        INNER JOIN msqta.TuningQuery query ON query.QueryID = queryObject.QueryID AND query.DatabaseID = DB_ID(queryObject.DatabaseName)

    END
    ELSE 
    BEGIN
        /*
        If session doesn't exist, (this is create new session request)
            - Create new session only if we don't have an active session
            - If query already exist with a mapping to an existing session, update the query mappings
            - Persist new query
            - Add new mapping for session and query
        */

        -- Validate we don't have active session
        IF (SELECT COUNT(*) FROM msqta.TuningSession WHERE DatabaseID = @databaseId AND Status = 0) > 1
        BEGIN
            THROW 51000, 'Database already have an active session.', 1
        END

        -- Create a new session
        INSERT INTO msqta.TuningSession (DatabaseID, Name, Description, Status, CreateDate, LastModifyDate, BaselineEndDate, UpgradeDate, TargetCompatLevel, WorkloadDurationDays)
        SELECT DB_ID(DatabaseName), Name, Description, Status, CreateDate, GETUTCDATE(), BaselineEndDate, UpgradeDate, TargetCompatLevel, WorkloadDurationDays FROM @sessionObject
            
        -- asign new session id
        SET @sessionId = SCOPE_IDENTITY()

        IF (SELECT COUNT(*) FROM @queryObject) > 0
        BEGIN
            -- Update Queries
            exec msqta.spQuerySave @queryObject, @queryOptionGroupObject, @queryExecutionStatObject, 2

            -- Add session-query mappings
            INSERT INTO msqta.TuningSession_TuningQuery (TuningSessionID, TuningQueryID)
            SELECT @sessionId, query.TuningQueryID 
            FROM @queryObject queryObject
            INNER JOIN msqta.TuningQuery query ON query.QueryID = queryObject.QueryID AND query.DatabaseID = DB_ID(queryObject.DatabaseName)
        END
    END

    EXEC msqta.spSessionById @sessionId

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION; 
    
    THROW 

END CATCH

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION;