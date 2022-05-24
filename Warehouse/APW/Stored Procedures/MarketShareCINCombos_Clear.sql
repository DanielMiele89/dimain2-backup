-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.MarketShareCINCombos_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.MarketShareCINID
	TRUNCATE TABLE APW.MarketShareCombination

END