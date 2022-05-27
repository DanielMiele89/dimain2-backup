-- =============================================
-- Author:		JEA
-- Create date: 01/02/2013
-- Description:	Monitors partner MIDs with new
-- combinations being received
-- =============================================
CREATE PROCEDURE gas.MIDWatchListCombos 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT B.BrandName, B.MID, c.Narrative, C.Inserted
	FROM Staging.Combination c
	INNER JOIN
	(
		SELECT co.BrandMIDID, CO.MID, B.BrandName, COUNT(DISTINCT co.Narrative) as NarrativeCount
		FROM Staging.Combination co
		INNER JOIN Relational.Outlet o on co.MID = o.MerchantID
		INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
		INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
		INNER JOIN (SELECT CombinationID
						FROM Staging.Combination
						WHERE Inserted > DATEADD(year, -1, getdate())
						AND Inserted > '2012-10-01') i on co.CombinationID = i.CombinationID --HARDCODED START OF MID COLLECTION
		WHERE O.MerchantID != ''
		GROUP BY co.BrandMIDID, CO.MID, B.BrandName
		HAVING COUNT(DISTINCT co.Narrative) > 1
	) B ON C.BrandMIDID = B.BrandMIDID
	ORDER BY B.BrandName, B.MID, c.Narrative, C.Inserted
	
	
END

GO
GRANT EXECUTE
    ON OBJECT::[gas].[MIDWatchListCombos] TO [DB5\reportinguser]
    AS [dbo];

