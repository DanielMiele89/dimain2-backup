-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Sets PrePeriodSpendID ON APW.CustomersActive table
-- =============================================
CREATE PROCEDURE APW.ControlMethod_CustomersActive_PrePeriodSpendID_Set 
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE c SET PrePeriodSpendID = p.TypeID
	FROM APW.CustomersActive c
	INNER JOIN APW.CustomersActiveSpend s ON c.CINID = S.CINID
	LEFT OUTER JOIN APW.ControlPrePeriodSpend p ON s.PrePeriodSpend BETWEEN p.MinSpend AND p.MaxSpend

	UPDATE APW.CustomersActive SET PrePeriodSpendID = 1
	WHERE PrePeriodSpendID IS NULL

END