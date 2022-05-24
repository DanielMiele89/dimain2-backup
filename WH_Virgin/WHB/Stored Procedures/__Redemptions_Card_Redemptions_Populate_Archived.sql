-- =============================================
-- Author:		Jason Shipp
-- Create date: 08/02/2018
-- Description:	Populate MI.Weekly_Card_Redemptions table for eVoucher Usage Report
-- Alteration history:
-- =============================================

create PROCEDURE [WHB].[__Redemptions_Card_Redemptions_Populate_Archived]
	
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
	DECLARE
	@WholeWeeksToDisplay INT = 22
	, @Today DATE = CAST(GETDATE() AS DATE)
	, @WeekEnd DATE
	, @RecentSunday DATE;

	SET @WeekEnd = DATEADD(day, -(DATEPART(dw, DATEADD(day, -1, @Today))), DATEADD(day, -1, @Today)); -- Most recent Sunday before previous week (which may be incomplete)
	SET @RecentSunday =  DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)) -- Most recent Sunday

	/**************************************************************************
	Set up temp table containing sequence of 1000 dates
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Digits') IS NOT NULL 
	DROP TABLE #Digits;

	CREATE TABLE #Digits 
		(Digit INT NOT NULL PRIMARY KEY);

	INSERT INTO #Digits(#Digits.[Digit])
	 VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

	IF OBJECT_ID('tempdb..#Numbers') IS NOT NULL 
	DROP TABLE #Numbers;

	SELECT 
	(D3.Digit*100) + (D2.Digit*10) + (D1.Digit) + 1 AS n
	INTO #Numbers
	FROM #Digits D1
	CROSS JOIN #Digits D2 
	CROSS JOIN #Digits D3
	ORDER BY n;

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL 
	DROP TABLE #Dates;

	SELECT 
	CAST(DATEADD(day, -num.n, @Today) AS date) AS CalendarDate
	INTO #Dates
	FROM #Numbers num;

	/**************************************************************************
	Set up week dates #Calendar table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL 
	DROP TABLE #Calendar;

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
		FROM #Dates
		UNION ALL
		SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1), #Dates.[CalendarDate]) AS WeekStart -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1)+6, #Dates.[CalendarDate])AS WeekEnd -- For each calendar date in #Dates, minus days since the most recent Sunday
		FROM #Dates
		WHERE #Dates.[CalendarDate] BETWEEN DATEADD(week, -@WholeWeeksToDisplay, @WeekEnd) AND @WeekEnd
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
	INNER JOIN Derived.RedemptionItem_TradeUpValue t -- This table holds the link to the partner information
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
	INNER JOIN Derived.Redemptions r WITH(NOLOCK)
		ON CAST(#Calendar.[r].RedeemDate AS DATE) BETWEEN cal.WeekStart AND cal.WeekEnd
	INNER JOIN SLC_Report.dbo.trans t
		ON #Calendar.[r].TranID = #Calendar.[t].ID
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
	INSERT INTO Report.Weekly_Card_Redemptions
		([Report].[Weekly_Card_Redemptions].[ReportDate]
		, [Report].[Weekly_Card_Redemptions].[WeekStart]
		, [Report].[Weekly_Card_Redemptions].[WeekEnd]
		, [Report].[Weekly_Card_Redemptions].[WeekID]
		, [Report].[Weekly_Card_Redemptions].[PartnerID]
		, [Report].[Weekly_Card_Redemptions].[RedemptionDescription]
		, [Report].[Weekly_Card_Redemptions].[Redemptions]
		, [Report].[Weekly_Card_Redemptions].[CurrentStockLevel]
		)
	SELECT
		r.ReportDate
		, r.WeekStart
		, r.WeekEnd
		, r.WeekID
		, r.PartnerID
		, r.[Description] AS RedemptionDescription
		, r.Redemptions
		, #Redems.[s].CurrentStockLevel
	FROM #Redems r
	LEFT JOIN OfferStock s
		ON r.PartnerID = s.PartnerID
		AND r.[Description] = s.[Description]
	WHERE NOT EXISTS
		(SELECT * FROM Report.Weekly_Card_Redemptions d
		WHERE r.ReportDate = #Redems.[d].ReportDate
			AND r.WeekStart = #Redems.[d].WeekStart 
			AND r.WeekEnd = #Redems.[d].WeekEnd 
			AND r.WeekID = #Redems.[d].WeekID 
			AND r.PartnerID = #Redems.[d].PartnerID
			AND r.[Description] = #Redems.[d].RedemptionDescription
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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END