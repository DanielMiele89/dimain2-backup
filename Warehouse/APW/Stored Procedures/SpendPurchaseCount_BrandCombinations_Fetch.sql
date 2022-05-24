-- =============================================
-- Author:		JEA
-- Create date: 29/06/2016
-- Description:	Retrieves combinations for selected brand
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_BrandCombinations_Fetch]
	(
		@BrandID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE BrandID = @BrandID

END