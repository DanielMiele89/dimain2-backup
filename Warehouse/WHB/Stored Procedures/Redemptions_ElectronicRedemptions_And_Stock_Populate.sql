-- =============================================
-- Author:		Jason Shipp
-- Create date: 25/05/2017
-- Description:	Populate MI.ElectronicRedemptions_And_Stock table for eVoucher Usage Report

-- Alteration history:

-- Jason Shipp 07/06/2018
	-- Added override to item description for Pizza Express so gift code / eGift card results are merged in the report

-- Jason Shipp 04/10/2018
	-- Added logic to handle change of PartnerID for Currys in RedemptionItem_TradeUpValue table from 04/10/2018
-- =============================================

CREATE PROCEDURE [WHB].[Redemptions_ElectronicRedemptions_And_Stock_Populate]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

		INSERT INTO staging.JobLog_Temp
		SELECT StoredProcedureName = OBJECT_NAME(@@PROCID)
			 , TableSchemaName = 'MI'
			 , TableName = 'ElectronicRedemptions_And_Stock'
			 , StartDate = GETDATE()
			 , EndDate = NULL
			 , TableRowCount  = NULL
			 , AppendReload = 'A'

	-------------------------------------------------------------------------------------------------------------------


	SET DATEFIRST 1; -- Set Monday as the first day of the week

	/**************************************************************************
	Declare variables
	***************************************************************************/
	DECLARE
	@WholeWeeksToDisplay INT = 12
	, @Today DATE = CAST(GETDATE() AS DATE)
	, @WeekEnd DATE
	, @RecentSunday DATE;

	SET @WeekEnd = DATEADD(day, -(DATEPART(dw, DATEADD(day, -1, @Today))), DATEADD(day, -1, @Today)); -- Most recent Sunday before previous week (which may be incomplete)
	SET @RecentSunday =  DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)) -- Most recent Sunday

	/**************************************************************************
	Set up temp table containing sequence of 1000 dates
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Digits') IS NOT NULL DROP TABLE #Digits;

	CREATE TABLE #Digits 
		(Digit INT NOT NULL PRIMARY KEY);

	INSERT INTO #Digits(Digit)
	VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

	IF OBJECT_ID('tempdb..#Numbers') IS NOT NULL DROP TABLE #Numbers;

	SELECT 
	(D3.Digit*100) + (D2.Digit*10) + (D1.Digit) + 1 AS n
	INTO #Numbers
	FROM #Digits D1
	CROSS JOIN #Digits D2 
	CROSS JOIN #Digits D3
	ORDER BY n;

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;

	SELECT 
	CAST(DATEADD(day, -num.n, @Today) AS date) AS CalendarDate
	INTO #Dates
	FROM #Numbers num;

	/**************************************************************************
	Set up week dates #Calendar table
	***************************************************************************/

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
		FROM #Dates
		UNION ALL
		SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(dd, -(DATEPART(dw, CalendarDate)-1), CalendarDate) AS WeekStart -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, CalendarDate)-1)+6, CalendarDate)AS WeekEnd -- For each calendar date in #Dates, minus days since the most recent Sunday
		FROM #Dates
		WHERE CalendarDate BETWEEN DATEADD(week, -@WholeWeeksToDisplay, @WeekEnd) AND @WeekEnd
		) calbase;

	/**************************************************************************
	Set up month dates in #CalendarMonth table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#CalendarMonth') IS NOT NULL DROP TABLE #CalendarMonth;

	CREATE TABLE #CalendarMonth 
		(ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL
		, ReportDate DATE NOT NULL
		, MonthStart DATE NOT NULL
		, MonthEnd DATE NULL
		);
 
	INSERT INTO #CalendarMonth
		SELECT DISTINCT
		@Today AS ReportDate
		, DATEADD(day, -(DATEPART(day, CalendarDate))+1, CalendarDate) AS MonthStart -- For each calendar date in #Dates, minus days since the start of the month  
		, DATEADD(day, -1, DATEADD(month, 1, DATEADD(day, 1 - day(CalendarDate), CalendarDate))) AS MonthEnd -- For each calendar date in #Dates, add days to the end of the month
	FROM #Dates
	WHERE 
		CalendarDate BETWEEN DATEADD(day, -(DATEPART(day, (DATEADD(MONTH, -3, @Today))))+1, (DATEADD(MONTH, -3, @Today))) AND DATEADD(day, -(DATEPART(day, @Today)), @Today);
	
	/**************************************************************************
	Create temp table of E-voucher campaigns 
	***************************************************************************/

	IF OBJECT_ID('tempdb..#RedeemItems') IS NOT NULL DROP TABLE #RedeemItems;

	SELECT DISTINCT
	r.ID AS ItemID 
	, CASE 
		WHEN t.PartnerID = 1000003 AND r.Description LIKE '%15%Pizza%Express%10%' 
		THEN '£15 PizzaExpress gift code/ eGift card for £10 Rewards'
		ELSE r.Description 
	END AS [Description]
	, CASE WHEN t.PartnerID = 4532 THEN 4001 ELSE t.PartnerID END AS PartnerID -- Logic to handle change of PartnerID for Currys in RedemptionItem_TradeUpValue table from 04/10/2018
	, r.ValidityDays
	INTO #RedeemItems
	FROM SLC_Report.dbo.Redeem r -- Holds the description of the redeem items
	LEFT JOIN Staging.R_0155_ERedemptions_RedeemIDExclusions a -- Holds a list of old & test items that should be removed from the report
		ON r.id = a.redeemid
	INNER JOIN Relational.RedemptionItem_TradeUpValue t -- This table holds the link to the partner information
		ON r.ID = t.RedeemID
	WHERE r.IsElectronic = 1
		AND a.RedeemID IS NULL;

	CREATE CLUSTERED INDEX cix_RedeemItems_RedeemID ON #RedeemItems (ItemID);

	/**************************************************************************
	Create temp table of E-voucher redemptions per voucher description and week  
	***************************************************************************/

	IF OBJECT_ID('tempdb..#eRedems') IS NOT NULL DROP TABLE #eRedems;

	SELECT
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, CASE WHEN r.PartnerID = 4532 THEN 4001 ELSE r.PartnerID END AS PartnerID -- Logic to handle change of PartnerID for Currys in Redemptions table from 04/10/2018
		, items.Description
		, items.ItemID
		, COUNT(*) AS eVouchRedemptions
	INTO #eRedems
	FROM #Calendar cal
	INNER JOIN Relational.Redemptions r WITH(NOLOCK)
		ON CAST(r.RedeemDate AS date) BETWEEN cal.WeekStart AND cal.WeekEnd
	INNER JOIN SLC_Report.dbo.Trans t
		ON r.TranID = t.ID
	INNER JOIN #RedeemItems items
		ON t.ItemID = items.ItemID
	WHERE r.RedeemType = 'Trade Up'
		GROUP BY 
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, CASE WHEN r.PartnerID = 4532 THEN 4001 ELSE r.PartnerID END
		, items.Description
		, items.ItemID
	ORDER BY
		cal.WeekEnd;
	
	/**************************************************************************
	Create temp table of current stock levels  
	***************************************************************************/

	IF OBJECT_ID ('tempdb..#StockLevels') IS NOT NULL DROP TABLE #StockLevels;
	 
	SELECT 
		r.ItemID
		, r.Description
		, r.PartnerID
		, r.ValidityDays
		, COUNT(DISTINCT ec.ID) AS eCodes_InStock
	INTO #StockLevels
	FROM #RedeemItems r
	LEFT JOIN SLC_Report.Redemption.ECodeBatch b -- Links the RedeemID to the btach of codes loaded
		ON r.ItemID = b.RedeemID
	LEFT JOIN SLC_Report.Redemption.ECode ec -- Holds the references to the codes (not the actual codes)
		ON b.ID = ec.BatchID
	WHERE 
		ec.Status = 0 -- Means codes uploaded
	GROUP BY
		r.ItemID
		, r.Description
		, r.PartnerID
		, r.ValidityDays
	HAVING 
		(COUNT(DISTINCT ec.ID) > 0 OR SUM(ValidityDays) > 0); -- This helps to remove odd items from being displayed in error
	
	/**************************************************************************
	Create table of average monthly E-voucher redemptions for the last 3 full calendar months
	***************************************************************************/

	IF OBJECT_ID ('tempdb..#MonthAvgRedem') IS NOT NULL DROP TABLE #MonthAvgRedem;

	SELECT
		monthly.Description
		, monthly.ItemID
		, monthly.PartnerID
		, AVG(monthly.eVouchRedemptions) AS eVouchRedemptionsMonthlyAverage
	INTO #MonthAvgRedem
	FROM
		(SELECT
		cal.ReportDate
		, cal.MonthStart
		, cal.MonthEnd
		, r.PartnerID
		, items.Description
		, items.ItemID
		, COUNT(*) AS eVouchRedemptions
		FROM #CalendarMonth cal
		INNER JOIN Relational.Redemptions r WITH(NOLOCK)
			ON CAST(r.RedeemDate AS date) BETWEEN cal.MonthStart AND cal.MonthEnd
		INNER JOIN SLC_Report.dbo.Trans t
			ON r.TranID = t.ID
		INNER JOIN #RedeemItems items
			ON t.ItemID = items.ItemID
		WHERE r.RedeemType = 'Trade Up'
		GROUP BY
		cal.ReportDate
		, cal.MonthStart
		, cal.MonthEnd
		, r.PartnerID
		, items.Description
		, items.ItemID
		) monthly
	GROUP BY
		monthly.Description
		, monthly.ItemID
		, monthly.PartnerID;
	
	/**************************************************************************
	Merge data for report
	***************************************************************************/

	INSERT INTO MI.ElectronicRedemptions_And_Stock
		SELECT
		er.ReportDate
		, er.WeekStart
		, er.WeekEnd
		, er.WeekID
		, er.PartnerID
		, er.Description AS RedemptionDescription
		, er.ItemID
		, er.eVouchRedemptions
		, mar.eVouchRedemptionsMonthlyAverage -- Values are duplicated for the same redemption description and partner
		, sl.eCodes_InStock AS Current_eCodes_InStock -- Values are duplicated for the same redemption description and partner
	FROM #eRedems er 
	LEFT JOIN #StockLevels sl
		ON er.ItemID = sl.ItemID
	LEFT JOIN #MonthAvgRedem mar
		ON er.ItemID = mar.ItemID
	WHERE NOT EXISTS
		(SELECT * FROM MI.ElectronicRedemptions_And_Stock d
		WHERE er.ReportDate = d.ReportDate
			AND er.WeekStart = d.WeekStart 
			AND er.WeekEnd = d.WeekEnd 
			AND er.WeekID = d.WeekID 
			AND er.PartnerID = d.PartnerID
			AND er.Description = d.RedemptionDescription
			AND er.ItemID = d.ItemID
		);

	/**************************************************************************
	-- For investigating missing report items
		
	SELECT *
		FROM Relational.Redemptions r 
	INNER JOIN SLC_Report.dbo.Trans t
		ON r.TranID = t.ID
	INNER JOIN SLC_Report.dbo.Redeem item
		ON item.ID = t.ItemID
	WHERE 
		r.RedeemDate >= '2018-10-01'
		AND item.[Description] like '%Argos%'
	***************************************************************************/

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	--------------------------------------------------------------------------------------------------*/

		UPDATE [Staging].[JobLog_temp]
		SET EndDate = GETDATE()
		  , TableRowCount = @@ROWCOUNT
		WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
		AND EndDate IS NULL

		INSERT INTO [Staging].[JobLog]
		SELECT [StoredProcedureName]
			 , [TableSchemaName]
			 , [TableName]
			 , [StartDate]
			 , [EndDate]
			 , [TableRowCount]
			 , [AppendReload]
		FROM [Staging].[JobLog_temp]
		WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)

		IF NOT EXISTS (SELECT 1 FROM [Staging].[JobLog_temp] WHERE StoredProcedureName != OBJECT_NAME(@@PROCID))
			BEGIN
				TRUNCATE TABLE [Staging].[JobLog_temp]
			END

		DELETE
		FROM [Staging].[JobLog_temp]
		WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)

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