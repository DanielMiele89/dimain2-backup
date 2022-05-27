-- =============================================
-- Author:		JEA
-- Create date: 07/03/2013
-- Description:	Performs Clean-up operations
-- following the MIDI process
-- =============================================
CREATE PROCEDURE [gas].[MIDICleanUp]
WITH EXECUTE AS OWNER
AS	
BEGIN
	
	SET NOCOUNT ON;

	ALTER INDEX IX_CardTransaction_CINID ON Relational.CardTransaction REBUILD WITH (ONLINE=ON)
	ALTER INDEX IX_BrandMID_BrandID ON Relational.BrandMID REBUILD
	ALTER INDEX IX_BrandMID_MID ON Relational.BrandMID REBUILD
	
	UPDATE STATISTICS Relational.CardTransaction
	UPDATE STATISTICS Relational.BrandMID
    
END
