-- =============================================
-- Author:		<AJS>
-- Create date: <24/07/2013>
-- Description:	<creates a monthly Stdev for a given month and partner>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyCusStDEVold] 
	-- Add the parameters for the stored procedure here
	(@monthid INT, @PartnerID int)
AS
BEGIN

DECLARE @StartDate date, @EndDate date

SELECT @StartDate = StartDate, @EndDate = EndDate
FROM Relational.SchemeUpliftTrans_Month WHERE ID = @monthid

select --max((isnull(PAS.PreActiveSpend,0) + isnull(PDS.PostDeActiveSpend,0) + isnull(ACS.ActiveSpend,0))) as MaxSpend, min((isnull(PAS.PreActiveSpend,0) + isnull(PDS.PostDeActiveSpend,0) + isnull(ACS.ActiveSpend,0))) as minSpend,
STDEV((isnull(PAS.PreActiveSpend,0) + isnull(PDS.PostDeActiveSpend,0) + isnull(ACS.ActiveSpend,0))) as devSpend, AVG((isnull(PAS.PreActiveSpend,0) + isnull(PDS.PostDeActiveSpend,0) + isnull(ACS.ActiveSpend,0))) as AVGSpend, @MonthID as MonthID, @PartnerID as PartnerID

from Relational.Customer C
left join (
SELECT c.FanID, SUM(Amount) as PreActiveSpend, @PartnerID as PartnerID, @monthid as monthid
	FROM Relational.SchemeUpliftTrans s
	INNER JOIN Relational.Customer C on s.fanid = c.fanid
	WHERE AddedDate between @StartDate AND @EndDate and s.PartnerID = @PartnerID
	and (s.AddedDate < c.ActivatedDate)
	AND Amount > 0
	GROUP BY c.FanID
) PAS on PAS.FanID = C.FanID
left join (
SELECT c.FanID, SUM(Amount) as PostDeActiveSpend 
	FROM Relational.SchemeUpliftTrans s
	INNER JOIN Relational.Customer C on s.fanid = c.fanid
	WHERE AddedDate between @StartDate AND @EndDate and s.PartnerID = @PartnerID
	and (s.AddedDate > c.DeactivatedDate)
	AND Amount > 0
	GROUP BY c.FanID
) PDS on PDS.FanID = C.FanID
Left join (
SELECT c.FanID, SUM(TransactionAmount) as ActiveSpend 
	FROM Relational.PartnerTrans p
	INNER JOIN Relational.Customer C on P.fanid = c.fanid
	WHERE AddedDate between @StartDate AND @EndDate and P.PartnerID = @PartnerID
	and (P.AddedDate >= c.ActivatedDate and (c.DeactivatedDate is null or P.AddedDate < c.DeactivatedDate))
	AND TransactionAmount > 0
	GROUP BY c.FanID
) ACS on ACS.FanID = C.FanID
WHERE C.ActivatedDate <= @EndDate and (C.DeactivatedDate is null or C.DeactivatedDate >= @EndDate)



END