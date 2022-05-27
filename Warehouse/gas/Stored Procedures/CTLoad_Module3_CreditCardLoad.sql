/*
Grab new rows from Archive_Light.dbo.CBP_Credit_TransactionHistory into reditCardLoad_InitialStage
Tag extra variables

Set non-paypal combinations
Set Paypal Combinations
New rows into Relational.ConsumerCombination

Distribute Transactions creditcardload_initialstage into relational.consumertransaction_creditcardholding
Unmatched rows go into staging.CreditCardLoad_MIDIHolding and staging.CreditCardLoad_MIDIHolding

Clear down Staging.CreditCardLoad_InitialStage

*/
CREATE PROCEDURE [gas].[CTLoad_Module3_CreditCardLoad] 

AS

SET NOCOUNT ON


------------------------------------------------------------------------------------------------------------------- 
-- Set CCFileID Variable
-- EXEC Staging.CreditCardLoad_MaxFileIDProcessed_Fetch
------------------------------------------------------------------------------------------------------------------- 
DECLARE @FileID INT
SELECT @FileID = MAX(FileID) FROM staging.CreditCardLoad_LastFileProcessed



------------------------------------------------------------------------------------------------------------------- 
-- Load CreditCardLoad_InitialStage Dataflow task
-- EXEC Archive_light.AWSFile.CreditCardTransaction_Fetch 0
------------------------------------------------------------------------------------------------------------------- 
INSERT INTO [Staging].[CreditCardLoad_InitialStage] (
	c.FileID, c.RowNum, 
	--TransactionReferenceNumber, MerchantDBACountry, MerchantID, MerchantDBAName, MerchantSICClassCode, MerchantZip, 
	CIN, CardholderPresentMC, Amount, TranDate, FanID
)
SELECT c.FileID, c.RowNum, 
	--TransactionReferenceNumber, MerchantDBACountry, MerchantID, MerchantDBAName, MerchantSICClassCode, MerchantZip, 
	CIN, CardholderPresentMC, Amount, TranDate AS TranDateString, FanID--, IsValidTransaction
FROM Archive_Light.dbo.CBP_Credit_TransactionHistory c
WHERE IsValidTransaction = 1
	AND FileID > @FileID --retrieve all transactions with fileid greater than the max already processed
	AND (CIN != '' OR FanID IS NOT NULL)



------------------------------------------------------------------------------------------------------------------- 
-- Update Staging Fields CC
-- EXEC Staging.CreditCardLoad_ColumnValues_Set
-------------------------------------------------------------------------------------------------------------------- 
UPDATE Staging.CreditCardLoad_InitialStage
SET CardholderPresentMC = '9'
WHERE CardholderPresentMC = ''

UPDATE i SET CIN = c.SourceUID
FROM Staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.Customer c ON i.FanID = c.FanID
WHERE CIN = ''


SELECT DISTINCT i.CIN
INTO #NewCINs
FROM Staging.CreditCardLoad_InitialStage i
LEFT OUTER JOIN Relational.CINList c ON i.CIN = c.CIN
WHERE c.CIN IS NULL

INSERT INTO Relational.CINList(CIN)
SELECT CIN
FROM #NewCINs

UPDATE i SET CINID = c.CINID
FROM staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.CINList c ON i.CIN = c.CIN


SELECT DISTINCT i.LocationCountry, i.PostCode
INTO #NewPostCodes
FROM staging.CreditCardLoad_InitialStage i
LEFT OUTER JOIN Relational.CreditCardPostCode p 
	ON i.LocationCountry = p.LocationCountry AND i.PostCode = p.PostCode
WHERE P.LocationID IS NULL

INSERT INTO Relational.CreditCardPostCode (LocationCountry, PostCode)
SELECT LocationCountry, PostCode
FROM #NewPostCodes

UPDATE i SET LocationID = p.LocationID
FROM staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.CreditCardPostCode p ON i.LocationCountry = p.LocationCountry and i.PostCode = p.PostCode


SELECT DISTINCT i.MCC
INTO #NewMCCs
FROM staging.CreditCardLoad_InitialStage i
LEFT OUTER JOIN Relational.MCCList m ON i.MCC = M.MCC
WHERE m.MCC IS NULL

