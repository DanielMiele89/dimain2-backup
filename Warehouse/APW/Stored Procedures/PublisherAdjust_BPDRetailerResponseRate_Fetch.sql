-- =============================================
-- Author:		JEA
-- Create date: 07/10/2016
-- Description:	Fetches the spender count
-- for brands marked for publisher adjustment
-- =============================================
CREATE PROCEDURE [APW].[PublisherAdjust_BPDRetailerResponseRate_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthStart DATE, @MonthEnd DATE

	--set dates to the most recently completed calendar month
	SET @MonthStart = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
	SET @MonthEnd = DATEADD(DAY, -1, @MonthStart)
	SET @MonthStart = DATEADD(MONTH, -1, @MonthStart)

	DECLARE @SampleSize FLOAT
	SELECT @SampleSize = COUNT(1) FROM APW.ControlAdjusted

	SELECT c.BrandID, CAST(COUNT(DISTINCT a.CINID) AS float)/@SampleSize AS ResponseRate
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN APW.PublisherAdjust_RetailerCombination c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
	INNER JOIN APW.ControlAdjusted a ON ct.CINID = a.CINID
	WHERE ct.TranDate BETWEEN @MonthStart AND @MonthEnd
	AND ct.IsOnline = 0
	GROUP BY c.BrandID

END
