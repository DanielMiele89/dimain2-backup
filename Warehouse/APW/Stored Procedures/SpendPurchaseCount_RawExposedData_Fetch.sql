-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Loads the spend and tran count for each member of the control group for the target brand
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawExposedData_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(YEAR, -1, @StartDate)

	SELECT c.CINID, SUM(ct.TranCount) AS TranCount, SUM(ct.Spend) AS Spend
	FROM [APW].[SpendPurchaseCount_CT_Exposed] ct WITH (NOLOCK)
	INNER JOIN APW.SpendPurchaseCount_CINExposed c ON ct.CINID = c.CINID
	INNER JOIN APW.SpendPurchaseCountCombination cc ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	GROUP BY c.CINID

END
