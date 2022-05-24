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
CREATE PROCEDURE [MI].[RedemptionsCharityMonth_Fetch_20210121] (@ItemID int = NULL, @PeriodType varchar(10) = 'Month')
	
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

	--SELECT @StartDate, @EndDate

	SELECT 
		MI.GetCharity(red.[Description]) AS CharityDonation
		, CAST(CASE WHEN t.[Option] = 'Yes I am a UK tax payer and eligible for gift aid' THEN 1 ELSE 0 END AS bit) AS GiftAid
		, f.FirstName + ' ' + f.LastName AS CustomerName
		, f.Address1 + ' ' + f.Address2 + ' ' + f.City + ' ' + f.County + ' ' + f.PostCode AS CustomerAddress
		, t.ClubCash AS Cost
		, CAST(t.[Date] AS date) AS RedeemDate
		, t.ID AS TranID
	FROM SLC_REPL.dbo.[Trans] t
	INNER JOIN SLC_REPL.dbo.Fan f 
		ON t.FanID = f.ID
	INNER JOIN SLC_REPL.dbo.Redeem red
		ON t.ItemID = red.ID
	WHERE
		CAST(t.[Date] AS date) BETWEEN @StartDate AND @EndDate
		AND (red.Privatedescription LIKE '%Donation to%' OR red.Privatedescription like '%Donate%') -- Charity donations
		AND (t.ItemID = @ItemID OR @ItemID IS NULL)
		-- AND t.TypeID <> 4 -- Exclude cancellations (overridden by condition below)
		AND t.TypeID = 3 -- Redemption (non-cancellation)
		AND t.ID <> 1000704535 -- Exclude test transaction

END