

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 20/07/2015
-- Description: Karrot Daily Report (Code written by Lloyd Green)
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0090_Karrot_DailyReport]
									
AS
BEGIN
	SET NOCOUNT ON;

----Cumulative by day----
IF OBJECT_ID('tempdb..#cumulativedayreport') IS NOT NULL DROP TABLE #cumulativedayreport
CREATE TABLE #CumulativeDayReport(ActivationDate DATE, NoCards INT, NoCardholders INT)

DECLARE @startdate DATE

SET @StartDate = '2015-07-20'

WHILE	@startdate <= (SELECT DATEADD(DD,-1, CAST(GETDATE() AS DATE)))
BEGIN

	INSERT INTO #CumulativeDayReport(ActivationDate, NoCards, NoCardholders)
	SELECT	@StartDate,
		COUNT(DISTINCT PaymentCardID) as Cards,
		COUNT(DISTINCT UserID) as Cardholders 
	FROM SLC_Report.dbo.Pan AS P
	INNER JOIN SLC_Report.dbo.Fan as f 
		ON f.CompositeID = p.CompositeID
	where	(p.removaldate is null or p.RemovalDate > @StartDate)
		and f.clubID = 144
		--and p.AdditionDate <= @StartDate 
		and (
		(      p.DuplicationDate IS NULL 
			or p.DuplicationDate > @StartDate
		)
		or 
		(
			p.DuplicationDate <= @StartDate 
					 AND  existS (  SELECT 1
							FROM SLC_Report.dbo.Pan ps 
							INNER JOIN SLC_Report.dbo.Fan fs ON ps.CompositeID = fs.CompositeID
							WHERE ps.PaymentCardID = p.PaymentCardID
												AND ps.AdditionDate between p.AdditionDate and @StartDate
												AND fs.ClubID = 141 -- P4L
						      ) 
				   )
			    )
                AND p.AdditionDate < DATEADD(dd, 1, @startdate)


SET @StartDate = DATEADD(DAY, 1, @StartDate)			
END	



IF OBJECT_ID('tempdb..#CumulativeDayReportMembers') IS NOT NULL DROP TABLE #CumulativeDayReportMembers
CREATE TABLE #cumulativedayreportmembers(ActivationDate DATE, NoMembers INT)

DECLARE @StartDate2 DATE
SET @StartDate2 = '2015-07-20'

WHILE @StartDate2 <= (SELECT DATEADD(DD,-1, CAST(GETDATE() AS DATE)))
BEGIN

	INSERT INTO #CumulativeDayReportMembers(ActivationDate, NoMembers)
	SELECT	@StartDate2,
		COUNT(DISTINCT id) as NoMembers
	FROM SLC_Report.dbo.Fan 
	WHERE	ClubID = 144  ---- (12 - Quidco, 143 - Easyfundraising, 144 - Karrot, 145 - NextJump)
		AND RegistrationDate < DATEADD(dd, 1, @startdate2) 		
			
	SET @StartDate2 = DATEADD(DAY, 1, @startdate2)			
END	



IF OBJECT_ID('tempdb..#summary1') IS NOT NULL DROP TABLE #summary1
SELECT	a.ActivationDate as ToDate,
	b.NoMembers as Cumulative_Members_Registered,
	a.NoCardholders as Cumulative_Unique_Cardholders,
	a.NoCards as Cumulative_Cards_Registered
INTO #summary1
FROM #cumulativedayreport a
INNER JOIN #cumulativedayreportmembers b 
	on a.ActivationDate = b.ActivationDate



SELECT	a.*,
	ISNULL((a.Cumulative_Members_Registered - b.Cumulative_Members_Registered),0) as Members_Added,
	ISNULL((a.Cumulative_Unique_Cardholders - b.Cumulative_Unique_Cardholders),0) as Cardholders_Added,
	ISNULL((a.Cumulative_Cards_Registered - b.Cumulative_Cards_Registered),0) as Cards_Added
FROM #Summary1 a
LEFT JOIN #Summary1 b 
	ON a.ToDate = DATEADD(dd, 1, b.ToDate) 


END