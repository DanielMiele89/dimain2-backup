
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 18/08/2016
	Description: 
	 

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Fetch_LiveCampaigns]
AS
BEGIN

    --DECLARE @StartDate date = DATEADD(m, DATEDIFF(m, 0, GETDATE())-1, 0)
    --DECLARE @EndDate date = EOMONTH(@StartDate)

    SELECT a.ClientServicesRef, a.StartDate, COALESCE(i.CalcStartDate, a.StartDate) CalcStartDate, COALESCE(i.CalcEndDate, a.EndDate) CalcEndDate, isCalculated, isIncomplete
    FROM MI.CampaignReport_Staging_AllCampaigns a
    LEFT JOIN MI.CampaignReportLog_Incomplete i on i.StartDate = a.StartDate and i.ClientServicesRef = a.ClientServicesRef
    LEFT JOIN MI.CampaignReportLog l on l.StartDate = a.StartDate and l.ClientServicesRef = a.ClientServicesRef
    WHERE isIncomplete = 1 or isCalculated = 0


END