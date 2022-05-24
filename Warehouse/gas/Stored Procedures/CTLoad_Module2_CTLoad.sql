/*
Grab new rows from Archive_Light.dbo.NobleTransactionHistory_MIDI into CTLoad_InitialStage

Tag loads of columns, including updating lookups.
 
Set Non-Paypal combinations

Set Paypal combinations

Set LocationIDs, including putting new ones into Relational.Location

Distribute transactions: 
	matched transactions go to Relational.ConsumerTransactionHolding
	unmatched transactions go to CTLoad_MIDIHolding

CTLoad_InitialStage is purged

*/
CREATE procedure [gas].[CTLoad_Module2_CTLoad] 

	@FileID INT

AS 

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


-------------------------------------------------------------------------------------------------------------------
-- Load CTLoad_InitialStage	Data flow task	Archive DB	Staging.CTLoad_InitialStage
-- Archive_Light.dbo.NobleTransactionHistory_MIDI -- 750GB  (3,739,471,457 rows), goes back to 2017-07-11
-------------------------------------------------------------------------------------------------------------------
INSERT INTO Staging.CTLoad_InitialStage 
	(FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, MCC, CardholderPresentData, TranDate, PaymentCardID, Amount, OriginatorID, PostStatus, CardInputMode, PaymentTypeID)
SELECT FileID
		, RowNum
		, BankID
		, LTRIM(RTRIM(MerchantID)) 
		, LTRIM(RTRIM(LocationName)) AS varNarrative
		, LTRIM(RTRIM(LocationAddress)) AS varLocationAddress
		, LTRIM(RTRIM(LocationCountry)) AS varLocationCountry
		, MCC
		, CardholderPresentData
		, TranDate AS varTranDate
		, PaymentCardID
		, Amount
		, OriginatorID
		, PostStatus
		, CardInputMode
		, CAST(1 AS TINYINT) AS PaymentTypeID
FROM Archive_Light.dbo.NobleTransactionHistory_MIDI  
WHERE FileID = @FileID


-------------------------------------------------------------------------------------------------------------------
-- Set column values	gas.CTLoad_SetInitialColumnValues		
-------------------------------------------------------------------------------------------------------------------
UPDATE h SET BankID = b.bankid
FROM Staging.CTLoad_InitialStage h  
INNER JOIN Relational.CardTransactionBank b   
	on h.BankIDString = b.BankIdentifier
	
UPDATE Staging.CTLoad_InitialStage SET 
	IsOnline = CASE WHEN CardholderPresentData = 5 THEN 1 ELSE 0 END, 
	IsRefund = CASE WHEN Amount < 0 THEN 1 ELSE 0 END


INSERT INTO Relational.MCCList (MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
SELECT DISTINCT MCC, '', '', '', 1
FROM Staging.CTLoad_InitialStage h
WHERE NOT EXISTS (SELECT 1 FROM Relational.MCCList m WHERE h.MCC = m.MCC)

UPDATE h SET MCCID = m.MCCID
FROM Staging.CTLoad_InitialStage h
INNER JOIN Relational.MCCList m 
	ON h.MCC = m.MCC


UPDATE h SET PostStatusID = p.PostStatusID
FROM Staging.CTLoad_InitialStage H
INNER JOIN Relational.PostStatus p 
	ON h.PostStatus = p.PostStatusDesc

UPDATE h SET CIN = i.SourceUID
FROM Staging.CTLoad_InitialStage h  
INNER JOIN SLC_Report.dbo.IssuerPaymentCard p   
	ON h.PaymentCardID = p.PaymentCardID
INNER JOIN SLC_Report.dbo.IssuerCustomer i   
	ON p.IssuerCustomerID= i.ID

INSERT INTO Relational.CINList(CIN)
SELECT CIN
FROM Staging.CTLoad_InitialStage
EXCEPT
SELECT CIN
FROM Relational.CINList

UPDATE h SET CINID = c.CINID
FROM Staging.CTLoad_InitialStage h  
INNER JOIN Relational.CINList C   
	ON h.CIN = c.CIN

UPDATE i SET InputModeID = c.InputModeID
FROM Staging.CTLoad_InitialStage i
INNER JOIN Relational.CardInputMode c 
	ON i.CardInputMode = c.CardInputMode



-------------------------------------------------------------------------------------------------------------------
-- Set Non-Paypal combinations	gas.CTLoad_CombinationsNonPaypal_Set		
-------------------------------------------------------------------------------------------------------------------
UPDATE i SET ConsumerCombinationID = c.ConsumerCombinationID
FROM Staging.CTLoad_InitialStage i
INNER JOIN Relational.ConsumerCombination c 
	ON i.MID = c.MID
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
CROSS APPLY (
	SELECT NewConsumerCombinationID = CASE 
		WHEN i.Narrative = c.Narrative AND c.IsHighVariance = 0 THEN c.ConsumerCombinationID 
		WHEN i.Narrative LIKE c.Narrative AND c.IsHighVariance = 1 THEN c.ConsumerCombinationID -- WHAT??
		ELSE i.ConsumerCombinationID END
) x
WHERE i.ConsumerCombinationID IS NULL
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal



-------------------------------------------------------------------------------------------------------------------
-- Set Paypal combinations	gas.CTLoad_CombinationsPaypal_Set		
-------------------------------------------------------------------------------------------------------------------
CREATE TABLE #PaypalCombosNonDefault (
	ConsumerCombinationID INT --PRIMARY KEY
	, LocationCountry VARCHAR(3) NOT NULL
	, MCCID SMALLINT NOT NULL
	, OriginatorID VARCHAR(11) NOT NULL)

