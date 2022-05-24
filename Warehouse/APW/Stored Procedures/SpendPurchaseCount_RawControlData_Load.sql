-- =============================================
-- Author:		JEA
-- Create date: 15/06/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawControlData_Load] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(YEAR, -1, @StartDate)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.ConsumerCombinationID
	INTO #CC
	FROM [Relational].[ConsumerCombination] cc
	WHERE EXISTS (	SELECT 1
					FROM [APW].[ControlRetailers] cr
					WHERE cc.BrandID = cr.BrandID)

	CREATE CLUSTERED INDEX CIX_CC ON #CC (ConsumerCombinationID)
	
	TRUNCATE TABLE [APW].[SpendPurchaseCount_CT_Control]

	INSERT INTO [APW].[SpendPurchaseCount_CT_Control]
	SELECT	ca.CINID
		,	ct.ConsumerCombinationID
		,	COUNT(*) AS TranCount
		,	SUM(ct.Amount) AS Spend
	FROM [Relational].[ConsumerTransaction] ct
	INNER JOIN [APW].[ControlAdjusted] ca
		ON ct.CINID = ca.CINID
	INNER JOIN #CC cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY	ca.CINID
			,	ct.ConsumerCombinationID

	ALTER INDEX CIX_CINCC ON [APW].[SpendPurchaseCount_CT_Control] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON)

END