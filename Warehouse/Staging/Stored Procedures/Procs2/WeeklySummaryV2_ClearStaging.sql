/******************************************************************************
Author: Jason Shipp
Created: 24/10/2018
Purpose: 
	- Clear staging tables involved in Weekly Summary (V2) ETL
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.WeeklySummaryV2_ClearStaging
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Staging.WeeklySummaryV2_RetailerAnalysisPeriods;
	TRUNCATE TABLE Staging.WeeklySummaryV2_CardholderCounts;

END