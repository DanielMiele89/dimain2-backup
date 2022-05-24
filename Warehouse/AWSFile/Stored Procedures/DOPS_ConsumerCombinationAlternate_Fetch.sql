-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	Retrieves ConsumerCombination information for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_ConsumerCombinationAlternate_Fetch] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;
	SELECT
		*
		, UPPER(AlternatePostCode) FinalPostCode
		, CONCAT('MID'
			, LTRIM(RTRIM(MID))
			, LTRIM(RTRIM(Narrative))
			, CASE WHEN LEN(UPPER(AlternatePostCode)) > 2 THEN SUBSTRING(UPPER(AlternatePostCode), 0, LEN(UPPER(AlternatePostCode)) - 2) END
		) AS ComboID
	FROM (

		SELECT cc.ConsumerCombinationID
			, cc.BrandID
			, cc.LocationCountry
			, cc.MCCID
			, cc.IsUKSpend
			,  dbo.fn_StripCharacters(ISNULL(p.PostCode, ''), '^a-zA-Z0-9 ') AS PostCode
			, ISNULL(p.LocationID,0) AS LocationID
			,  dbo.fn_StripCharacters(ISNULL(al.PostCode, ''), '^a-zA-Z0-9 ') AS AlternatePostCode
			, ISNULL(a.AlternateLocationID,0) AS AlternateLocationID
			,  dbo.fn_StripCharacters(CC.MID, '^a-zA-Z0-9 ') AS MID
			,  dbo.fn_StripCharacters(CC.Narrative, '^a-zA-Z0-9 ') AS Narrative
		FROM Relational.ConsumerCombination cc
		LEFT OUTER JOIN AWSFile.ComboPostcode p ON cc.ConsumerCombinationID = p.ConsumerCombinationID
		LEFT OUTER JOIN AWSFile.ConsumerCombination_AlternateLocation a ON cc.ConsumerCombinationID = a.ConsumerCombinationID
		LEFT OUTER JOIN AWSFile.AlternateLocation al ON a.AlternateLocationID = al.ID
	) x
    
END