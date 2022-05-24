-- =============================================
-- Author:		JEA
-- Create date: 02/06/2016
-- Description:	Retrieves parameter list for adjusted control group
-- =============================================
CREATE PROCEDURE APW.ControlMethod_AdjustedControlParams_List

AS
BEGIN

	SET NOCOUNT ON;

	SELECT FirstTranYear, PrePeriodSpendID, AdjustedControlSize
	FROM APW.ControlExposedPercentageMakeup
	WHERE AdjustedControlSize > 0
	ORDER BY FirstTranYear, PrePeriodSpendID

END