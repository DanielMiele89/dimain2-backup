-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Counts total number of transactions without a CIN in this file
-- =============================================
CREATE PROCEDURE gas.QA_NoCINCount_Fetch
	(
		@FileID int
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT COUNT(1)
	FROM Staging.CardTransactionHolding
	WHERE CINID IS NULL
	
END