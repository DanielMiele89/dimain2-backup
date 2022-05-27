-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Refreshes CBP Dashboard offer information
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Offers_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATE, @LastMonthStart DATE, @LastMonthEnd DATE, @LastWeekStart DATE, @LastWeekEnd DATE

	SET @ThisWeekEnd = DATEADD(DAY, -1, GETDATE())
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)
	SET @LastMonthStart = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
	SET @LastMonthEnd = DATEADD(DAY, -1, DATEADD(MONTH, 1, @LastMonthStart))
	SET @LastWeekEnd = DATEADD(DAY, -1, @ThisWeekStart)
	SET @LastWeekStart = DATEADD(DAY, -6, @LastWeekend)

    DECLARE @WOWOfferCountWeek INT, @WOWOfferCountMonth INT
		, @WOWOfferSpendCustomersWeek INT, @WOWOfferSentCustomersWeek INT
		, @WOWOfferSpendCustomersPrevious INT, @WOWOfferSentCustomersPrevious INT
		, @WOWSpendWeek MONEY, @WOWEarningsWeek MONEY, @WOWSpendPrevious MONEY, @WOWEarningsPrevious MONEY

	--Above base offers active at some point during the last week
	SELECT @WOWOfferCountWeek = COUNT(DISTINCT h.ClientServicesRef)
	FROM Relational.IronOffer o
	INNER JOIN Relational.IronOffer_Campaign_HTM h ON o.IronOfferID = h.IronOfferID
	WHERE O.AboveBase = 1
	AND o.StartDate <= @ThisWeekEnd
	AND (o.EndDate IS NULL OR o.EndDate >= @ThisWeekStart)

	--Above base offers active at some point during the previous calendar month
	SELECT @WOWOfferCountMonth = COUNT(DISTINCT h.ClientServicesRef)
	FROM Relational.IronOffer o
	INNER JOIN Relational.IronOffer_Campaign_HTM h ON o.IronOfferID = h.IronOfferID
	WHERE O.AboveBase = 1
	AND o.StartDate <= @LastMonthEnd
	AND (o.EndDate IS NULL OR o.EndDate >= @LastMonthStart)

	--Customers who earned against any above base offer during the last week
	--and total spend and earnings against above base offers
	SELECT @WOWOfferSpendCustomersWeek = COUNT(DISTINCT FanID)
		, @WOWSpendWeek = SUM(TransactionAmount)
		, @WOWEarningsWeek = SUM(CashbackEarned)
	FROM Relational.PartnerTrans
	WHERE AboveBase = 1
	AND AddedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	--Customers who earned against any above base offer during the previous week
	--and total spend and earnings against above base offers
	SELECT @WOWOfferSpendCustomersPrevious = COUNT(DISTINCT FanID)
		, @WOWSpendPrevious = SUM(TransactionAmount)
		, @WOWEarningsPrevious = SUM(CashbackEarned)
	FROM Relational.PartnerTrans
	WHERE AboveBase = 1
	AND AddedDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @WOWOfferSentCustomersWeek = COUNT(DISTINCT m.CompositeID)
	FROM Relational.IronOffer o
	INNER JOIN Relational.IronOfferMember m ON o.IronOfferID = m.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	INNER JOIN MI.CustomerActiveStatus ca ON c.FanID = ca.FanID
	WHERE O.AboveBase = 1
	AND o.StartDate <= @ThisWeekEnd
	AND (o.EndDate IS NULL OR o.EndDate >= @ThisWeekStart)
	AND ca.ActivatedDate <= @ThisWeekEnd
	AND (ca.DeactivatedDate IS NULL OR ca.DeactivatedDate > @ThisWeekStart)

	SELECT @WOWOfferSentCustomersPrevious = COUNT(DISTINCT m.CompositeID)
	FROM Relational.IronOffer o
	INNER JOIN Relational.IronOfferMember m ON o.IronOfferID = m.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	INNER JOIN MI.CustomerActiveStatus ca ON c.FanID = ca.FanID
	WHERE O.AboveBase = 1
	AND o.StartDate <= @LastWeekEnd
	AND (o.EndDate IS NULL OR o.EndDate >= @LastWeekStart)
	AND ca.ActivatedDate <= @LastWeekEnd
	AND (ca.DeactivatedDate IS NULL OR ca.DeactivatedDate > @LastWeekStart)

	DELETE FROM MI.CBPDashboard_Week_Offers

	INSERT INTO MI.CBPDashboard_Week_Offers(
		OfferCountWeek
		, WOWOfferCountMonth
		, WOWOfferCustomersSpendWeek
		, WOWOfferCustomersSentWeek
		, WOWOfferCustomersSpendPrevious
		, WOWOfferCustomersSentPrevious
		, WOWSpendWeek
		, WOWEarningsWeek
		, WOWSpendPrevious
		, WOWEarningsPrevious
		)

	SELECT @WOWOfferCountWeek AS OfferCountWeek
		, @WOWOfferCountMonth AS WOWOfferCountMonth
		, @WOWOfferSpendCustomersWeek WOWOfferCustomersSpendWeek
		, @WOWOfferSentCustomersWeek WOWOfferCustomersSentWeek
		, @WOWOfferSpendCustomersPrevious WOWOfferCustomersSpendPrevious
		, @WOWOfferSentCustomersPrevious WOWOfferCustomersSentPrevious
		, @WOWSpendWeek WOWSpendWeek
		, @WOWEarningsWeek WOWEarningsWeek
		, @WOWSpendPrevious WOWSpendPrevious
		, @WOWEarningsPrevious WOWEarningsPrevious

END
