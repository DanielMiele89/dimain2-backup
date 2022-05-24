-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.MOMRetailerTracking_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.MID
		, b.BrandID
		, b.BrandName
		, CAST(MAX(CAST(a.RewardTrackable AS TINYINT)) AS BIT) AS RewardTrackable
		, a.AcquirerName AS Acquirer
		, SUM(r.AnnualSpend) AS AnnualSpend
		, CAST(MAX(CAST(r.TransactedOnDate AS TINYINT)) AS BIT) AS TransactedOnDate
		, MAX(r.TransactedDate) AS TransactedDate
	FROM MI.RetailerTrackingAcquirer r
	INNER JOIN Relational.ConsumerCombination c ON r.ConsumerCombinationID = c.ConsumerCombinationID
	INNER JOIN Relational.Acquirer a ON r.AcquirerID = a.AcquirerID
	INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID
	WHERE c.MID != ''
	GROUP BY c.MID
		, b.BrandID
		, b.BrandName
		, a.AcquirerName

END