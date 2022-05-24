/******************************************************************************
Author:
Created:
Purpose: 
	- Fetches unaggregated charity redemptions data for the last calendar month 

------------------------------------------------------------------------------
Modification History

Jason Shipp 02/04/2020
	- Parameterised query so results for a specific Item ID can be fetched, or data fetched for the last week instead of month

Jason Shipp 06/04/2020
	- Updated logic to use SLC_REPL tables only, so the results are as up to date as possible (i.e. the results are not dependant on the Warehouse Build)
	- This is slower, but is a report requirement

******************************************************************************/
CREATE PROCEDURE [MI].[RedemptionsCharityMonth_Fetch] (@ItemID int = NULL, @PeriodType varchar(10) = 'Month')
	
AS
BEGIN

	SET NOCOUNT ON;

	-- For testing
	--DECLARE @ItemID int = NULL;
	--DECLARE @PeriodType varchar(10) = 'Month';

	DECLARE @Today date = CAST(GETDATE() AS date);

	--SET @Today = DATEADD(MONTH, -1, @Today)

	DECLARE @StartDate date, @EndDate date;

	IF @PeriodType = 'Month'
	BEGIN
		SET @StartDate = DATEADD(month, -1, DATEADD(day, -((DATEPART(day, @Today))-1), @Today));
		SET @EndDate = EOMONTH(@StartDate);
	END

	IF @PeriodType = 'Week'
	BEGIN
		SET DATEFIRST 1; -- Set Monday as the first day of the week
		SET @EndDate = DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today));
		SET @StartDate = DATEADD(day, -6, @EndDate);
	END

	--SELECT @StartDate, @EndDate, @Today

	--IF @Today = '2021-12-20'
	--	BEGIN
	--		SET @StartDate = '2021-11-18'
	--	END


	IF OBJECT_ID('tempdb..#Redeem') IS NOT NULL DROP TABLE #Redeem
	SELECT	re.ID
		,	MI.GetCharity(re.[Description]) AS CharityDonation
	INTO #Redeem
	FROM [SLC_REPL].[dbo].[Redeem] re
	WHERE re.Privatedescription LIKE '%Donation to%'	-- Charity donations
	OR re.Privatedescription like '%Donate%'			-- Charity donations

	CREATE CLUSTERED INDEX CIX_RedeemID ON #Redeem (ID)

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	tr.[Option]
		,	tr.ClubCash
		,	tr.Date
		,	tr.ID AS TranID
		,	tr.FanID
		,	re.CharityDonation
	INTO #Trans
	FROM [SLC_REPL].[dbo].[Trans] tr
	INNER JOIN #Redeem re
		ON tr.ItemID = re.ID
	WHERE CONVERT(DATE, tr.[Date]) BETWEEN @StartDate AND @EndDate
	AND (tr.ItemID = @ItemID OR @ItemID IS NULL)
	AND tr.TypeID = 3			-- Redemption (non-cancellation)
	AND tr.ID <> 1000704535		-- Exclude test transaction

	CREATE CLUSTERED INDEX CIX_FanID ON #Trans (FanID ,[Option])

	IF OBJECT_ID('tempdb..#Fan') IS NOT NULL DROP TABLE #Fan
	SELECT	fa.ID
		,	fa.FirstName + ' ' + fa.LastName AS CustomerName
		,	fa.Address1 + ' ' + fa.Address2 + ' ' + fa.City + ' ' + fa.County + ' ' + fa.PostCode AS CustomerAddress
	INTO #Fan
	FROM [SLC_REPL].[dbo].[Fan] fa
	WHERE EXISTS (	SELECT 1
					FROM #Trans tr
					WHERE fa.ID = tr.FanID)

	CREATE CLUSTERED INDEX CIX_FanID ON #Fan (ID)

	SELECT	CharityDonation
		,	CONVERT(BIT,	CASE
								WHEN t.[Option] LIKE 'Yes% I%m a %UK tax payer and eligible for gift aid%' THEN 1
								WHEN t.[Option] = 'Yes, I want the NSPCC to treat all gifts of money that I have made in the last four years and all fu' THEN 1
								ELSE 0
							END) AS GiftAid
		,	t.[Option]
		,	f.CustomerName
		,	f.CustomerAddress
		,	t.ClubCash AS Cost
		,	CAST(t.[Date] AS date) AS RedeemDate
		,	t.TranID
	FROM #Trans t
	INNER JOIN #Fan f 
		ON t.FanID = f.ID

END