INSERT INTO #PaypalCombosNonDefault (ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
FROM Relational.ConsumerCombination
WHERE PaymentGatewayStatusID = 1

CREATE CLUSTERED INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID)


CREATE TABLE #PaypalMIDNew(MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)

INSERT INTO #PaypalMIDNew (MID, TranCount)
SELECT MID, COUNT(*)
FROM Staging.CTLoad_InitialStage
WHERE Narrative LIKE 'PAYPAL%'
	AND ConsumerCombinationID IS NULL
GROUP BY MID
HAVING COUNT(*) >= 10


UPDATE i SET ConsumerCombinationID = c.ConsumerCombinationID
	, RequiresSecondaryID = 1
FROM Staging.CTLoad_InitialStage i
INNER JOIN #PaypalCombosNonDefault c 
	ON i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorID = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
	AND i.Narrative LIKE 'PAYPAL%'



DECLARE @ComboRequiredCount INT

SELECT @ComboRequiredCount = COUNT(*)
FROM Staging.CTLoad_InitialStage i
WHERE i.ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
	AND i.Narrative LIKE 'PAYPAL%'

IF @ComboRequiredCount > 0
BEGIN

	ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON Relational.ConsumerCombination DISABLE
	ALTER INDEX [IX_Relational_ConsumerCombination] ON Relational.ConsumerCombination DISABLE
		
	INSERT INTO Relational.ConsumerCombination (BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
	SELECT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorID, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
	FROM Staging.CTLoad_InitialStage i
	WHERE i.ConsumerCombinationID IS NULL
		AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
		AND i.Narrative LIKE 'PAYPAL%'
		
	ALTER INDEX [IX_NCL_Relational_ConsumerCombination_Matching] ON Relational.ConsumerCombination REBUILD
	ALTER INDEX [IX_Relational_ConsumerCombination] ON Relational.ConsumerCombination REBUILD

	UPDATE i SET ConsumerCombinationID = c.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN #PaypalCombosNonDefault c 
		ON i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
	WHERE i.ConsumerCombinationID IS NULL
		AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
		AND i.Narrative LIKE 'PAYPAL%'

END




-------------------------------------------------------------------------------------------------------------------
-- Load CTLoad_PaypalSecondaryID	Data flow task	Staging.CTLoad_InitialStage	Staging.CTLoad_PaypalSecondaryID EXEC gas.CTLoad_PaypalSecondary_Fetch
-- no longer required
-------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
-- Match SecondaryIDs	gas.CTLoad_PaypalSecondaryIDs_Set	
-- #1 slowest stored procedure, 15 minutes. Six minutes to rebuild the index.	
-------------------------------------------------------------------------------------------------------------------
--disable index prior to insert
ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

--insert new secondary combinations
INSERT INTO Relational.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative) -- 28,719,654
SELECT ConsumerCombinationID, MID, Narrative FROM Staging.CTLoad_InitialStage WHERE RequiresSecondaryID = 1
EXCEPT
SELECT ConsumerCombinationID, MID, Narrative FROM Relational.PaymentGatewaySecondaryDetail

--rebuild index following insert for subsequent querying
ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD

