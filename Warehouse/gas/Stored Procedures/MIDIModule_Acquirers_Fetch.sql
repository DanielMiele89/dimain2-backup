-- =============================================
-- Author:		JEA
-- Create date: 11/09/2014
-- Description:	Retrieves a list of OriginatorIDs and Acquirers for a specified brand
-- =============================================
CREATE PROCEDURE gas.MIDIModule_Acquirers_Fetch
	(
		@BrandID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT OriginatorID, Acquirer, COUNT(1) AS Frequency
	FROM
	(
		SELECT c.OriginatorID, CASE WHEN c.LocationCountry != 'GB' THEN 'Foreign' ELSE a.AcquirerName END AS Acquirer
		FROM (SELECT ConsumerCombinationID, OriginatorID, LocationCountry
				FROM Relational.ConsumerCombination
				WHERE BrandID = @BrandID) c
		LEFT OUTER JOIN (SELECT ca.ConsumerCombinationID, a.AcquirerName
							FROM MI.MOMCombinationAcquirer ca
							INNER JOIN Relational.Acquirer a ON ca.AcquirerID = a.AcquirerID
							WHERE ca.BrandID = @BrandID) a ON c.ConsumerCombinationID = a.ConsumerCombinationID
		WHERE a.ConsumerCombinationID IS NOT NULL OR c.LocationCountry != 'GB'
	) a
	GROUP BY OriginatorID, Acquirer
	ORDER BY Frequency DESC

END