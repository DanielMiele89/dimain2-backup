-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Retrieves market spend data for market share
-- =============================================
CREATE PROCEDURE [APW].[MarketShareSpendData_Fetch] 
	(
		@PartnerID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthStart DATE, @MonthEnd DATE
	SET @MonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)

	SET @MonthEnd = DATEADD(DAY, -1, @MonthStart)
	SET @MonthStart = DATEADD(MONTH, -1, @MonthStart)


	SELECT @PartnerID AS RetailerID, m.IsRetailer, c.IsSchemeMember, SUM(ct.Amount) AS Spend
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.MarketShareCINID c ON ct.CINID = c.CINID
	INNER JOIN APW.MarketShareCombination m ON ct.ConsumerCombinationID = m.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @MonthStart AND @MonthEnd
	GROUP BY m.IsRetailer, c.IsSchemeMember

END
