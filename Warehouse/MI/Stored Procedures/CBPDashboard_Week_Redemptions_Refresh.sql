-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Redemption figures for CBP Weekly Dashboard
-- =============================================
CREATE PROCEDURE MI.CBPDashboard_Week_Redemptions_Refresh 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATETIME, @LastWeekStart DATE, @LastWeekEnd DATETIME, @YearStart DATE

	SET @ThisWeekEnd = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)
	SET @LastWeekEnd = DATEADD(DAY, -1, @ThisWeekStart)
	SET @LastWeekStart = DATEADD(DAY, -6, @LastWeekend)
	SET @YearStart = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

	--add time component because redemptions have a time
	SET @ThisWeekEnd = DATEADD(MINUTE, -1, DATEADD(DAY, 1, @ThisWeekEnd))
	SET @LastWeekEnd = DATEADD(MINUTE, -1, DATEADD(DAY, 1, @LastWeekEnd))

	DECLARE @CashCountThisWeek INT, @TradeUpCountThisWeek INT, @CharityCountThisWeek INT
		, @CashCountLastWeek INT, @TradeUpCountLastWeek INT, @CharityCountLastWeek INT
		, @CashCountYear INT, @TradeUpCountYear INT, @CharityCountYear INT
		, @RedeemValueYear MONEY

	--THIS WEEK
	SELECT @CashCountThisWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Cash'
	AND RedeemDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @TradeUpCountThisWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Trade Up'
	AND RedeemDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @CharityCountThisWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Charity'
	AND RedeemDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	--LAST WEEK
	SELECT @CashCountLastWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Cash'
	AND RedeemDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @TradeUpCountLastWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Trade Up'
	AND RedeemDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @CharityCountLastWeek = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Charity'
	AND RedeemDate BETWEEN @LastWeekStart AND @LastWeekEnd

	--YEAR TO DATE
	SELECT @CashCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Cash'
	AND RedeemDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @TradeUpCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Trade Up'
	AND RedeemDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @CharityCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Charity'
	AND RedeemDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @RedeemValueYear = SUM(CashbackUsed)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemDate BETWEEN @YearStart AND @ThisWeekEnd

	DELETE FROM MI.CBPDashboard_Week_Redemptions

	INSERT INTO MI.CBPDashboard_Week_Redemptions(CashCountThisWeek, TradeUpCountThisWeek, CharityCountThisWeek, CashCountLastWeek, TradeUpCountLastWeek
		, CharityCountLastWeek, CashCountYear, TradeUpCountYear, CharityCountYear, RedeemValueYear)

	SELECT @CashCountThisWeek CashCountThisWeek, @TradeUpCountThisWeek TradeUpCountThisWeek, @CharityCountThisWeek CharityCountThisWeek
		, @CashCountLastWeek CashCountLastWeek, @TradeUpCountLastWeek TradeUpCountLastWeek, @CharityCountLastWeek CharityCountLastWeek
		, @CashCountYear CashCountYear, @TradeUpCountYear TradeUpCountYear, @CharityCountYear CharityCountYear
		, @RedeemValueYear RedeemValueYear

END