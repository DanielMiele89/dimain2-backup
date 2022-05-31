/*************************************************************************
Author: Suraj Chahal
Date: 10-03-2014

Description: This stored procedure is used to populate the report R_0001.
*************************************************************************/
CREATE PROCEDURE Reporting.[SSRS_nFI_R0001_ETL_Load]
			(
			@Date DATE
			)
WITH EXECUTE AS OWNER
AS

BEGIN

SELECT	a.StartDate,
	a.EndDate,
	CAST(DATEDIFF(MINUTE,a.StartDate,a.EndDate) AS VARCHAR) + ' Minutes'  as TimeTakentoRun,
	MAX(CASE WHEN jl.EndDate IS NULL THEN 'Yes' ELSE 'No' END) as DidAnySPsFail
FROM	(
	SELECT	MAX(CASE WHEN StoredProcedureName = 'ETL_Build_Start' THEN StartDate ELSE NULL END) as StartDate,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_Start' THEN JobLogID ELSE NULL END) as SD_JobID,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_End' THEN EndDate ELSE NULL END) as EndDate,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_End' THEN JobLogID ELSE NULL END) as ED_JobID
	FROM nFI.staging.joblog
	WHERE CAST(StartDate AS DATE) = @Date
	)a
INNER JOIN nFI.staging.joblog jl
	ON a.SD_JobID < JobLogID
	AND a.ED_JobID > JobLogID
GROUP BY a.StartDate,a.EndDate

END