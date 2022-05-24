-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Refreshes CBP Dashboard offer information
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Offers_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ThisMonthStart DATE, @ThisMonthEnd DATE

	SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthStart)
	SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthStart)

    DECLARE @WOWOfferCountMonth INT, @WOWOfferCustomersMonth INT, @WOWSpendMonth MONEY, @WOWEarningsMonth MONEY

	--Above base offers active at some point during the last week
	SELECT @WOWOfferCountMonth = COUNT(DISTINCT h.ClientServicesRef)
	FROM Relational.IronOffer o
	INNER JOIN Relational.IronOffer_Campaign_HTM h ON o.IronOfferID = h.IronOfferID
	WHERE O.AboveBase = 1
	AND o.StartDate <= @ThisMonthEnd
	AND o.EndDate >= @ThisMonthStart

	--Customers who earned against any above base offer during the last week
	--and total spend and earnings against above base offers
	SELECT @WOWOfferCustomersMonth = COUNT(DISTINCT FanID)
		, @WOWSpendMonth = SUM(TransactionAmount)
		, @WOWEarningsMonth = SUM(CashbackEarned)
	FROM Relational.PartnerTrans
	WHERE AboveBase = 1
	AND AddedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	DELETE FROM MI.CBPDashboard_Month_Offers

	INSERT INTO MI.CBPDashboard_Month_Offers(WOWOfferCountMonth, WOWOfferCustomersMonth, WOWSpendMonth, WOWEarningsMonth)

	SELECT @WOWOfferCountMonth AS WOWOfferCountMonth, @WOWOfferCustomersMonth WOWOfferCustomersMonth, @WOWSpendMonth WOWSpendMonth, @WOWEarningsMonth WOWEarningsMonth

END