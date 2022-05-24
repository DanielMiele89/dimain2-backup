

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 09/10/2015
-- Description: Cashback awarded after end date
-- ***************************************************************************
CREATE PROCEDURE Staging.SSRS_R0105_CashbackAwarded_Outside_TransactionDatePeriod
			(
			@StartDate DATE,
			@EndDate DATE,
			@PartnerID INT
			)
												
AS
BEGIN
	SET NOCOUNT ON;
	

SELECT	@PartnerID as PartnerID,
	p.PartnerName,
	TransactionDate,
	SUM(CashbackEarned) as CashbackEarned
FROM Warehouse.Relational.PartnerTrans pt
INNER JOIN Warehouse.Relational.Partner p
	ON pt.PartnerID = p.PartnerID
WHERE	TransactionDate BETWEEN @StartDate AND @EndDate
	AND AddedDate > @EndDate
	AND pt.PartnerID = @PartnerID
GROUP BY p.PartnerName, TransactionDate
ORDER BY TransactionDate ASC


END










