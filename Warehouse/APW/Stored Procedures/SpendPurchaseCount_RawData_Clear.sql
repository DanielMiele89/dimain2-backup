-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Clears the APW.SpendPurchaseCount_CINSpend table
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawData_Clear] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.SpendPurchaseCount_CINSpend

END
