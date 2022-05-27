-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Retrieves market spend data for market share
-- =============================================
CREATE PROCEDURE [APW].[MarketShareSpendData_FetchMonth] 
	(
		@PartnerID INT, @MonthStart DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthEnd DATE
	SET @MonthEnd = DATEADD(MONTH, 1, @MonthStart)
	SET @MonthEnd = DATEADD(DAY, -1, @MonthEnd)

	SELECT @PartnerID AS RetailerID, m.IsRetailer, c.IsSchemeMember, SUM(ct.Amount) AS Spend
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.MarketShareCINID c ON ct.CINID = c.CINID
	INNER JOIN APW.MarketShareCombination m ON ct.ConsumerCombinationID = m.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @MonthStart AND @MonthEnd
	GROUP BY m.IsRetailer, c.IsSchemeMember

END
