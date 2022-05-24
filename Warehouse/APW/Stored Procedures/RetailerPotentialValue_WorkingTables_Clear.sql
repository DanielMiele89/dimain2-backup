-- =============================================
-- Author:		JEA
-- Create date: 06/07/2017
-- Description:	Clears working tables for retailer potential value process
-- =============================================
CREATE PROCEDURE APW.RetailerPotentialValue_WorkingTables_Clear
 
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.RetailerPotentialValue_Brand

END