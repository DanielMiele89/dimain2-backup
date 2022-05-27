
CREATE PROCEDURE [Staging].[OfferReport_Fetch_OutlierReport]
AS
BEGIN

    DECLARE @ReportMonthStart DATE, @ReportMonthEnd DATE

    SET @ReportMonthStart = DATEADD(DAY, 1, EOMONTH(GETDATE(), -2))
    SET @ReportMonthEnd = EOMONTH(@ReportMonthStart)

    TRUNCATE TABLE Staging.OfferReport_OutlierExclusion_Checks

    IF OBJECT_ID('tempdb..#T1') IS NOT NULL DROP TABLE #T1
    SELECT
	   m.PartnerID,
	   m.BrandID,
	   Sum(Amount) as TotalSales,
	   SUM(CASE WHEN Amount >= UpperValue THEN Amount ELSE 0 END) as ExcludedSales,
        SUM(CASE WHEN Amount >= UpperValue THEN Amount ELSE 0 END)/Sum(Amount) as PercentageExcluded
    INTO #T1
    FROM Warehouse.relational.ConsumerTransaction ct with (nolock)
    JOIN Warehouse.relational.ConsumerCombination cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    JOIN Warehouse.Staging.OfferReport_OutlierExclusion m on m.BrandID = cc.BrandID AND m.EndDate IS NULL
    WHERE	Trandate Between @ReportMonthStart AND @ReportMonthEnd
	   AND Amount > 0
    GROUP BY m.PartnerID, m.BrandID
    HAVING SUM(CASE WHEN Amount >= UpperValue THEN Amount ELSE 0 END)/Sum(Amount) > 0.2

    INSERT INTO Staging.OfferReport_OutlierExclusion_Checks
    SELECT
	   t.BrandID
	   , t.PartnerID
	   , COALESCE(p.PartnerName, np.PartnerName) PartnerName
	   , t.TotalSales
	   , t.ExcludedSales
	   , t.PercentageExcluded
    FROM #T1 t
    LEFT JOIN Warehouse.Relational.Partner p on p.PartnerID = t.PartnerID
    LEFT JOIN nFI.Relational.Partner np on np.PartnerID = t.PartnerID

END