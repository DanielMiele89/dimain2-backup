-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Loads the spend and tran count for each member of the control group for the target brand
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawControlData_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT c.CINID, SUM(ct.TranCount) AS TranCount, SUM(ct.Spend) AS Spend
	FROM [APW].[SpendPurchaseCount_CT_Control] ct
	INNER JOIN APW.ControlAdjusted c ON ct.CINID = c.CINID
	INNER JOIN APW.SpendPurchaseCountCombination cc ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	GROUP BY c.CINID

END
