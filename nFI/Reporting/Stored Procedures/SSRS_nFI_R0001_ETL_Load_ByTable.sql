/*************************************************************************
Author: Suraj Chahal
Date: 10-03-2014

Description: This stored procedure is used to populate the report R_0001.
	This stores the line by line data for the ETL load
*************************************************************************/
CREATE PROCEDURE REPORTING.[SSRS_nFI_R0001_ETL_Load_ByTable]
			(
			@Date date
			)
WITH EXECUTE AS OWNER
AS

BEGIN

SELECT	jl.*,
	CAST(DATEDIFF(MINUTE,jl.StartDate,jl.EndDate) AS VARCHAR) + ' Minutes'  as TimeTakentoRun,
	CASE
		WHEN jl.EndDate IS NULL THEN 'Yes'
		ELSE 'No'
	END as DidAnySPsFail
FROM	(
	SELECT	MAX(CASE WHEN StoredProcedureName = 'ETL_Build_Start' THEN StartDate ELSE NULL END) as StartDate,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_Start' THEN JobLogID ELSE NULL END)  as SD_JobID,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_End' THEN EndDate ELSE NULL END) as EndDate,
		MAX(CASE WHEN StoredProcedureName = 'ETL_Build_End' THEN JobLogID ELSE NULL END)  as ED_JobID
	FROM nFI.staging.joblog
	WHERE Cast(StartDate as date) = @Date
	) as a
INNER JOIN nFI.staging.joblog jl
	ON a.SD_JobID < jl.JobLogID
	AND a.ED_JobID > jl.JobLogID
ORDER BY JobLogID

END