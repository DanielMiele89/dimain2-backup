
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Fetches weekly total exceptions 
***********************************************************************/
CREATE PROCEDURE [MI].[WeeklyCampaignExceptions_Fetch]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @start int, @sYear int
DECLARE @end int, @eYear int

SELECT @sYear = year(min(inserttime)), @eYear = year(max(inserttime)), @start = datepart(wk, min(inserttime)), @end = datepart(wk, max(inserttime))
FROM mi.CampaignReport_CheckFlags crcf

;WITH CTE
AS
(
    SELECT * FROM
    (
	   VALUES
		  (1, 'Gold', '#B29600'),
		  (2, 'Silver', '#868686'),
		  (3, 'Bronze', '#72461c')
    ) x(TierID, TierDesc, Colour)
    CROSS JOIN InsightArchive.CalendarWeeks cw
    WHERE (datepart(wk, cw.StartDate) >= @start AND year(cw.StartDate) = @sYear)
	   AND (datepart(wk, cw.EndDate) <= @end AND year(cw.EndDate) = @eYear)
)
select TierID
    , TierDesc
    , Colour
    , count(sc.ClientServicesRef) 'TotalCamp'
    , sum(sales + IncSales + AdjFact + Uplift) 'TotalException'
    , c.startDate
    , c.EndDate
    , 'W/C ' + FORMAT(c.StartDate, 'D', 'en-GB' ) 'WeekDesc'
    , SUM(UniqueExceptions) UniqueExceptions
from Relational.Master_Retailer_Table pt
join relational.Partner p on p.PartnerID = pt.PartnerID
JOIN MI.CampaignDetailsWave_PartnerLookup pl ON pl.PartnerID = p.PartnerID
JOIN (
    SELECT * FROM (
	   SELECT distinct l.ClientServicesRef, l.StartDate, CalcDate
		  , CASE WHEN MAX(SalesCheck) <> '-' THEN 1 ELSE 0 END Sales
		  , CASE WHEN MAX(IncrementalSalesCheck) <> '-' THEN 1 ELSE 0 END IncSales
		  , CASE WHEN MAX(AdjFactorCapCheck) <> '-' THEN 1 ELSE 0 END AdjFact
		  , CASE WHEN MAX(UpliftCheck) <> '-' THEN 1 ELSE 0 END  Uplift
		  , CASE WHEN MAX(SalesCheck) <> '-' THEN 1 
			 WHEN MAX(IncrementalSalesCheck) <> '-' THEN 1
			 WHEN MAX(AdjFactorCapCheck) <> '-' THEN 1 
			 WHEN MAX(UpliftCheck) <> '-' THEN 1 ELSE 0 END UniqueExceptions
	   FROM MI.CampaignReport_CheckFlags crcf
	   JOIN MI.CampaignReportLog l on l.ClientServicesRef = crcf.ClientServicesRef and l.StartDate = crcf.StartDate
	   WHERE Archived = 0 and isError = 0 and Status <> 'Calculation Started'
	   GROUP BY l.ClientServicesRef, CalcDate, l.StartDate
	   --ORDER BY CalcDate
    ) x
) sc ON sc.ClientServicesRef = pl.ClientServicesRef AND sc.StartDate = pl.StartDate
RIGHT JOIN CTE c ON c.TierID = pt.Tier AND CalcDate BETWEEN c.StartDate AND c.EndDate
GROUP BY c.StartDate, c.EndDate, TierID, c.TierDesc, Colour


END


