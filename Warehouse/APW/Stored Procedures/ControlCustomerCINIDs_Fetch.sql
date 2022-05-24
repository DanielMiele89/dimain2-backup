-- =============================================
-- Author:		JEA
-- Create date: 09/06/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.ControlCustomerCINIDs_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT CINID, CAST(0 AS BIT) AS IsScheme
	FROM APW.ControlAdjusted

END
