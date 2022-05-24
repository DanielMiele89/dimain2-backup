-- =============================================
-- Author:		JEA
-- Create date: 11/09/2014
-- Description:	Retrieves a list of MIDs for a specified brand
-- =============================================
CREATE PROCEDURE gas.MIDIModule_MCCs_Fetch
	(
		@BrandID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT m.MCC, m.MCCDesc, COUNT(1) AS MCCFrequency
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.MCCList m ON c.MCCID = m.MCCID
	WHERE BrandID = @BrandID
	GROUP BY m.MCC, m.MCCDesc
	ORDER BY MCCFrequency DESC

END