-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Description:	Load latest brand/acquirer information
-- into the BrandAcquirer table from the latest MID Origin Match
-- =============================================
CREATE PROCEDURE [MI].[MOMBrandAcquirer_Persist]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	INSERT INTO MI.MOMBrandAcquirerCount(BrandID, AcquirerID, CombinationCount)
	SELECT m.BrandID, m.AcquirerID, COUNT(1) AS BrandMIDCount
	FROM MI.MOMCombinationAcquirer m
	GROUP BY BrandID, AcquirerID
	ORDER BY BrandID, AcquirerID
    
END