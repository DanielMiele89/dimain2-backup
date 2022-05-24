-- =============================================
-- Author:		JEA
-- Create date: 01/07/2014
-- Description:	Retrieves spend projections for the retailer prospect report
-- =============================================
CREATE PROCEDURE MI.RetailerProspect_ProjectedSpend_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT b.brandid
		, b.brandname
		, SUM(ProjectedCoreAnnualSpend) AS ProjectedCoreAnnualSpend
		, SUM(ProjectedNonCoreAnnualSpend) AS ProjectedNonCoreAnnualSpend
		, SUM(ProjectedQuidcoAnnualSpend) AS ProjectedQuidcoAnnualSpend
	FROM
	(
		SELECT M.MonthID
			, s.BrandID
			, (s.CoreSpend/s.CoreSpenders) * (CAST(S.CoreSpenders AS FLOAT)/CAST(M.ActualCustomerCount AS FLOAT) * m.ProjectedCustomerCount) AS ProjectedCoreAnnualSpend
			, (s.NonCoreSpend/s.NonCoreSpenders) * (CAST(S.NonCoreSpenders AS FLOAT)/CAST(M.ActualCustomerCount AS FLOAT) * m.ProjectedCustomerCount) AS ProjectedNonCoreAnnualSpend
			, CASE WHEN s.QuidcoSpenders = 0 THEN 0 ELSE(s.QuidcoSpend/s.QuidcoSpenders) * (CAST(S.QuidcoSpenders AS FLOAT)/CAST(m.ActualQuidcoCount AS FLOAT) * m.ProjectedQuidcoCount * 0.6) END AS ProjectedQuidcoAnnualSpend
		FROM
		(
			SELECT p.MonthID, a.ActiveCount AS ActualCustomerCount, a.QuidcoCount AS ActualQuidcoCount, p.ActiveCount AS ProjectedCustomerCount, p.QuidcoCount AS ProjectedQuidcoCount
			FROM MI.RetailerProspect_ActiveCustomerActual a
			CROSS JOIN MI.RetailerProspect_ActiveCustomerMonthProjected p
		) M
		INNER JOIN
		(
		SELECT C.MonthID, c.BrandID, c.Spend AS CoreSpend, c.Spenders AS CoreSpenders
			, n.Spend AS NonCoreSpend, n.Spenders AS NonCoreSpenders
			, ISNULL(q.Spend,0) AS QuidcoSpend, ISNULL(q.Spenders,0) AS QuidcoSpenders
		FROM MI.RetailerProspect_CoreSpend c
		INNER JOIN  MI.RetailerProspect_NonCoreSpend n ON c.BrandID = n.BrandID and c.MonthID = n.MonthID
		LEFT OUTER JOIN MI.RetailerProspect_QuidcoSpend q ON c. BrandID = q.BrandID and c.MonthID = q.MonthID
		LEFT OUTER JOIN (SELECT DISTINCT BrandID
							FROM
							(
								SELECT s.BrandID, [Date] AS StatusDate, FunnelStatus
								FROM MI.SalesFunnel s
								INNER JOIN
								(
									SELECT BrandID, MAX([Date]) As StatusDate
									FROM MI.SalesFunnel
									GROUP BY BrandID
								) m ON s.BrandID = m.BrandID and s.[Date] = m.StatusDate
							) b
							WHERE FunnelStatus >= 7
			) S ON c.BrandID = s.BrandID
		WHERE S.BrandID IS NULL
		) S ON M.MonthID = S.MonthID
	) T
	INNER JOIN Relational.Brand b ON t.BrandID = b.BrandID
	GROUP BY b.brandid, b.brandname
	ORDER BY ProjectedCoreAnnualSpend DESC

END
