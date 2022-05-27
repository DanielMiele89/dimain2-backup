-- =============================================
-- Author:		JEA
-- Create date: 14/08/2013
-- Description:	Assesses Tesco MIDs reported as missing for incentivisation
-- =============================================
CREATE PROCEDURE [MI].[TescoMIDCheck_Fetch]

AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #BrandMIDs(BrandMIDID int not null)

	INSERT INTO #BrandMIDs(BrandMIDID) --populate the temp table with all BrandMIDIDs associated with the MIDs marked for checking
	SELECT bm.BrandMIDID
	FROM Relational.BrandMID bm
	INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID
	INNER JOIN MI.TescoMIDCheck t ON bm.MID = t.MID
	WHERE t.ResolveDate IS NULL  --MIDs are marked as resolved when a decision is made regarding a particular case.

	ALTER TABLE #BrandMIDs ADD PRIMARY KEY(BrandMIDID)

	SELECT T.MID, t.DateEntered, br.BrandID, br.BrandName, b.BrandMIDID, b.Narrative, c.CardholderPresentData, c.MCC, M.MCCDesc, C.FirstTranDate, C.LastTranDate, C.Frequency
	FROM
	(
		SELECT B.BrandMIDID, c.MCC, c.CardholderPresentData, min(c.TranDate) AS FirstTranDate, max(c.TranDate) AS LastTranDate, COUNT(1) AS Frequency
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN #BrandMIDs b on C.BrandMIDID = b.BrandMIDID
		GROUP BY b.BrandMIDID, c.MCC, c.CardholderPresentData
	) c
	INNER JOIN Relational.BrandMID b ON c.BrandMIDID = b.BrandMIDID
	INNER JOIN Relational.MCCList m on C.MCC = M.MCC
	INNER JOIN Relational.Brand br ON B.BrandID = br.BrandID
	RIGHT OUTER JOIN (SELECT MID, DateEntered FROM MI.TescoMIDCheck WHERE ResolveDate IS NULL) t ON b.MID = T.MID -- all MIDs to check will show whether or not we have received data
	ORDER BY MID, MCC, CardholderPresentData

	DROP TABLE #BrandMIDs

END
