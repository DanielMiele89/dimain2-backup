-- =============================================
-- Author:		JEA
-- Create date: 11/09/2014
-- Description:	Retrieves a list of MIDs for a specified brand
-- =============================================
CREATE PROCEDURE gas.MIDIModule_BrandNarratives_Fetch
	(
		@BrandID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT Narrative
	FROM Relational.ConsumerCombination
	WHERE BrandID = @BrandID
	ORDER BY Narrative

END
