-- =============================================
-- Author:		JEA
-- Create date: 06/06/2016
-- Description:	Calculates control adjustment factors
-- =============================================
CREATE PROCEDURE APW.ControlMethod_AdjustmentFactors_Set 

AS
BEGIN

	SET NOCOUNT ON;

	UPDATE APW.ControlAdjustmentFactor
		SET RRAdjustmentFactor = (SpenderCountExposed/CustomerCountExposed)/(SpenderCountControl/CustomerCountControl)
		, SPSAdjustmentFactor = (SpendExposed/SpenderCountExposed)/(SpendControl/SpenderCountControl)
		, ATVAdjustmentFactor = (SpendExposed/TranCountExposed)/(SpendControl/TranCountControl)
		, ATFAdjustmentFactor = (TranCountExposed/SpenderCountExposed)/(TranCountControl/SpenderCountControl)

END
