-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.SchemeUpliftTrans_RetailOutletSignedOff_Clear 
	WITH EXECUTE AS OWNER

AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.SchemeUpliftTrans_RetailOutletSignedOff

END
