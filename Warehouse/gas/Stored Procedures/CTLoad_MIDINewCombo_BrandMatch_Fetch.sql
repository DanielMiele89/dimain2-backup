-- =============================================
-- Author:		JEA
-- Create date: 03/07/2014
-- Description:	Retrieves brand matches for new combos
-- =============================================
CREATE PROCEDURE gas.CTLoad_MIDINewCombo_BrandMatch_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT c.ID AS ComboID, bm.BrandMatchID, bm.BrandID, b.BrandGroupID
	FROM Staging.CTLoad_MIDINewCombo c
	INNER JOIN Staging.BrandMatch bm ON c.Narrative like bm.Narrative
	INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID

END