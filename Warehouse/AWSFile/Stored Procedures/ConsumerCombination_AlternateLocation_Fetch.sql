-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.ConsumerCombination_AlternateLocation_Fetch

AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.ConsumerCombinationID, MIN(a.ID) AS LocationID
	FROM Staging.AlternateLocation_File f
	INNER JOIN Staging.AlternateLocation_ConsumerCombination c on f.MIDNumeric = c.MIDNumeric and f.Narrative = c.Narrative
	INNER JOIN AWSFile.AlternateLocation a ON c.BrandID = a.BrandID
		AND f.Postcode = a.PostCode
		AND f.[Format] = a.LocationFormat
		AND f.Category = a.LocationCategory
	GROUP BY c.ConsumerCombinationID

END