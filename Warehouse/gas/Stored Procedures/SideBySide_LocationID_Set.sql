-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Sets location IDs in the working table
-- =============================================
CREATE PROCEDURE gas.SideBySide_LocationID_Set
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.ConsumerTransactionWorking
	SET LocationID = l.LocationID
	FROM Staging.ConsumerTransactionWorking w
	INNER JOIN Relational.Location l ON w.BrandCombinationID = l.ConsumerCombinationID
		AND w.LocationAddress = l.LocationAddress
	WHERE L.IsNonLocational = 0

	UPDATE Staging.ConsumerTransactionWorking
	SET LocationID = l.LocationID
	FROM Staging.ConsumerTransactionWorking w
	INNER JOIN Relational.Location l ON w.BrandCombinationID = l.ConsumerCombinationID
	WHERE L.IsNonLocational = 1


END
