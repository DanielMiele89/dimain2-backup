-- =============================================
-- Author:		JEA
-- Create date: 13/12/2013
-- Description:	Clears consumer transaction staging area
-- =============================================
CREATE PROCEDURE Staging.ConsumerTransactionStage_Clear 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.ConsumerTransactionStage;

END