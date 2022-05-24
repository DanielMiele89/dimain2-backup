-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Retrieves median incremental sales ROI (ROS) and financial ROI (PIS) by tier
-- =============================================
create PROCEDURE [MI].[CBPDashboard_Week_ROI_Fetch_OLD] 
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @MonthID INT, @SalesTier1 MONEY, @SalesTier2 MONEY, @SalesTier3 MONEY
		, @FinancialTier1 MONEY, @FinancialTier2 MONEY, @FinancialTier3 MONEY
		, @Tier1Count INT, @Tier2Count INT, @Tier3Count INT


	SELECT @MonthID = MAX(MonthID)
	FROM MI.RetailerReportMonthly where LabelID = 1

	select top 10 * from mi.RetailerReportMetric

	SELECT m.PartnerID, m.IncrementalSales, SUM(w.ActivatedCommission) AS Commission, t.margin, f.Tier, b.ChargeOnRedeem
	INTO #Figures
	FROM MI.RetailerReportMonthly m
	INNER JOIN MI.RetailerReportWeekly w ON M.MonthID = W.MonthID AND M.PartnerID = W.PartnerID
	INNER JOIN MI.SchemeMarginsAndTargets t ON m.PartnerID = t.PartnerID
	INNER JOIN Relational.[Partner] p ON M.PartnerID = p.PartnerID
	INNER JOIN MI.SalesFunnelTier f ON p.BrandID = f.BrandID
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE m.MonthID = @MonthID
	AND m.LabelID = 1 and w.LabelID = 1
	AND t.IsNonCore = 0
	AND b.ChargeOnRedeem = 0
	GROUP BY m.PartnerID, m.IncrementalSales, t.margin, f.Tier, b.ChargeOnRedeem

	UPDATE #Figures SET Commission = IncrementalSales * 0.025
	WHERE PartnerID = 3960

	SELECT PartnerID, (IncrementalSales/Commission)/1.2 AS IncrementalSalesROI
		, (((margin * IncrementalSales)/Commission)/1.2)-1 AS FinancialROI
		, Tier
	INTO #ROI
	FROM #Figures

	--INCREMENTAL SALES VARIABLES

	SELECT @Tier1Count = SUM(CASE WHEN Tier = 1 THEN 1 ELSE 0 END)
		, @Tier2Count = SUM(CASE WHEN Tier = 2 THEN 1 ELSE 0 END)
		, @Tier3Count = SUM(CASE WHEN Tier = 3 THEN 1 ELSE 0 END)
	FROM #ROI

	SELECT @SalesTier1 = AVG(IncrementalSalesROI)
	FROM
	(
		SELECT IncrementalSalesROI, ROW_NUMBER() OVER (ORDER BY IncrementalSalesROI) AS RankNum
		FROM #ROI
		WHERE Tier = 1
	) R
	WHERE RankNum IN (@Tier1Count/2 + 1, (@Tier1Count + 1)/2)

	SELECT @SalesTier2 = AVG(IncrementalSalesROI)
	FROM
	(
		SELECT IncrementalSalesROI, ROW_NUMBER() OVER (ORDER BY IncrementalSalesROI) AS RankNum
		FROM #ROI
		WHERE Tier = 2
	) R
	WHERE RankNum IN (@Tier2Count/2 + 1, (@Tier2Count + 1)/2)

	SELECT @SalesTier3 = AVG(IncrementalSalesROI)
	FROM
	(
		SELECT IncrementalSalesROI, ROW_NUMBER() OVER (ORDER BY IncrementalSalesROI) AS RankNum
		FROM #ROI
		WHERE Tier = 3
	) R
	WHERE RankNum IN (@Tier3Count/2 + 1, (@Tier3Count + 1)/2)

	--FINANCIAL ROI

	SELECT @FinancialTier1 = AVG(FinancialROI)
	FROM
	(
		SELECT FinancialROI, ROW_NUMBER() OVER (ORDER BY FinancialROI) AS RankNum
		FROM #ROI
		WHERE Tier = 1
	) R
	WHERE RankNum IN (@Tier1Count/2 + 1, (@Tier1Count + 1)/2)

	SELECT @FinancialTier2 = AVG(FinancialROI)
	FROM
	(
		SELECT FinancialROI, ROW_NUMBER() OVER (ORDER BY FinancialROI) AS RankNum
		FROM #ROI
		WHERE Tier = 2
	) R
	WHERE RankNum IN (@Tier2Count/2 + 1, (@Tier2Count + 1)/2)

	SELECT @FinancialTier3 = AVG(FinancialROI)
	FROM
	(
		SELECT FinancialROI, ROW_NUMBER() OVER (ORDER BY FinancialROI) AS RankNum
		FROM #ROI
		WHERE Tier = 3
	) R
	WHERE RankNum IN (@Tier3Count/2 + 1, (@Tier3Count + 1)/2)

	SELECT @SalesTier1 SalesTier1, @SalesTier2 SalesTier2, @SalesTier3 SalesTier3
		, @FinancialTier1 FinancialTier1, @FinancialTier2 FinancialTier2, @FinancialTier3 FinancialTier3

	DROP TABLE #Figures
	DROP TABLE #ROI

END
