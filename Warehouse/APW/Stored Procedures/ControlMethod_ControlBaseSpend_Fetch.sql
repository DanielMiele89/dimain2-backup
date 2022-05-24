-- =============================================
-- Author:		JEA
-- Create date: 01/06/2016
-- Description:	Fetches control pre-period spend
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_ControlBaseSpend_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.CINID, SUM(ct.Amount) AS Spend, COUNT(*) AS TranCount
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.ControlBase c ON ct.CINID = c.CINID AND ct.TranDate BETWEEN c.PrePeriodStartDate AND c.PrePeriodEndDate
	INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
	GROUP BY c.CINID

END
