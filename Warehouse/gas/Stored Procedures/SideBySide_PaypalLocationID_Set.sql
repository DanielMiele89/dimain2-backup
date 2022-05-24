-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Sets location IDs in the paypal working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_PaypalLocationID_Set]
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.ConsumerTransactionPaypalSecondary
	SET LocationID = l.LocationID
	FROM Staging.ConsumerTransactionPaypalSecondary w
	INNER JOIN Relational.Location l ON w.BrandCombinationID = l.ConsumerCombinationID
		AND w.LocationAddress = l.LocationAddress
	WHERE L.IsNonLocational = 0

	UPDATE Staging.ConsumerTransactionPaypalSecondary
	SET LocationID = l.LocationID
	FROM Staging.ConsumerTransactionPaypalSecondary w
	INNER JOIN Relational.Location l ON w.BrandCombinationID = l.ConsumerCombinationID
	WHERE L.IsNonLocational = 1


END