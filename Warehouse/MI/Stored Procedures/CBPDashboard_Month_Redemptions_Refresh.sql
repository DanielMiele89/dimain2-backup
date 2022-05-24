-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Redemption figures for CBP Monthly Dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Redemptions_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisMonthStart DATE, @ThisMonthEnd DATETIME,@YearStart DATE

	SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthStart)
	SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthStart)
	SET @YearStart = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

	--add time component because redemptions have a time
	SET @ThisMonthEnd = DATEADD(MINUTE, -1, DATEADD(DAY, 1, @ThisMonthEnd))

	DECLARE @CashCountThisMonth INT, @TradeUpCountThisMonth INT, @CharityCountThisMonth INT
		, @CashCountYear INT, @TradeUpCountYear INT, @CharityCountYear INT
		, @RedeemValueYear MONEY

	--THIS WEEK
	SELECT @CashCountThisMonth = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Cash'
	AND RedeemDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @TradeUpCountThisMonth = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Trade Up'
	AND RedeemDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @CharityCountThisMonth = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Charity'
	AND RedeemDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	--YEAR TO DATE
	SELECT @CashCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Cash'
	AND RedeemDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @TradeUpCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Trade Up'
	AND RedeemDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @CharityCountYear = COUNT(1)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemType = 'Charity'
	AND RedeemDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @RedeemValueYear = SUM(CashbackUsed)
	FROM Relational.Redemptions
	WHERE Cancelled = 0
	AND RedeemDate BETWEEN @YearStart AND @ThisMonthEnd

	DELETE FROM MI.CBPDashboard_Month_Redemptions

	INSERT INTO MI.CBPDashboard_Month_Redemptions(CashCountThisMonth, TradeUpCountThisMonth, CharityCountThisMonth
		, CashCountYear, TradeUpCountYear, CharityCountYear, RedeemValueYear)

	SELECT @CashCountThisMonth CashCountThisMonth, @TradeUpCountThisMonth TradeUpCountThisMonth, @CharityCountThisMonth CharityCountThisMonth
		, @CashCountYear CashCountYear, @TradeUpCountYear TradeUpCountYear, @CharityCountYear CharityCountYear
		, @RedeemValueYear RedeemValueYear

END