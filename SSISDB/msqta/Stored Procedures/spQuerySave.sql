CREATE PROCEDURE msqta.spQuerySave
@queryObject				msqta.TuningQueryType		READONLY,
@queryOptionGroupObject		msqta.QueryOptionGroupType	READONLY,
@queryExecutionStatObject	msqta.ExecutionStatType		READONLY,
@update						tinyint 
AS

/*
------------------------------------------------------------
Copyright (c) Microsoft Corporation.  All rights reserved.
Licensed under the Source EULA. See License.txt in the project root for license information.
------------------------------------------------------------

Persist queries into database. 
@queryObject				- UDT for TuningQuery
@queryOptionGroupObject		- UDT from QueryOptionObject
@queryExecutionStatObject	- UDT for ExecutionStat
@update						- Valid values are 
                                1 - Force update existing record and insert new records
                                2 - update existing record only if it's query_status is behind the incoming record and insert new records
                                x - insert new records

*/

BEGIN TRANSACTION

BEGIN TRY
    
     -- Verify Database name is valid for query records
    IF (SELECT COUNT(*) FROM @queryObject WHERE DB_ID(DatabaseName) IS NULL) > 0
    BEGIN
        THROW 51000, 'Cannot find database against which query is saved.', 1
    END
        
    IF @update = 1
    BEGIN
        
        /*
        If query already exists, we will overwrite existing record with the incoming record (DELETE + ADD)
        */

        DELETE query
        FROM msqta.TuningQuery query
        INNER JOIN @queryObject queryObject on queryObject.QueryID = query.QueryID AND DB_ID(queryObject.DatabaseName) = query.DatabaseID
        
    END

    IF @update = 2
    BEGIN
        
        /*
        If query already exists, we will update record only if saved query's query_status is behind the incoming record
        */

        DELETE query
        FROM msqta.TuningQuery query
        INNER JOIN @queryObject queryObject on queryObject.QueryID = query.QueryID AND DB_ID(queryObject.DatabaseName) = query.DatabaseID
        WHERE query.Status <= queryObject.Status

    END

    /*
    Add new records
    */

    -- Create temporary list of QueryIDs to which we have to insert. 
    DECLARE @msqta_TempQueryToInsert table(
    QueryID bigint,
    DatabaseID int)

    INSERT INTO @msqta_TempQueryToInsert (QueryID, DatabaseID)
    SELECT queryObject.QueryID, DB_ID(queryObject.DatabaseName)
    FROM @queryObject queryObject
    LEFT JOIN msqta.TuningQuery query on query.QueryID = queryObject.QueryID AND query.DatabaseID = DB_ID(queryObject.DatabaseName)
    WHERE query.QueryID IS NULL AND query.DatabaseID IS NULL

    -- Adding Query Record
    INSERT INTO msqta.TuningQuery(
    QueryID,
    DatabaseID,
    ParentObjectId,
    QueryHash,
    QueryText,
    QueryType,
    IsParametrized,
    PlanGuide,
    Status,
    CreateDate,
    LastModifyDate,
    ProfileCompleteDate,
    AnalysisCompleteDate,
    ExperimentPendingDate,
    ExperimentCompleteDate,
    DeployedDate,
    AbandonedDate,
    Parameters)

    SELECT 
    queryObject.QueryID, 
    DB_ID(queryObject.DatabaseName), 
    queryObject.ParentObjectId, 
    queryObject.QueryHash, 
    queryObject.QueryText, 
    queryObject.QueryType, 
    queryObject.IsParametrized, 
    queryObject.PlanGuide, 
    queryObject.Status,
    queryObject.CreateDate, 
    GETUTCDATE(), 
    queryObject.ProfileCompleteDate, 
    queryObject.AnalysisCompleteDate, 
    queryObject.ExperimentPendingDate, 
    queryObject.ExperimentCompleteDate, 
    queryObject.DeployedDate, 
    queryObject.AbandonedDate, 
    queryObject.Parameters 
    FROM @queryObject queryObject
    INNER JOIN @msqta_TempQueryToInsert queryToInsert ON queryToInsert.QueryID = queryObject.QueryID AND queryToInsert.DatabaseID = DB_ID(queryObject.DatabaseName)

    -- Create a temporary mapping of QueryOptionGroup(GroupID) from the client to actual GroupID generated from above statement.
    -- We will need this mapping to link ExecutionStats back to GroupID
    DECLARE @msqta_TempGroupIdMapping table(
    TuningQueryID bigint,
    TempGroupID bigint,
    NewGroupID bigint)

    /*
    Adding QueryOptionGroup Records with always insert merge condition.
    We have to use merge condition in this case because we have to use output clause to get back the identity column value for GroupID.
    Output clause will generate the temporary mapping of GroupID from client to actual GroupID.
    */
    MERGE INTO msqta.QueryOptionGroup
    USING @queryOptionGroupObject qogObject
    INNER JOIN @msqta_TempQueryToInsert queryToInsert ON queryToInsert.QueryID = qogObject.QueryID AND queryToInsert.DatabaseID = DB_ID(qogObject.DatabaseName)
    INNER JOIN msqta.TuningQuery query ON query.QueryID = qogObject.QueryID AND query.DatabaseID = DB_ID(qogObject.DatabaseName)
    ON 1=0
    WHEN NOT MATCHED THEN
        INSERT(
        TuningQueryID,
        QueryOptions,
        IsVerified,
        IsDeployed,
        ValidationCompleteDate)

        VALUES(
        query.TuningQueryID,
        qogObject.QueryOptions,
        qogObject.IsVerified,
        qogObject.IsDeployed,
        qogObject.ValidationCompleteDate)

        OUTPUT INSERTED.TuningQueryID, qogObject.GroupID, INSERTED.GroupID INTO @msqta_TempGroupIdMapping;

    -- Adding ExecutionStat Records
    INSERT INTO msqta.ExecutionStat(
    GroupID,
    StatType,
    IsProfiled,
    ExecutionCount,
    Showplan,
    Stats)

    SELECT
    tempGroupIdMapping.NewGroupID,
    statsObject.StatType,
    statsObject.IsProfiled,
    statsObject.ExecutionCount,
    statsObject.Showplan,
    statsObject.Stats
    FROM @queryExecutionStatObject statsObject
    INNER JOIN @msqta_TempQueryToInsert queryToInsert ON queryToInsert.QueryID = statsObject.QueryID AND queryToInsert.DatabaseID = DB_ID(statsObject.DatabaseName)
    INNER JOIN msqta.TuningQuery query ON query.QueryID = statsObject.QueryID AND query.DatabaseID = DB_ID(statsObject.DatabaseName)
    INNER JOIN @msqta_TempGroupIdMapping tempGroupIdMapping ON tempGroupIdMapping.TuningQueryID = query.TuningQueryID AND tempGroupIdMapping.TempGroupID = statsObject.GroupID

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION; 
    THROW

END CATCH

IF @@TRANCOUNT > 0  
    COMMIT TRANSACTION;