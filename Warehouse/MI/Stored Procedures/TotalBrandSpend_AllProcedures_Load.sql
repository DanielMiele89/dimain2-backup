-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.TotalBrandSpend_AllProcedures_Load 
	
AS
BEGIN

	SET NOCOUNT ON;

	EXEC MI.TotalBrandSpend_Load_CJM
	EXEC MI.TotalBrandSpendCashbackPlus_Load_CJM
	EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_Container_Load_CJM

END