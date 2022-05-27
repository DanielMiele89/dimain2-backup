
-- =============================================
-- Author:		JEA
-- Create date: 01/06/2016
-- Description:	Sets PrePeriodSpendID ON APW.ControlBase table
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_Base_PrePeriodSpendID_Set] 
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE c SET PrePeriodSpendID = p.TypeID
	FROM APW.ControlBase c
	INNER JOIN APW.ControlBaseSpend s ON c.CINID = S.CINID
	LEFT OUTER JOIN APW.ControlPrePeriodSpend p ON s.PrePeriodSpend BETWEEN p.MinSpend AND p.MaxSpend

	UPDATE APW.ControlBase SET PrePeriodSpendID = 1
	WHERE PrePeriodSpendID IS NULL

END

