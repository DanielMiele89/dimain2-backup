-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.AlternateLocationList_Refresh

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	INSERT INTO AWSFile.AlternateLocation(BrandID, PostCode, LocationFormat, LocationCategory)
	
	SELECT DISTINCT c.BrandID, f.Postcode, f.[Format] AS LocationFormat, f.Category AS LocationCategory
	FROM Staging.AlternateLocation_File f
	INNER JOIN Staging.AlternateLocation_ConsumerCombination c on f.MIDNumeric = c.MIDNumeric and f.Narrative = c.Narrative

	EXCEPT

	SELECT BrandID, PostCode, LocationFormat, LocationCategory
	FROM AWSFile.AlternateLocation

END
