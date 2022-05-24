

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 14/09/2015
-- Description: Next Jump Daily Report (Code written by Lloyd Green)
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0101_OverallPublisherDailyReport_V2Dev]
									
AS
BEGIN
	SET NOCOUNT ON;


----Cumulative by day----
IF OBJECT_ID('tempdb..#cumulativedayreport') IS NOT NULL DROP TABLE #cumulativedayreport
CREATE TABLE #CumulativeDayReport(ClubID int, ActivationDate DATE, NoCards INT, NoCardholders INT)

IF OBJECT_ID('tempdb..#CumulativeDayReportMembers') IS NOT NULL DROP TABLE #CumulativeDayReportMembers
CREATE TABLE #cumulativedayreportmembers(ClubID INT, ActivationDate DATE, NoMembers INT)

DECLARE @startdate DATE, 
		@ClubID int,
		@RunID int,
		@MaxID INT,
		@time DATETIME,
		@msg VARCHAR(2048)


/******************************************************************		
		Set parameters for loop 
******************************************************************/

Set @RunID = 1
Set @MaxID = (Select Max(ID) from Staging.SSRS_R0101_OverallPublisherDailyReportClubs)

SELECT @msg = 'Parameters set'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT


/******************************************************************		
		Begin loop 
******************************************************************/

While @RunID <= @MaxID
Begin
		
		Set @ClubID = (Select ClubID from Staging.SSRS_R0101_OverallPublisherDailyReportClubs where @RunID = ID)
		SET @StartDate = (Select StartDate from Staging.SSRS_R0101_OverallPublisherDailyReportClubs where @RunID = ID)

		/******************************************************************		
				For each day since the start of the programme, get the
				cummalative counts for each metric
		******************************************************************/
		
				WHILE	@startdate <= (SELECT DATEADD(DD,-1, CAST(GETDATE() AS DATE)))
				BEGIN

					INSERT INTO #CumulativeDayReport(ClubID, ActivationDate, NoCards, NoCardholders)
					SELECT	ClubID, 
						@StartDate,
						COUNT(DISTINCT PaymentCardID) as Cards,
						COUNT(DISTINCT UserID) as Cardholders 
					FROM SLC_Report.dbo.Pan AS P
					INNER JOIN SLC_Report.dbo.Fan as f 
						ON f.CompositeID = p.CompositeID
					where	(p.removaldate is null or p.RemovalDate > @StartDate)
						and f.clubID = @ClubID -- Virgin
						and p.AdditionDate <= @StartDate 
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
						Group by f.ClubID
				
				SET @StartDate = DATEADD(DAY, 1, @StartDate)	
				
				END	


		SET @StartDate = (Select StartDate from Staging.SSRS_R0101_OverallPublisherDailyReportClubs where @RunID = ID)

			DECLARE @StartDate2 DATE
			SET @StartDate2 = @StartDate

				WHILE @StartDate2 <= (SELECT DATEADD(DD,-1, CAST(GETDATE() AS DATE)))
				BEGIN

					INSERT INTO #CumulativeDayReportMembers(ClubID, ActivationDate, NoMembers)
					SELECT	@ClubID, 
							@StartDate2,
						COUNT(DISTINCT id) as NoMembers
					FROM SLC_Report.dbo.Fan 
					WHERE	ClubID = @ClubID ---- (12 - Quidco, 143 - Easyfundraising, 144 - Karrot, 145 - NextJump, 147 - Virgin)
						AND RegistrationDate < DATEADD(dd, 1, @startdate2)
					Group by ClubID 		
			
					SET @StartDate2 = DATEADD(DAY, 1, @startdate2)			
				END	

			Set @RunID = @RunID + 1

			SELECT @msg = cast(@CLubID as varchar) + ' completed'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

End

/******************************************************************		
		Get all data for all clubs in to one table 
******************************************************************/


IF OBJECT_ID('tempdb..#summary1') IS NOT NULL DROP TABLE #summary1
SELECT	a.clubid, 
	a.ActivationDate as ToDate,
	b.NoMembers as Cumulative_Members_Registered,
	a.NoCardholders as Cumulative_Unique_Cardholders,
	a.NoCards as Cumulative_Cards_Registered
INTO #summary1
FROM #cumulativedayreport a
INNER JOIN #cumulativedayreportmembers b 
	on a.ActivationDate = b.ActivationDate
	and a.ClubID = b.ClubID


/******************************************************************		
		Calculate difference betweeen  each day for each metric to
		get daily metrics
******************************************************************/

SELECT	a.*,
	ISNULL((a.Cumulative_Members_Registered - b.Cumulative_Members_Registered),0) as Members_Added,
	ISNULL((a.Cumulative_Unique_Cardholders - b.Cumulative_Unique_Cardholders),0) as Cardholders_Added,
	ISNULL((a.Cumulative_Cards_Registered - b.Cumulative_Cards_Registered),0) as Cards_Added
Into #FinalData
FROM #Summary1 a
LEFT JOIN #Summary1 b 
	ON a.ToDate = DATEADD(dd, 1, b.ToDate) 
	and a.ClubID = b.CLubID



Select *
From #FinalData

END



