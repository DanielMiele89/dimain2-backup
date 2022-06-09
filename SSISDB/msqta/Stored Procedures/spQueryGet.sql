CREATE PROCEDURE msqta.spQueryGet
@databaseName	varchar(256)
AS

/*
------------------------------------------------------------
Copyright (c) Microsoft Corporation.  All rights reserved.
Licensed under the Source EULA. See License.txt in the project root for license information.
------------------------------------------------------------

Returns list of TuningQuery for the given database
@databaseName			- Name of the database for which TuningQuery is returned for

*/

SELECT 
query.TuningQueryID,
query.QueryID,
DB_NAME(query.DatabaseID) AS DatabaseName,
query.ParentObjectId,
query.QueryHash,
query.QueryText,
query.QueryType,
query.IsParametrized,
query.PlanGuide,
query.Status,
query.CreateDate,
query.LastModifyDate,
query.ProfileCompleteDate,
query.AnalysisCompleteDate,
query.ExperimentPendingDate,
query.ExperimentCompleteDate,
query.DeployedDate,
query.AbandonedDate,
query.Parameters 
FROM msqta.TuningQuery query
WHERE query.DatabaseID = DB_ID(@databaseName)

SELECT 
queryOptionGroup.GroupID,
queryOptionGroup.TuningQueryID,
query.QueryID,
DB_NAME(query.DatabaseID) AS DatabaseName,
queryOptionGroup.QueryOptions,
queryOptionGroup.IsVerified,
queryOptionGroup.IsDeployed,
queryOptionGroup.ValidationCompleteDate
FROM msqta.QueryOptionGroup queryOptionGroup
INNER JOIN msqta.TuningQuery query ON query.TuningQueryID = queryOptionGroup.TuningQueryID
WHERE query.DatabaseID = DB_ID(@databaseName)

SELECT
stat.StatID,
stat.GroupID,
query.QueryID,
DB_NAME(query.DatabaseID) AS DatabaseName,
stat.StatType,
stat.IsProfiled,
stat.ExecutionCount,
stat.Showplan,
stat.Stats
FROM msqta.ExecutionStat stat
INNER JOIN msqta.QueryOptionGroup queryOptionGroup ON queryOptionGroup.GroupID = stat.GroupID
INNER JOIN msqta.TuningQuery query ON query.TuningQueryID = queryOptionGroup.TuningQueryID
WHERE query.DatabaseID = DB_ID(@databaseName)