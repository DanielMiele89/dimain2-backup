-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Retrieves the transactions requiring processing
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_TransactionsToProcess_Fetch]
	(
		@FileID Int
	)
AS
BEGIN

	SET NOCOUNT ON;

	--SELECT FileID
	--	, RowNum
	--	, CAST(ClientProductCode AS VARCHAR(4)) AS BankID
	--	, CAST(MerchantAccountNumber AS NVARCHAR(50)) AS varMID -- CHANGE TO MERCHANTID
	--	, CAST(LEFT(MerchantDBAName,22) AS NVARCHAR(22)) AS varNarrative
	--	, CAST(MerchantDBACity + ' ' + MerchantDBAState AS NVARCHAR(18)) AS varLocationAddress
	--	, CAST(MerchantDBACountry AS NVARCHAR(3)) AS varLocationCountry
	--	, CAST(MerchantSICClassCode AS VARCHAR(4)) AS MCC
	--	, CardholderPresentData
	--	, TranDate AS varTranDate
	--	, PaymentCardID
	--	, Amount
	--	, CAST('' AS VARCHAR(11)) AS OriginatorID
	--	, CAST('O' AS CHAR(1)) AS PostStatus
	--	, CAST(RIGHT(TerminalEntry,1) AS CHAR(1)) AS CardInputMode  --FIXME!!!
	--	, CAST(2 AS TINYINT) AS PaymentTypeID
	--FROM Archive.dbo.CBP_Credit_TransactionHistory WITH (NOLOCK)
	--WHERE FileID = @FileID
	--AND RTRIM(LTRIM(LEFT(MerchantDBAName,22))) != ''
	--AND IsValidTransaction = 1
	--UNION ALL
	SELECT FileID
		, RowNum
		, BankID
		, MerchantID AS varMID
		, LocationName AS varNarrative
		, LocationAddress AS varLocationAddress
		, LocationCountry AS varLocationCountry
		, MCC
		, CardholderPresentData
		, TranDate AS varTranDate
		, PaymentCardID
		, Amount
		, OriginatorID
		, PostStatus
		, CardInputMode
		, CAST(1 AS TINYINT) AS PaymentTypeID
	FROM Archive.dbo.NobleTransactionHistory WITH (NOLOCK)
	WHERE FileID = @FileID
	
END
