CREATE PROCEDURE msqta.spSessionById
@sessionId	bigint
AS

/*
------------------------------------------------------------
Copyright (c) Microsoft Corporation.  All rights reserved.
Licensed under the Source EULA. See License.txt in the project root for license information.
------------------------------------------------------------

Retrieve already saved Tuning Session. 
@sessionId			- sessionId to retrieve

*/

SELECT 
TuningSessionID,
DB_NAME(DatabaseID) AS DatabaseName,
Name,
Description,
Status,
CreateDate,
LastModifyDate,
BaselineEndDate,
UpgradeDate,
TargetCompatLevel,
WorkloadDurationDays
FROM msqta.TuningSession 
WHERE TuningSessionID = @sessionId

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
INNER JOIN msqta.TuningSession_TuningQuery session_query ON session_query.TuningQueryID = query.TuningQueryID
WHERE session_query.TuningSessionID = @sessionId

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
INNER JOIN msqta.TuningSession_TuningQuery session_query ON session_query.TuningQueryID = queryOptionGroup.TuningQueryID
WHERE session_query.TuningSessionID = @sessionId

SELECT
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
INNER JOIN msqta.TuningSession_TuningQuery session_query ON session_query.TuningQueryID = queryOptionGroup.TuningQueryID
WHERE session_query.TuningSessionID = @sessionId