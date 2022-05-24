-- =============================================
-- Author:		JEA
-- Create date: 13/12/2013
-- Description:	Creates locations that are found in the data stream but do not exist yet
CREATE PROCEDURE MI.Location_Create 
	(
		@ConsumerCombinationID INT
		, @LocationAddress VARCHAR(50)
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    INSERT INTO Relational.Location(LocationAddress, ConsumerCombinationID, IsHighVariance)
	VALUES(@LocationAddress, @ConsumerCombinationID, 0)

END