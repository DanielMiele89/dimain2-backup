-- =============================================
-- Author:		JEA
-- Create date: 02/06/2016
-- Description:	Retrieves correct number of base
-- control to form adjusted control
-- MUST BE CALLED USING THE 'WITH RESULT SETS' CLAUSE
-- IF USED IN AN SSIS DATA FLOW TASK due to its
-- dynamic sql
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_AdjustedControl_FetchByCategory] 
	(
		@FirstTranYear SMALLINT
		, @PrePeriodSpendID TINYINT
		, @AdjustedControlSize INT
	)
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @SQL VARCHAR(8000)

	IF @FirstTranYear = 0
	BEGIN
		SET @SQL = 'SELECT TOP ' + CAST(@AdjustedControlSize AS VARCHAR(10)) + ' c.CINID
			, CAST(0 AS SMALLINT) AS FirstTranYear
			, CAST(1 AS TINYINT) AS PrePeriodSpendID
			, ISNULL(s.PrePeriodSpend, 0) AS PrePeriodSpend
			, ISNULL(s.PrePeriodTranCount, 0) AS PrePeriodTranCount
			, c.PseudoActivatedMonthID
		FROM APW.ControlBase c
		LEFT OUTER JOIN APW.ControlBaseSpend s ON c.CINID = s.CINID
		WHERE c.FirstTranMonthID = 0
		ORDER BY NEWID()'
	END
	ELSE
	BEGIN
		SET @SQL = 'SELECT TOP ' + CAST(@AdjustedControlSize AS VARCHAR(10)) + ' c.CINID
			, d.DateYear AS FirstTranYear
			, c.PrePeriodSpendID
			, ISNULL(s.PrePeriodSpend, 0) AS PrePeriodSpend
			, ISNULL(s.PrePeriodTranCount, 0) AS PrePeriodTranCount
			, c.PseudoActivatedMonthID
		FROM APW.ControlBase c
		LEFT OUTER JOIN APW.ControlBaseSpend s ON c.CINID = s.CINID
		INNER JOIN APW.ControlDates d on c.FirstTranMonthID = d.ID
		WHERE d.DateYear = ' + CAST(@FirstTranYear AS VARCHAR(4)) + '
		AND c.PrePeriodSpendID = ' + CAST(@PrePeriodSpendID AS VARCHAR(1)) + '
		ORDER BY NEWID()'
	END

	EXEC(@SQL)

END