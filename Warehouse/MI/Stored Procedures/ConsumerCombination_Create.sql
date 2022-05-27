-- =============================================
-- Author:		JEA
-- Create date: 13/12/2013
-- Description:	Creates combinations that are found in the data stream but do not exist yet
-- =============================================
CREATE PROCEDURE MI.ConsumerCombination_Create 
	(
		@BrandMIDID INT
		, @MCCID SMALLINT
		, @OriginatorID VARCHAR(11)
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	INSERT INTO Relational.ConsumerCombination(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance)
	SELECT BrandMIDID, BrandID, MID, Narrative, Country, @MCCID, @OriginatorID, IsHighVariance
	FROM Relational.BrandMID
	WHERE BrandMIDID = @BrandMIDID

END
