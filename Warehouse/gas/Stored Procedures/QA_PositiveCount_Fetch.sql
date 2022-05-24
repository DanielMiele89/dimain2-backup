-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Counts total number of matched transactions with positive values
-- =============================================
CREATE PROCEDURE [gas].[QA_PositiveCount_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT COUNT(1)
	FROM Staging.CardTransactionHolding
	WHERE Amount > 0
	
END