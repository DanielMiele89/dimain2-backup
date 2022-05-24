
-- =============================================
-- Author:		JEA
-- Create date: 24/07/2014
-- Description:	Loads weekly retailer summary information
-- designed to return results according to a data-driven subscription
-- =============================================
CREATE PROCEDURE [MI].[RewardWeeklySummaryRetailer_Load_Old]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE, @PartnerName VARCHAR(50)

	--set the start and end date values to the monday and sunday of the most recently completed week
	SET @EndDate = DATEADD(DAY, -1,GETDATE())

	--take enddate back until it is the last sunday
	WHILE DATENAME(DW, @EndDate) != 'Sunday'
	BEGIN
		SET @EndDate = DATEADD(DAY, -1, @EndDate)
	END

	--set startdate to the preceding monday
	SET @StartDate = DATEADD(DAY, -6, @EndDate)

	CREATE TABLE #Partners(PartnerID INT PRIMARY KEY
		, PartnerName VARCHAR(50) NOT NULL
		, CumulativeStartDate DATE NOT NULL)

	INSERT INTO #Partners(PartnerID, PartnerName, CumulativeStartDate)
	SELECT m.PartnerID
		, p.PartnerName
		, COALESCE(cs.CustomStartDate,m.Advertised_Launch_Date) AS CumulativeDate
	FROM Relational.Master_Retailer_Table m
	INNER JOIN Relational.[Partner] p ON m.PartnerID = p.PartnerID
	LEFT OUTER JOIN Warehouse.Staging.Reward_StaffTable e ON e.StaffID = m.CS_Lead_ID
	LEFT OUTER JOIN MI.RewardWeeklySummary_CustomStartDate cs ON m.PartnerID = cs.PartnerID
	LEFT OUTER JOIN MI.RewardWeeklySummary_PartnersClosed cl ON m.PartnerID = cl.PartnerID
	WHERE m.Advertised_Launch_Date IS NOT NULL
	AND cl.PartnerID IS NULL

	TRUNCATE TABLE MI.RewardWeeklySummary

	INSERT INTO MI.RewardWeeklySummary(PartnerID
		, PartnerName
		, SalesWeek
		, SalesCumul
		, TranCountWeek
		, TranCountCumul
		, UniqueSpendersWeek
		, UniqueSpendersCumul
		, TargetedCustomersWeek
		, TargetedCustomersCumul
		, CommissionWeek
		, CommissionCumul
		, WeekStartDate
		, WeekEndDate
		, CumulativeDate
		, SalesWeekOnline
		, SalesCumulOnline
		, CommissionWeekOnline
		, CommissionCumulOnline)

	--return weekly and cumulative results for the retailer
	SELECT w.PartnerID 
		, w.PartnerName AS PartnerName
		, ISNULL(w.SalesWeek, 0) AS SalesWeek
		, ISNULL(c.SalesCumul, 0) AS SalesCumul
		, ISNULL(w.TranCountWeek, 0) AS TranCountWeek
		, ISNULL(c.TranCountCumul, 0) AS TranCountCumul
		, ISNULL(w.UniqueSpendersWeek, 0) AS UniqueSpendersWeek
		, ISNULL(c.UniqueSpendersCumul, 0) AS UniqueSpendersCumul
		, ISNULL(tw.TargetedCustomersWeek,0) AS TargetedCustomersWeek
		, ISNULL(tc.TargetedCustomersCumul,0) AS TargetedCustomersCumul
		, CASE WHEN w.PartnerID = 3960 THEN CAST(0 AS MONEY) ELSE ISNULL(w.CommissionWeek, 0) END AS CommissionWeek
		, CASE WHEN w.PartnerID = 3960 THEN CAST(0 AS MONEY) ELSE ISNULL(c.CommissionCumul, 0) END AS CommissionCumul
		, @StartDate AS WeekStartDate
		, @EndDate AS WeekEndDate
		, w.CumulativeStartDate
		, ISNULL(w.SalesWeekOnline, 0) AS SalesWeekOnline
		, ISNULL(c.SalesCumulOnline, 0) AS SalesCumulOnline
		, CASE WHEN w.PartnerID = 3960 THEN CAST(0 AS MONEY) ELSE ISNULL(w.CommissionWeekOnline, 0) END AS CommissionWeekOnline
		, CASE WHEN w.PartnerID = 3960 THEN CAST(0 AS MONEY) ELSE ISNULL(c.CommissionCumulOnline, 0) END AS CommissionCumulOnline
	FROM
	(
		SELECT p.PartnerID 
			, p.PartnerName
			, P.CumulativeStartDate 
			, SUM(TransactionAmount) AS SalesWeek
			, SUM(CASE WHEN IsOnline = 1 then TransactionAmount ELSE 0 END) AS SalesWeekOnline
			, COUNT(1) AS TranCountWeek
			, COUNT(DISTINCT FanID) AS UniqueSpendersWeek
			, SUM(CommissionChargable) AS CommissionWeek
			, SUM(CASE WHEN IsOnline = 1 then CommissionChargable ELSE 0 END) AS CommissionWeekOnline
		FROM #Partners p
		LEFT OUTER JOIN Relational.PartnerTrans pt ON P.PartnerID = pt.PartnerID
		WHERE pt.AddedDate BETWEEN @StartDate AND @EndDate
		GROUP BY p.PartnerID 
			, p.PartnerName
			, P.CumulativeStartDate
	) w
	INNER JOIN 
	(
		SELECT p.PartnerID 
			, SUM(TransactionAmount) AS SalesCumul
			, SUM(CASE WHEN IsOnline = 1 then TransactionAmount ELSE 0 END) AS SalesCumulOnline
			, COUNT(1) AS TranCountCumul
			, COUNT(DISTINCT FanID) AS UniqueSpendersCumul
			, SUM(CommissionChargable) AS CommissionCumul
			, SUM(CASE WHEN IsOnline = 1 then CommissionChargable ELSE 0 END) AS CommissionCumulOnline
		FROM #Partners p
		LEFT OUTER JOIN Relational.PartnerTrans pt ON P.PartnerID = pt.PartnerID
		WHERE pt.AddedDate BETWEEN p.CumulativeStartDate AND @EndDate
		GROUP BY p.PartnerID
	) c ON w.PartnerID = c.PartnerID
	LEFT OUTER JOIN
	(
		SELECT p.PartnerID, COUNT(DISTINCT s.FanID) AS TargetedCustomersWeek
		FROM Relational.IronOfferMember m
		INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
		INNER JOIN #Partners p ON o.PartnerID = p.PartnerID
		INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
		INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
		WHERE o.StartDate <= @EndDate
		AND (o.EndDate IS NULL OR o.EndDate >= @StartDate)
		AND s.ActivatedDate <= @EndDate
		AND (s.DeactivatedDate IS NULL OR s.DeactivatedDate >= @StartDate)
		GROUP BY p.PartnerID
	) tw ON w.PartnerID = tw.PartnerID
	LEFT OUTER JOIN
	(
		SELECT p.PartnerID, COUNT(DISTINCT s.FanID) AS TargetedCustomersCumul
		FROM Relational.IronOfferMember m
		INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
		INNER JOIN #Partners p ON o.PartnerID = p.PartnerID
		INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
		INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
		WHERE o.StartDate <= @EndDate
		AND (o.EndDate IS NULL OR o.EndDate >= p.CumulativeStartDate)
		AND s.ActivatedDate <= @EndDate
		AND (s.DeactivatedDate IS NULL OR s.DeactivatedDate >= p.CumulativeStartDate)
		GROUP BY p.PartnerID
	) tc ON w.PartnerID = tc.PartnerID

END