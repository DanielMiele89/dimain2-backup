-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Clears the APW.ControlBase_PseudoActivationAssign table
-- =============================================
CREATE PROCEDURE APW.ControlMethod_Base_PseudoActivationAssign_Clear
	
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.ControlBase_PseudoActivationAssign

END
