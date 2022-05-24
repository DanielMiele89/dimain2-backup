-- =============================================
-- Author:		JEA
-- Create date: 28/05/2014
-- Description:	Retrieves information for MOM acquirer classification
-- =============================================
CREATE PROCEDURE [MI].[MOMBaseInfo_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT m.ConsumerCombinationID, c.BrandID, c.MID, c.Narrative, m.LastTranDate, c.OriginatorID, loc.LocationAddress, c.mccid
	FROM MI.MOMCombinationLastTrans m
	INNER JOIN Relational.ConsumerCombination c ON m.ConsumerCombinationID = c.ConsumeRCombinationID
	INNER JOIN (SELECT m.ConsumerCombinationID, MAX(LocationID) AS LocationID 
				FROM Relational.Location l
				INNER JOIN MI.MOMCombinationLastTrans m ON L.ConsumerCombinationID = M.ConsumerCombinationID
				GROUP BY m.ConsumerCombinationID) l ON c.ConsumerCombinationID = l.ConsumerCombinationID
	INNER JOIN Relational.Location loc ON l.locationID = loc.locationID

END
