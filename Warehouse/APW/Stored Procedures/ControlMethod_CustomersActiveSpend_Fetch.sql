-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Fetches spend for active customers
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_CustomersActiveSpend_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.CINID, SUM(ct.Amount) AS Spend, COUNT(1) AS TranCount
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.CustomersActive c ON ct.CINID = c.CINID AND ct.TranDate BETWEEN c.PrePeriodStartDate AND c.PrePeriodEndDate
	INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
	GROUP BY c.CINID

END
