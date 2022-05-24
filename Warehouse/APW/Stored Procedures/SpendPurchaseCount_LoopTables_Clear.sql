-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Clears tables re-used in the SSIS loop
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_LoopTables_Clear] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.SpendPurchaseCount_CINSpend
	TRUNCATE TABLE APW.SpendPurchaseCount_CINExposed
	TRUNCATE TABLE APW.SpendPurchaseCountCombination

END