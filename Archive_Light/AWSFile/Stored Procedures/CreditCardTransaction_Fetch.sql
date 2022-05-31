-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[CreditCardTransaction_Fetch] 
	(
		@FileID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT c.FileID, c.RowNum, TransactionReferenceNumber, MerchantDBACountry, MerchantID, MerchantDBAName
		, MerchantSICClassCode, MerchantZip, CIN, CardholderPresentMC, Amount, TranDate AS TranDateString, FanID--, IsValidTransaction
	FROM dbo.CBP_Credit_TransactionHistory c
	WHERE IsValidTransaction = 1
	AND FileID > @FileID --retrieve all transactions with fileid greater than the max already processed
	AND (CIN != '' OR FanID IS NOT NULL)

END
