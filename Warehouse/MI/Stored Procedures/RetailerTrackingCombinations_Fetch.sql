-- =============================================
-- Author:		JEA
-- Create date: 18/02/2015
-- Description:	Fetches combinations to determine 
-- if a retailer is trackable by Reward
-- =============================================
CREATE PROCEDURE MI.RetailerTrackingCombinations_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.ConsumerCombinationID
		, c.BrandID
		, c.MID
		, a.AcquirerID
		, mom.AcquirerID AS AcquirerOverrideID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.RewardPartnerBrand b ON c.BrandID = b.BrandID
	INNER JOIN MI.MOMCombinationAcquirer a ON c.ConsumerCombinationID = a.ConsumerCombinationID
	LEFT OUTER JOIN MI.RetailerTrackingBrandAcquirerOverride mom ON c.BrandID = mom.BrandID
	WHERE c.LocationCountry = 'GB'

END