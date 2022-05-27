-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Sets NULL FirstTranMonthIDs to 0
-- =============================================
CREATE PROCEDURE APW.ControlMethod_NullFirstTransIDs_Fix 
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE APW.CustomersActive
	SET FirstTranMonthID = 0
	WHERE FirstTranMonthID IS NULL

	UPDATE APW.ControlBase
	SET FirstTranMonthID = 0
	WHERE FirstTranMonthID IS NULL

END
