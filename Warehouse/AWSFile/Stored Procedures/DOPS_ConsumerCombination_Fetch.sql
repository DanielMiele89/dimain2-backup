-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	Retrieves ConsumerCombination information for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_ConsumerCombination_Fetch] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	SELECT cc.ConsumerCombinationID
		, cc.BrandID
		, cc.LocationCountry
		, cc.MCCID
		, cc.IsUKSpend
		, ISNULL(p.PostCode, '') AS PostCode
		, ISNULL(p.LocationID,0) AS LocationID
		, ISNULL(al.PostCode, '') AS AlternatePostCode
		, ISNULL(a.AlternateLocationID,0) AS AlternateLocationID
		, CC.MID
		, CC.Narrative
	FROM Relational.ConsumerCombination cc
	LEFT OUTER JOIN AWSFile.ComboPostcode p ON cc.ConsumerCombinationID = p.ConsumerCombinationID
	LEFT OUTER JOIN AWSFile.ConsumerCombination_AlternateLocation a ON cc.ConsumerCombinationID = a.ConsumerCombinationID
	LEFT OUTER JOIN AWSFile.AlternateLocation al ON a.AlternateLocationID = al.ID
    
END
