-- =============================================
-- Author:		JEA
-- Create date: 21/02/2013
-- Description:	Load latest brand/acquirer information
-- into the BrandAcquirer table from the latest MID Origin Match
-- =============================================
CREATE PROCEDURE [Staging].[BrandAcquirer_Persist]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MOMRun INT
	
	SELECT @MOMRun = MAX(MOMRunID) FROM Staging.MOMRun

	INSERT INTO Staging.BrandAcquirer(MOMRun, BrandID, AcquirerID, BrandMIDCount)
	SELECT @MOMRun, BrandID, AcquirerID, COUNT(1) AS BrandMIDCount
	FROM Staging.MIDOriginMatch
	GROUP BY BrandID, AcquirerID
	
	IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Staging_MIDOriginMatch_BrandID')
	BEGIN
		CREATE NONCLUSTERED INDEX IX_Staging_MIDOriginMatch_BrandID
		ON [Staging].[MIDOriginMatch] ([BrandID])
		INCLUDE ([BrandMIDID],[LastTranDate],[MID],[Narrative],[LocationAddress],[OriginatorID],[MCC],[AcquirerID])
	END
    
END
