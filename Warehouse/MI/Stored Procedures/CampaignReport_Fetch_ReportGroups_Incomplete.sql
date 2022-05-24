
/***********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Get the list of reports to generate

	Fetch reports that have not been created, have not errored and is for the ExtendedPeriod defined

	======================= Change Log =======================

	- 14/08/2015 Added check for final table to ensure that reports that have been removed from the 
	final table are not generated

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Fetch_ReportGroups_Incomplete]
AS
BEGIN
	SET NOCOUNT ON;

	-- Get Params from Log Table
	SELECT
		w.ClientServicesRef,
		m.StartDate,
		m.CalcStartDate,
		m.CalcEndDate
	FROM MI.CampaignReportLog_Incomplete m
	JOIN MI.CampaignInternalResultsFinalWave_Incomplete w on w.ClientServicesRef = m.ClientServicesRef and w.StartDate = m.CalcStartDate
	WHERE IsError = 0
	   AND Status = 'Calculation Completed'
	   and m.ClientServicesRef like 'AB%'
	   --AND m.ClientServicesRef like 'QP%'
	   --AND cast(calcdate as date) = '2015-12-10'
	   --AND substring(m.ClientServicesRef, 0, ISNULL(NULLIF(charindex('bespoke', m.clientservicesref, 0), 0), 99)) in ('WA061')
END