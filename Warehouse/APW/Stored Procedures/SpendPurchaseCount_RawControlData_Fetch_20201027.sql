-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Loads the spend and tran count for each member of the control group for the target brand
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawControlData_Fetch_20201027] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(YEAR, -1, @StartDate)

	SELECT c.CINID, COUNT(*) AS TranCount, SUM(ct.Amount) AS Spend
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.ControlAdjusted c ON ct.CINID = c.CINID
	INNER JOIN APW.SpendPurchaseCountCombination cc ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY c.CINID

END
