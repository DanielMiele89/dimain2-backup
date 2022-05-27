-- =============================================
-- Author:		JEA
-- Create date: 06/06/2016
-- Description:	Fetches adjustment factors by pseudo-activation month
-- =============================================
CREATE PROCEDURE APW.ControlMethod_ControlAdjustmentFactor_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.PseudoActivatedMonthID
		, c.CustomerCountControl
		, c.SpenderCountControl
		, c.TranCountControl
		, c.SpendControl
		, e.CustomerCountExposed
		, e.SpenderCountExposed
		, e.TranCountExposed
		, e.SpendExposed
	FROM
	(
		SELECT PseudoActivatedMonthID
			, COUNT(*) AS CustomerCountControl
			, SUM(CASE WHEN PrePeriodTranCount > 1 THEN 1 ELSE 0 END) AS SpenderCountControl
			, SUM(PrePeriodTranCount) AS TranCountControl
			, SUM(PrePeriodSpend) AS SpendControl
		FROM APW.ControlAdjusted
		GROUP BY PseudoActivatedMonthID
	) c
	INNER JOIN
	(
		SELECT c.ActivatedMonthID
			, COUNT(*) AS CustomerCountExposed
			, SUM(CASE ISNULL(s.PrePeriodTranCount,0) WHEN 0 THEN 0 ELSE 1 END) as SpenderCountExposed
			, SUM(ISNULL(s.PrePeriodTranCount,0)) AS TranCountExposed
			, SUM(ISNULL(s.PrePeriodSpend,0)) AS SpendExposed
		FROM APW.CustomersActive c
		LEFT OUTER JOIN APW.CustomersActiveSpend s ON c.CINID = s.CINID
		GROUP BY c.ActivatedMonthID
	) e ON c.PseudoActivatedMonthID = e.ActivatedMonthID
	ORDER BY PseudoActivatedMonthID

END
