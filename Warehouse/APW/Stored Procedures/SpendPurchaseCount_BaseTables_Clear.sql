
-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Clears tables re-used in the SSIS loop
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_BaseTables_Clear] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.SpendPurchaseCount_RetailerSPS
	TRUNCATE TABLE APW.SpendPurchaseCount_RetailerPurchaseCount
	TRUNCATE TABLE APW.ControlRetailersSpendPurchase
	TRUNCATE TABLE APW.SpendPurchaseCount_RetailerAvgPurchases

END

