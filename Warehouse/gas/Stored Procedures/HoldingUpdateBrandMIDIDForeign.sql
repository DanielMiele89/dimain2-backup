-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets BrandMIDIDs for foreign combination matches
-- in the holding area
-- =============================================
CREATE PROCEDURE [gas].[HoldingUpdateBrandMIDIDForeign]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE Staging.CardTransactionHolding 
	SET BrandMIDID = 147179
	FROM Staging.CardTransactionHolding CTH
	LEFT OUTER JOIN -- EXCLUDE NAMED EXCEPTIONS
		(SELECT DISTINCT bm.Narrative
		FROM Relational.Brand b
		INNER JOIN Staging.BrandMatch bm ON b.brandid = bm.brandid
		WHERE b.IsNamedException = 1) b ON CTH.Narrative LIKE b.Narrative
	WHERE CTH.LocationCountry != 'GB'
	AND B.Narrative IS NULL
	AND CTH.BrandMIDID IS NULL
	
END