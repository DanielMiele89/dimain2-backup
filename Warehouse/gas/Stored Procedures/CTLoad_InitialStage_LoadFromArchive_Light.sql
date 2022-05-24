CREATE PROCEDURE [gas].[CTLoad_InitialStage_LoadFromArchive_Light]

 @FileID INT

AS

INSERT INTO Staging.CTLoad_InitialStage WITH (TABLOCK)
	(FileID, RowNum, BankIDString, 
	MID, Narrative, LocationAddress, LocationCountry, 
	MCC, CardholderPresentData, TranDate, PaymentCardID, 
	Amount, OriginatorID, PostStatus, CardInputMode, PaymentTypeID)
SELECT FileID
	, RowNum
	, BankID
	, CAST(MerchantID AS VARCHAR(50)) AS MID
	, CAST(LocationName AS VARCHAR(22)) AS Narrative
	, CAST(LocationAddress AS VARCHAR(18)) AS LocationAddress
	, CAST(LocationCountry AS VARCHAR(3)) AS LocationCountry
	, MCC
	, CardholderPresentData
	, TranDate
	, PaymentCardID
	, Amount
	, OriginatorID
	, PostStatus
	, CardInputMode
	, CAST(1 AS TINYINT) AS PaymentTypeID
FROM Archive_Light.dbo.NobleTransactionHistory_MIDI nth WITH (NOLOCK)
WHERE FileID = @FileID
AND NOT EXISTS (	SELECT 1
		FROM Warehouse.Staging.CTLoad_InitialStage ct
		WHERE nth.FileID = ct.FileID
		AND nth.RowNum = ct.RowNum)

RETURN 0