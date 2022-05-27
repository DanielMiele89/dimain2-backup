-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Loads all base control with specified first tran month ID in random order
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_Base_PseudoActivationAssign_Fetch]
	(
		@FirstTranMonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CINID
		, FirstTranMonthID
	FROM APW.ControlBase
	WHERE FirstTranMonthID = @FirstTranMonthID
	ORDER BY NEWID()

END
