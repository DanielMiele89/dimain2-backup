
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 18/08/2016
	Description: 
	 

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Insert_LiveCampaigns]
AS
BEGIN


-- Pull Live campaigns for current month
DECLARE @StartDate date = DATEADD(m, DATEDIFF(m, 0, GETDATE())-1, 0)
DECLARE @EndDate date = EOMONTH(@StartDate)

TRUNCATE TABLE MI.CampaignReport_Staging_AllCampaigns

INSERT INTO MI.CampaignReport_Staging_AllCampaigns (ClientServicesRef, StartDate, EndDate, isCalculated, isIncomplete)
select distinct 
    ih.ClientServicesRef
    , io.StartDate
    , EndDate
    , CASE WHEN w.ClientServicesRef IS NULL THEN 0 ELSE 1 END as isCalculated 
    , CASE 
	   WHEN ISNULL(EndDate, DATEADD(DAY, 1, @EndDate)) > @EndDate THEN 1 
	   WHEN io.StartDate < @StartDate THEN 1
	   ELSE 0 
	 END as isIncomplete
from relational.ironoffer io
join relational.IronOffer_Campaign_HTM ih on ih.IronOfferID = io.IronOfferID
LEFT JOIN MI.CampaignInternalResults_Workings w on w.ClientServicesRef = ih.ClientServicesRef
where (io.StartDate <= @EndDate and (CASE WHEN ISNULL(EndDate, @EndDate) >= @EndDate THEN @EndDate ELSE EndDate END >= @StartDate ))
    and ih.ClientServicesRef not in ('XX-3963-2012-4', 'XX-3962-2012-4')

-- Reset any calculations that have not been calculated to be picked up in normal calculation
DECLARE @CalcCheck nvarchar(max) = 
    (
	   SELECT 'EXEC MI.CampaignReport_Reset_Calc ''' + a.ClientServicesRef + ''',''' + CAST(a.StartDate as nvarchar) + ''', 0 '
	   FROM #AllCampaigns a
	   JOIN MI.CampaignReportLog l on l.ClientServicesRef = a.ClientServicesRef and l.StartDate = a.StartDate and ExtendedPeriod = 0
	   WHERE isIncomplete = 0 and isCalculated = 0
	   FOR XML PATH('')
    )

EXEC (@CalcCheck)

-- Create any campaigns that need to be calculated but have not yet been inserted into log table
SET @CalcCheck = 
    (
	   SELECT 'EXEC MI.CampaignReport_Create_Params ''' + ClientServicesRef + ''',''' + CAST(StartDate as nvarchar) + ''', 0 '
	   FROM #AllCampaigns a
	   WHERE NOT EXISTS (
		  SELECT 1 FROM MI.CampaignReportLog r
		  WHERE r.ClientServicesRef = a.ClientServicesRef and r.StartDate = a.StartDate and ExtendedPeriod = 0
	   )
		  AND isIncomplete = 0 and isCalculated = 0
	   FOR XML PATH('')
    )

EXEC (@CalcCheck)

-- Insert Incomplete campaigns to be calculated

INSERT INTO MI.CampaignReportLog_Incomplete (ClientServicesRef, StartDate, CalcStartDate, CalcEndDate)
SELECT a.ClientServicesRef, a.StartDate,
    CASE WHEN a.StartDate < @StartDate THEN @StartDate ELSE a.StartDate END as CalcStartDate,
    CASE WHEN a.EndDate > @EndDate THEN @EndDate ELSE a.EndDate END as CalcEndDate 
FROM MI.CampaignReport_Staging_AllCampaigns a
--JOIN MI.CampaignreportLog l on l.ClientServicesRef = a.ClientServicesRef and l.StartDate = a.StartDate
WHERE (isIncomplete = 1)

END

