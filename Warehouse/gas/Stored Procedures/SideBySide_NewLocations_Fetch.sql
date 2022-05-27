-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	fetches new locations
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_NewLocations_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT BrandCombinationID AS ConsumerCombinationID
		, LocationAddress
		, CAST(0 AS BIT) AS IsNonLocational
	FROM  Staging.ConsumerTransactionLocationMissing
	WHERE LocationID IS NULL

END
