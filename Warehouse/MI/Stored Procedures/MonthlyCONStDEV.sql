
-- =============================================
-- Author:		<AJS>
-- Create date: <24/07/2013>
-- Description:	<creates a monthly Stdev for a given month and partner For control customers>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyCONStDEV] 
	-- Add the parameters for the stored procedure here
	(@monthid INT, @PartnerID int, @ControlID int)
AS
BEGIN

DECLARE @StartDate date, @EndDate date

SELECT @StartDate = StartDate, @EndDate = EndDate
FROM Relational.SchemeUpliftTrans_Month WHERE ID = @monthid

select STDEV(isnull(PAS.Spend,0)) as CondevSpend, AVG(isnull(PAS.Spend,0)) as ConAVGSpend, @monthid as monthID, @PartnerID as PartnerID 

from Relational.Control_Stratified C
left join (
SELECT c.FanID, SUM(Amount) as Spend 
	FROM Relational.SchemeUpliftTrans s
	INNER JOIN Relational.Customer C on s.fanid = c.fanid
	WHERE AddedDate between @StartDate AND @EndDate and s.PartnerID = @PartnerID 
	AND Amount > 0
	GROUP BY c.FanID
) PAS on PAS.FanID = C.FanID
WHERE C.MonthID = @monthId and C.PartnerID = @ControlID


END