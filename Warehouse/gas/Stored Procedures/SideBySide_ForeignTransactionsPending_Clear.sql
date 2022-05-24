-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Removes foreign transactions from the pending table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ForeignTransactionsPending_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DELETE FROM Staging.ConsumerTransactionPending
	WHERE BrandMIDID = 147179

END