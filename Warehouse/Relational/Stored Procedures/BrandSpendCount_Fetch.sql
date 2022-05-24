-- =============================================
-- Author:		JEA
-- Create date: 30/10/2012
-- Description:	A commonly used query to return
-- spend, transaction count and unique customer
-- count over a specified time period.
-- =============================================
CREATE PROCEDURE Relational.BrandSpendCount_Fetch 
	(
		@BrandID SmallInt
		, @StartDate SmallDateTime
		, @EndDate SmallDateTime
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT SUM(c.Amount) AS TotalAmount
		, COUNT(1) AS TransCount
		, COUNT(DISTINCT c.CINID) AS CustomerCount
	FROM Relational.CardTransaction c
	INNER JOIN Relational.BrandMID b ON c.BrandMIDID = b.BrandMIDID
	WHERE b.BrandID = @BrandID
	AND c.TranDate BETWEEN @StartDate AND @EndDate
    
END