-- =============================================
-- Author:		JEA
-- Create date: 20/03/2014
-- Description:	Refreshes the consumersector table
-- =============================================
CREATE PROCEDURE Staging.ConsumerSector_Rebuild 
	
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_Relational_ConsumerSector_BrandSector ON Relational.ConsumerSector DISABLE

	INSERT INTO Relational.ConsumerSector(ConsumerCombinationID, BrandID, SectorID)
	SELECT C.ConsumerCombinationID, B.BrandID, B.SectorID
	FROM Relational.ConsumerCombination c
		JOIN Relational.Brand B ON C.BrandID = B.BrandID
	WHERE C.BrandID != 944

	INSERT INTO Relational.ConsumerSector(ConsumerCombinationID, BrandID, SectorID)
	SELECT C.ConsumerCombinationID, 944, m.SectorID
	FROM Relational.ConsumerCombination c
		JOIN Relational.MCCList m ON C.MCCID = M.MCCID
	WHERE C.BrandID = 944
		AND C.IsUKSpend = 1

	ALTER INDEX IX_Relational_ConsumerSector_BrandSector ON Relational.ConsumerSector REBUILD

END