INSERT INTO Relational.MCCList(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
SELECT MCC, '', '', '', 1
FROM #NewMCCs

UPDATE i SET MCCID = m.MCCID
FROM staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.MCCList m ON i.MCC = m.MCC


UPDATE staging.CreditCardLoad_InitialStage
SET MID = LTRIM(RTRIM(MID))
	, Narrative = LTRIM(RTRIM(Narrative))
	, LocationCountry = LTRIM(RTRIM(LocationCountry))

UPDATE staging.CreditCardLoad_InitialStage
SET Narrative = REPLACE(narrative, '"', '')



------------------------------------------------------------------------------------------------------------------- 
-- Set non-paypal combinations CC
-- EXEC Staging.CreditCardLoad_CombinationsNonPaypal_Set
------------------------------------------------------------------------------------------------------------------- 
UPDATE i
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.ConsumerCombination c ON
	i.MID = c.MID
	AND i.Narrative = c.Narrative
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorReference = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 0
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal

UPDATE i
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage i
INNER JOIN Relational.ConsumerCombination c ON
	i.MID = c.MID
	AND i.Narrative LIKE c.Narrative
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorReference = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND c.IsHighVariance = 1
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal



------------------------------------------------------------------------------------------------------------------- 
-- Set Paypal Combinations CC
-- EXEC Staging.CreditCardLoad_CombinationsPaypal_Set
------------------------------------------------------------------------------------------------------------------- 
	CREATE TABLE #PaypalCombosNonDefault(ConsumerCombinationID INT PRIMARY KEY
		, LocationCountry VARCHAR(3) NOT NULL
		, MCCID SMALLINT NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL)

	CREATE TABLE #PaypalMIDNew(MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)

	INSERT INTO #PaypalCombosNonDefault(ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
	SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
	FROM Relational.ConsumerCombination
	WHERE PaymentGatewayStatusID = 1

	CREATE INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault(LocationCountry, MCCID, OriginatorID)

	INSERT INTO #PaypalMIDNew(MID, TranCount)
	SELECT MID, COUNT(*)
	FROM Staging.CTLoad_InitialStage
	WHERE Narrative LIKE 'PAYPAL%'
	AND ConsumerCombinationID IS NULL
	GROUP BY MID
	HAVING COUNT(*) >= 10

	UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN #PaypalCombosNonDefault c ON
		i.Narrative LIKE 'PAYPAL%'
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
	LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
	WHERE i.ConsumerCombinationID IS NULL
	AND pn.MID IS NULL

	DECLARE @ComboRequiredCount INT

	SELECT @ComboRequiredCount = COUNT(1)
	FROM Staging.CreditCardLoad_InitialStage i
	LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
	WHERE ConsumerCombinationID IS NULL
	AND Narrative LIKE 'PAYPAL%'
	AND pn.MID IS NULL

	IF @ComboRequiredCount > 0 BEGIN

		--EXEC gas.CTLoad_ConsumerCombinationIndexes_Disable -- ###
		ALTER INDEX [ix_BrandID] ON Relational.ConsumerCombination DISABLE
		ALTER INDEX [ix_MID] ON Relational.ConsumerCombination DISABLE
		ALTER INDEX IX_NCL_ConsumerCombination_MIDLocMCC ON Relational.ConsumerCombination DISABLE
		ALTER INDEX IX_NCL_ConsumerCombination_PaymentGateway ON Relational.ConsumerCombination DISABLE
		ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination DISABLE
		ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination DISABLE	
		
		INSERT INTO Relational.ConsumerCombination (BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
		SELECT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorReference, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
		FROM Staging.CreditCardLoad_InitialStage i
		LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
		WHERE ConsumerCombinationID IS NULL
			AND Narrative LIKE 'PAYPAL%'
			AND pn.MID IS NULL
		
		--EXEC gas.CTLoad_ConsumerCombinationIndexes_Rebuild -- ###
		ALTER INDEX [ix_BrandID] ON Relational.ConsumerCombination REBUILD
		ALTER INDEX [ix_MID] ON Relational.ConsumerCombination REBUILD
		ALTER INDEX IX_NCL_ConsumerCombination_MIDLocMCC ON Relational.ConsumerCombination REBUILD
		ALTER INDEX IX_NCL_ConsumerCombination_PaymentGateway ON Relational.ConsumerCombination REBUILD
		ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination REBUILD
		ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination REBUILD	


		UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
			, RequiresSecondaryID = 1
		FROM Staging.CreditCardLoad_InitialStage i
		INNER JOIN #PaypalCombosNonDefault c ON
			i.Narrative LIKE 'PAYPAL%'
			AND i.LocationCountry = c.LocationCountry
			AND i.MCCID = c.MCCID
			AND i.OriginatorReference = c.OriginatorID
		LEFT OUTER JOIN #PaypalMIDNew pn ON i.MID = pn.MID
		WHERE i.ConsumerCombinationID IS NULL
		AND pn.MID IS NULL

	END



------------------------------------------------------------------------------------------------------------------- 
-- Load Secondary IDs CC dataflow task
-- EXEC Staging.CreditCardLoad_PaypalSecondary_Fetch
------------------------------------------------------------------------------------------------------------------- 
/*
INSERT INTO Staging.CTLoad_PaypalSecondaryID (FileID, RowNum, MID, Narrative, ConsumerCombinationID)
SELECT FileID
	, RowNum
	, MID
	, Narrative
	, ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage
WHERE RequiresSecondaryID = 1
*/


------------------------------------------------------------------------------------------------------------------- 
-- Match Secondary IDs CC
-- EXEC Staging.CreditCardLoad_PaypalSecondaryIDs_Set
------------------------------------------------------------------------------------------------------------------- 
/*
--set existing secondary combinations
UPDATE Staging.CTLoad_PaypalSecondaryID SET SecondaryCombinationID = p.PaymentGatewayID
FROM Staging.CTLoad_PaypalSecondaryID s
INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
	ON s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative

--disable index prior to insert
ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

--insert new secondary combinations
INSERT INTO Relational.PaymentGatewaySecondaryDetail(ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, Narrative
FROM Staging.CTLoad_PaypalSecondaryID
WHERE SecondaryCombinationID IS NULL

--rebuild index following insert for subsequent querying
ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD

--update rows with newly inserted IDs
UPDATE Staging.CTLoad_PaypalSecondaryID SET SecondaryCombinationID = p.PaymentGatewayID
FROM Staging.CTLoad_PaypalSecondaryID s
INNER JOIN Relational.PaymentGatewaySecondaryDetail p -- 28,751,700
	ON s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative
WHERE s.SecondaryCombinationID IS NULL

--update staging table with secondary IDs
UPDATE i
SET SecondaryCombinationID = p.SecondaryCombinationID
FROM Staging.CreditCardLoad_InitialStage i
INNER JOIN Staging.CTLoad_PaypalSecondaryID p ON i.FileID = p.FileID AND i.RowNum = p.RowNum

TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID
*/
---------------------------------
-- NEW VERSION
SELECT DISTINCT ConsumerCombinationID, MID, Narrative
INTO #PaymentGatewaySecondaryDetail
FROM Staging.CreditCardLoad_InitialStage s
WHERE RequiresSecondaryID = 1
AND NOT EXISTS (
	SELECT 1 FROM Relational.PaymentGatewaySecondaryDetail p -- 28,751,700
	WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative
)

INSERT INTO Relational.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, Narrative
FROM #PaymentGatewaySecondaryDetail

UPDATE s SET SecondaryCombinationID = x.PaymentGatewayID
FROM Staging.CreditCardLoad_InitialStage s
CROSS APPLY (
	SELECT PaymentGatewayID = MIN(PaymentGatewayID) 
	FROM Relational.PaymentGatewaySecondaryDetail p -- 28,751,700
	WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative
) x
WHERE RequiresSecondaryID = 1
	AND s.SecondaryCombinationID IS NULL
---------------------------------


------------------------------------------------------------------------------------------------------------------- 
-- Distribute Transactions CC dataflow task creditcardload_initialstage into relational.consumertransaction_creditcardholding
------------------------------------------------------------------------------------------------------------------- 
INSERT INTO relational.consumertransaction_creditcardholding (
	[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], 
	[CardholderPresentData], 
	[TranDate], [CINID], [Amount], 
	[IsOnline], 
	[LocationID], [FanID]
)
SELECT 	[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], 
	[CardholderPresentData] = 0, -- ###
	[TranDate], [CINID], [Amount], 
	[IsOnline] = 0,  -- ###
	[LocationID], [FanID]
FROM staging.creditcardload_initialstage
WHERE 0 = 1 -- get this from the SSIS package

insert into staging.CreditCardLoad_MIDIHolding (
	[FileID],[RowNum],[OriginatorReference],[LocationCountry],[MID],[Narrative],[MCC],[PostCode],[CIN],[CardholderPresentMC],[Amount],[TranDateString],
	[TranDate],[ConsumerCombinationID],[SecondaryCombinationID],[RequiresSecondaryID],[MCCID],[LocationID],[CINID],[PaymentTypeID],[FanID]
)
SELECT [FileID]
      ,[RowNum]
      ,[OriginatorReference]
      ,[LocationCountry]
      ,[MID]
      ,[Narrative]
      ,[MCC]
      ,[PostCode]
      ,[CIN]
      ,[CardholderPresentMC]
      ,[Amount]
      ,[TranDateString]
      ,[TranDate]
      ,[ConsumerCombinationID]
      ,[SecondaryCombinationID]
      ,[RequiresSecondaryID]
      ,[MCCID]
      ,[LocationID]
      ,[CINID]
      ,[PaymentTypeID]
      ,[FanID] 
FROM staging.creditcardload_initialstage
WHERE 0 = 1 -- get this from the SSIS package



------------------------------------------------------------------------------------------------------------------- 
-- Clear Holding Tables CC
-- EXEC Staging.CreditCardLoad_HoldingTable_Clear
------------------------------------------------------------------------------------------------------------------- 
TRUNCATE TABLE Staging.CreditCardLoad_InitialStage

RETURN 0