--set existing secondary combinations
UPDATE s SET SecondaryCombinationID = p.PaymentGatewayID
FROM Staging.CTLoad_InitialStage s
INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
	ON s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative
WHERE s.RequiresSecondaryID = 1



-------------------------------------------------------------------------------------------------------------------
-- Set LocationIDs	gas.CTLoad_LocationIDs_Set		
-------------------------------------------------------------------------------------------------------------------
--SET VALID LOCATIONS
UPDATE i SET LocationID = L.LocationID
FROM Staging.CTLoad_InitialStage i
INNER JOIN Relational.Location l 
	ON i.ConsumerCombinationID = l.ConsumerCombinationID
	AND i.LocationAddress = l.LocationAddress
WHERE l.IsNonLocational = 0

--SET NON-LOCATION ADDRESSES
UPDATE i SET LocationID = L.LocationID
FROM Staging.CTLoad_InitialStage i
INNER JOIN Relational.Location l 
	ON i.ConsumerCombinationID = l.ConsumerCombinationID
WHERE l.IsNonLocational = 1
	AND i.LocationID IS NULL


--DISABLE INDEX PRIOR TO INSERT
ALTER INDEX IX_Relational_Location_Cover ON Relational.Location DISABLE

--INSERT NEW LOCATIONS
INSERT INTO Relational.Location (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM Staging.CTLoad_InitialStage
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL

--ENABLE INDEX FOLLOWING INSERT
ALTER INDEX IX_Relational_Location_Cover ON Relational.Location REBUILD


--SET NEW LOCATIONS
UPDATE i SET LocationID = L.LocationID
FROM Staging.CTLoad_InitialStage i
INNER JOIN Relational.Location l 
	ON i.ConsumerCombinationID = l.ConsumerCombinationID
	AND i.LocationAddress = l.LocationAddress
WHERE l.IsNonLocational = 0
AND i.LocationID IS NULL



-------------------------------------------------------------------------------------------------------------------
-- Distribute transactions	Data flow task	Staging.CTLoad_InitialStage	Relational.ConsumerTransactionHolding / Staging.CTLoad_MIDIHolding
-------------------------------------------------------------------------------------------------------------------
INSERT INTO Relational.ConsumerTransactionHolding (
	FileID, RowNum, BankID, 
		--MID, Narrative, LocationAddress, LocationCountry, 
		CardholderPresentData, TranDate
		, CINID, Amount, IsOnline, IsRefund, 
		--OriginatorID, MCCID, 
		PostStatusID, LocationID, ConsumerCombinationID
		, SecondaryCombinationID, InputModeID, PaymentTypeID
)
SELECT FileID, RowNum, BankID, 
	--MID, Narrative, LocationAddress, LocationCountry, 
	CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, 
	--OriginatorID, MCCID, 
	PostStatusID, LocationID, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM Staging.CTLoad_InitialStage
WHERE CINID IS NOT NULL
AND (LocationID IS NOT NULL AND ConsumerCombinationID IS NOT NULL)


INSERT INTO Staging.CTLoad_MIDIHolding (
	FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
		, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID, ConsumerCombinationID
		, SecondaryCombinationID, InputModeID, PaymentTypeID
)
SELECT FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID, ConsumerCombinationID
	, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM Staging.CTLoad_InitialStage
WHERE CINID IS NOT NULL
AND (LocationID IS NULL OR ConsumerCombinationID IS NULL)



-------------------------------------------------------------------------------------------------------------------
-- QA Logging	gas.CTLoad_QAStats_Set		
-------------------------------------------------------------------------------------------------------------------
   INSERT INTO Staging.CardTransaction_QA(FileID, FileCount, MatchedCount, UnmatchedCount, NoCINCount, PositiveCount)
	SELECT FileID
		, COUNT(1) AS FileCount
		, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 0 ELSE 1 END) AS MatchedCount
		, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
		, SUM(CASE WHEN CINID IS NULL THEN 0 ELSE 1 END) AS NoCINCount
		, SUM(CASE WHEN IsRefund = 0 THEN 1 ELSE 0 END) AS PositiveCount
	FROM Staging.CTLoad_InitialStage
	GROUP BY FileID



-------------------------------------------------------------------------------------------------------------------
-- Clear holding tables	gas.CTLoad_StagingTables_Clear		
-------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE Staging.CTLoad_InitialStage
TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID



RETURN 0
