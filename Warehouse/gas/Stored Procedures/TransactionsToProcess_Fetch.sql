-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Retrieves the transactions requiring processing
-- =============================================
CREATE PROCEDURE [gas].[TransactionsToProcess_Fetch]
	(
		@FileID Int
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID, RowNum, BankID, MerchantID AS varMID, LocationName AS varNarrative, LocationAddress AS varLocationAddress
    , LocationCountry AS varLocationCountry, MCC, CardholderPresentData, TranDate, PaymentCardID, Amount, OriginatorID, PostStatus
	FROM Archive.dbo.NobleTransactionHistory WITH (NOLOCK)
	WHERE FileID = @FileID
	
END
