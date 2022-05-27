-- =============================================
-- Author:		JEA
-- Create date: 11/09/2014
-- Description:	Retrieves summary brand information for MIDI module
-- =============================================
CREATE PROCEDURE gas.MIDIModule_BrandHeadlineInfo_Fetch
	(
		@BrandID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT BrandID, BrandName, IsHighRisk, bs.SectorName
	FROM Relational.Brand b
	INNER JOIN Relational.BrandSector bs ON b.SectorID = bs.SectorID
	WHERE BrandID = @BrandID

END
