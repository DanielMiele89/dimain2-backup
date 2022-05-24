-- =============================================
-- Author:		Jason Shipp
-- Create date: 08/02/2018
-- Description:	Populate MI.Weekly_Card_Redemptions table for eVoucher Usage Report

----------------------------------------------------------------------------------------------
-- Alteration history:

-- Jason Shipp 20/12/2019
	-- Changed calendar logic to use a tally table
-- =============================================

CREATE PROCEDURE WHB.Redemptions_Card_Redemptions_Populate
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	SET DATEFIRST 1; -- Set Monday as the first day of the week

	/**************************************************************************
	Declare variables
	***************************************************************************/
	
	DECLARE @WholeWeeksToDisplay INT = 22;
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @WeekEnd date = DATEADD(day, -(DATEPART(dw, DATEADD(day, -1, @Today))), DATEADD(day, -1, @Today)); -- Most recent Sunday before previous week (which may be incomplete)
	DECLARE @RecentSunday date =  DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)); -- Most recent Sunday
	DECLARE @MinStartDate date = DATEADD(week, -@WholeWeeksToDisplay, @WeekEnd);

	/**************************************************************************
	Set up week dates #Calendar table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#TallyDates') IS NOT NULL DROP TABLE #TallyDates;

	WITH
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
	SELECT n, CalDate = DATEADD(day, n, @MinStartDate) INTO #TallyDates FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= DATEADD(day, -1, @Today); -- Create table of consecutive dates

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	CREATE TABLE #Calendar 
		(ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL
		, ReportDate DATE NOT NULL
		, WeekStart DATE NOT NULL
		, WeekEnd DATE NULL
		, WeekID INT NOT NULL
		);

	INSERT INTO #Calendar
	SELECT 
	calbase.*
	, CASE
		WHEN calbase.WeekEnd = DATEADD(day, -1, @Today) THEN 1
		WHEN calbase.WeekEnd BETWEEN DATEADD(week, -3, @RecentSunday) AND @RecentSunday THEN 2
		ELSE 3
	END AS WeekID
	FROM
		(SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(day, 1, @WeekEnd) AS WeekStart -- Manually set dates for first reporting week, as it may be an incomplete week
			, DATEADD(day, -1, @Today) AS WeekEnd
		FROM #TallyDates
		UNION ALL
		SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) AS WeekStart -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate)AS WeekEnd -- For each calendar date in #Dates, minus days since the most recent Sunday
		FROM #TallyDates
		WHERE CalDate BETWEEN @MinStartDate AND @WeekEnd
		) calbase;

	/**************************************************************************
	Create temp table of card trade-up campaigns 
	***************************************************************************/

	IF OBJECT_ID('tempdb..#RedeemItems') IS NOT NULL 
		DROP TABLE #RedeemItems;

	SELECT DISTINCT
	r.ID AS ItemID 
	, r.Description
	, t.PartnerID
	, r.ValidityDays
	, r.CurrentStockLevel
	INTO #RedeemItems
	FROM SLC_Report.dbo.Redeem r -- Holds the description of the redeem items
	LEFT JOIN Staging.R_0155_ERedemptions_RedeemIDExclusions a -- Holds a list of old & test items that should be removed from the report
		ON r.id = a.redeemid
	INNER JOIN Relational.RedemptionItem_TradeUpValue t -- This table holds the link to the partner information
		ON r.ID = t.RedeemID
	WHERE r.IsElectronic = 0
		AND a.RedeemID IS NULL;

	CREATE CLUSTERED INDEX cix_RedeemItems_RedeemID ON #RedeemItems (ItemID);
	
	/**************************************************************************
	Create temp table of card trade-up redemptions per week  
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Redems') IS NOT NULL 
		DROP TABLE #Redems;

	SELECT
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, r.PartnerID
		, items.[Description]
		, COUNT(*) AS Redemptions
	INTO #Redems
	FROM #Calendar cal
	INNER JOIN Relational.Redemptions r WITH(NOLOCK)
		ON CAST(r.RedeemDate AS DATE) BETWEEN cal.WeekStart AND cal.WeekEnd
	INNER JOIN SLC_Report.dbo.trans t
		ON r.TranID = t.ID
	INNER JOIN #RedeemItems items
		ON t.ItemID = items.ItemID
	WHERE r.RedeemType = 'Trade Up'
	GROUP BY 
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, r.PartnerID
		, items.[Description];

	/**************************************************************************
	Insert new results into MI.Weekly_Card_Redemptions table

	Create results table: 

	CREATE TABLE MI.Weekly_Card_Redemptions
	(ID INT IDENTITY (1,1)
	, ReportDate DATE
	, WeekStart DATE
	, WeekEnd DATE
	, WeekID INT
	, PartnerID INT
	, RedemptionDescription VARCHAR(200)
	, ItemID INT
	, Redemptions INT
	, CurrentStockLevel INT
	, CONSTRAINT PK_Weekly_Card_Redemptions PRIMARY KEY CLUSTERED (ID)  
	)
	***************************************************************************/

	WITH OfferStock AS
		(SELECT
		i.PartnerID
		, i.Description
		, SUM(i.CurrentStockLevel) AS CurrentStockLevel 
		FROM #RedeemItems i
		GROUP BY 
		i.PartnerID
		, i.Description
		)
	INSERT INTO MI.Weekly_Card_Redemptions
		(ReportDate
		, WeekStart
		, WeekEnd
		, WeekID
		, PartnerID
		, RedemptionDescription
		, Redemptions
		, CurrentStockLevel
		)
	SELECT
		r.ReportDate
		, r.WeekStart
		, r.WeekEnd
		, r.WeekID
		, r.PartnerID
		, r.[Description] AS RedemptionDescription
		, r.Redemptions
		, s.CurrentStockLevel
	FROM #Redems r
	LEFT JOIN OfferStock s
		ON r.PartnerID = s.PartnerID
		AND r.[Description] = s.[Description]
	WHERE NOT EXISTS
		(SELECT * FROM MI.Weekly_Card_Redemptions d
		WHERE r.ReportDate = d.ReportDate
			AND r.WeekStart = d.WeekStart 
			AND r.WeekEnd = d.WeekEnd 
			AND r.WeekID = d.WeekID 
			AND r.PartnerID = d.PartnerID
			AND r.[Description] = d.RedemptionDescription
		);

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END