-- =============================================
-- Author:		JEA
-- Create date: 11/03/2016
-- Description:	Retrieves Pivoted summary of brands and acquirers
-- =============================================
CREATE PROCEDURE [MI].[MOMRetailerTrackingSummary_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT BrandID
		, BrandName
		, ISNULL([Barclaycard Business],0) AS [Barclaycard Business]
		, ISNULL([Cardnet],0) AS [Cardnet]
		, ISNULL([Chase],0) AS [Chase]
		, ISNULL([Elavon],0) AS [Elavon]
		, ISNULL([Foreign],0) AS [Foreign]
		, ISNULL([Global Payments],0) AS [Global Payments]
		, ISNULL([HBOS],0) AS [HBOS]
		, ISNULL([Unknown],0) AS [Unknown]
		, ISNULL([WorldPay],0) AS [WorldPay]
		, ISNULL([WorldPay Reward],0) AS [WorldPay Reward]
		, (ISNULL([Barclaycard Business],0) + ISNULL([Cardnet],0) + ISNULL([Chase],0) + ISNULL([Elavon],0) + ISNULL([Foreign],0) + ISNULL([Global Payments],0) 
			+ ISNULL([HBOS],0) + ISNULL([Unknown],0) + ISNULL([WorldPay],0) + ISNULL([WorldPay Reward],0)) AS [Grand Total]
		, (ISNULL([Barclaycard Business],0) + ISNULL([Cardnet],0) + ISNULL([Elavon],0) + ISNULL([HBOS],0) + ISNULL([WorldPay Reward],0)) AS [Reward Total]
	FROM
	(
    SELECT b.BrandID
		, b.BrandName
		, a.AcquirerName AS Acquirer
		, r.AnnualSpend AS AnnualSpend
	FROM MI.RetailerTrackingAcquirer r
	INNER JOIN Relational.ConsumerCombination c ON r.ConsumerCombinationID = c.ConsumerCombinationID
	INNER JOIN Relational.Acquirer a ON r.AcquirerID = a.AcquirerID
	INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID
	WHERE c.MID != ''
	) s
	PIVOT
	(
		SUM(AnnualSpend)
		FOR Acquirer IN ([Barclaycard Business], [Cardnet], [Chase], [Elavon], [Foreign], [Global Payments], [HBOS], [Unknown], [WorldPay], [WorldPay Reward])
	) P
	ORDER BY [Grand Total] DESC
END
