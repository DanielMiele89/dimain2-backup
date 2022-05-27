-- =============================================
-- Author:		JEA
-- Create date: 16/02/2016
-- Description:	Refreshes MI.RewardPartnerBrand
-- which is used for the retailer tracking report
-- =============================================
CREATE PROCEDURE [MI].[RewardPartnerBrand_Refresh] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RewardPartnerBrand
	TRUNCATE TABLE MI.RetailerTrackingAcquirer

	INSERT INTO MI.RewardPartnerBrand(BrandID)
	SELECT BrandID FROM Relational.Brand
	--SELECT DISTINCT BrandID
	--FROM MI.TotalBrandSpend
	--WHERE SpendThisYear >= 1000000

	--UNION
	
	--SELECT BrandID 
	--FROM Relational.[Partner]
	--WHERE BrandID IS NOT NULL

	--UNION

	--SELECT BrandID
	--FROM InsightArchive.nFIpartnerdeals
	--WHERE BrandID IS NOT NULL

END
