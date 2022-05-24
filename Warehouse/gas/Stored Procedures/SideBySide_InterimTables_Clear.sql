-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Clears all working tables at the end of the load
-- =============================================
CREATE PROCEDURE gas.SideBySide_InterimTables_Clear 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.ConsumerTransactionPending
	TRUNCATE TABLE Staging.ConsumerTransactionWorking
	TRUNCATE TABLE Staging.ConsumerTransactionLocationMissing
	TRUNCATE TABLE Staging.ConsumerTransactionPaypalSecondary
	TRUNCATE TABLE Staging.ConsumerCombinationReview

END