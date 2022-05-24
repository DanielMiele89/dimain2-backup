-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.PostCode_LocationMatches_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT bm.ConsumerCombinationID, bm.BrandID, MIN(ccd.MerchantZIP) AS PostCode
	FROM AWSFile.PostCode_NewLocations_SecondStage ccd
	INNER JOIN Relational.ConsumerCombination bm
	ON ccd.MerchantID=bm.MID
		AND  '%' + MerchantDBAName +'%' LIKE '%'+narrative+'%' 
	WHERE bm.LocationCountry='GB' 
		AND  bm.Narrative NOT LIKE '%CRV%' 
		AND bm.Narrative NOT LIKE '%CURVE%' 
		AND bm.Narrative<>'IZ *'
	GROUP BY bm.ConsumerCombinationID, bm.BrandID

END
