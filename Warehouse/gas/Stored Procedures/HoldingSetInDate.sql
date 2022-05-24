-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Deletes early transactions and sets the InDate
-- on transactions in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingSetInDate
	
	(
		@InDate SmallDateTime
	)
	
AS
BEGIN

	SET NOCOUNT ON;

    DELETE FROM Staging.CardTransactionHolding
	WHERE TranDate < '2010-01-01'

	UPDATE Staging.CardTransactionHolding SET InDate = @InDate
	
END