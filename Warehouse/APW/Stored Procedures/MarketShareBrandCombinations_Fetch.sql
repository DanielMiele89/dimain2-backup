-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Retrieves own and competitor combinations for selected brand
-- =============================================
CREATE PROCEDURE APW.MarketShareBrandCombinations_Fetch
	(
		@BrandID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ConsumerCombinationID, CAST(1 AS BIT) AS IsRetailer
	FROM Relational.ConsumerCombination
	WHERE BrandID = @BrandID
	AND IsUKSpend = 1

	UNION ALL

	SELECT c.ConsumerCombinationID, CAST(0 AS BIT) AS IsRetailer
	FROM Relational.ConsumerCombination c
	LEFT OUTER JOIN Relational.BrandCompetitor bc ON c. BrandID = bc.CompetitorID
	WHERE bc.BrandID = @BrandID
	AND c.IsUKSpend = 1

END