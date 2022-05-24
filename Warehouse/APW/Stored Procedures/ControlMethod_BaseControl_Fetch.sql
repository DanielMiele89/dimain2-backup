-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Retrieves unstratified control group and date of first spend
-- =============================================
CREATE PROCEDURE APW.ControlMethod_BaseControl_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.CINID
		, c.FirstTranDate
		, d.ID AS FirstTranMonthID
	FROM Relational.CustomerAttribute c
	LEFT OUTER JOIN APW.ControlDates d ON c.FirstTranDate BETWEEN d.StartDate AND d.EndDate
	INNER JOIN Relational.CINList CIN ON c.CINID = CIN.CINID
	LEFT OUTER JOIN Relational.Customer cu ON CIN.CIN = cu.SourceUID
	WHERE cu.SourceUID IS NULL

END
