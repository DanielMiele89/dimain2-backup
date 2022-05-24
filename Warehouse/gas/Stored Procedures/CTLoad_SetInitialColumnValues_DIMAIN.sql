-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Sets unpopulated columns in the initial staging table
-- CJM added ORDER BY
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_SetInitialColumnValues_DIMAIN]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE STATISTICS [Staging].[CTLoad_InitialStage]
	UPDATE STATISTICS Relational.MCCList

    UPDATE [Staging].[CTLoad_InitialStage] SET BankID = b.bankid
	FROM [Staging].[CTLoad_InitialStage] h WITH (NOLOCK)
	INNER JOIN Relational.CardTransactionBank b WITH (NOLOCK) on h.BankIDString = b.BankIdentifier
	
	UPDATE [Staging].[CTLoad_InitialStage]
	SET IsOnline =	CASE
						WHEN CardholderPresentData = 5 THEN 1
						ELSE 0
					END
	,	IsRefund = CASE
						WHEN Amount < 0 THEN 1
						ELSE 0
					END

	UPDATE [Staging].[CTLoad_InitialStage] SET MCCID = m.MCCID
	FROM [Staging].[CTLoad_InitialStage] h
	INNER JOIN Relational.MCCList m ON h.MCC = m.MCC

	INSERT INTO Relational.MCCList(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT DISTINCT MCC, '', '', '', 1
	FROM [Staging].[CTLoad_InitialStage]
	WHERE MCCID IS NULL
	ORDER BY MCC

	UPDATE [Staging].[CTLoad_InitialStage] SET MCCID = m.MCCID
	FROM [Staging].[CTLoad_InitialStage] h
	INNER JOIN Relational.MCCList m ON h.MCC = m.MCC
	WHERE h.MCCID IS NULL

	UPDATE [Staging].[CTLoad_InitialStage] SET PostStatusID = p.PostStatusID
	FROM [Staging].[CTLoad_InitialStage] H
	INNER JOIN Relational.PostStatus p ON h.PostStatus = p.PostStatusDesc

	--UPDATE [Staging].[CTLoad_InitialStage] SET CIN = i.SourceUID
	--FROM [Staging].[CTLoad_InitialStage] h WITH (NOLOCK)
	--INNER JOIN SLC_REPL.dbo.IssuerPaymentCard p WITH (NOLOCK) ON h.PaymentCardID = p.PaymentCardID
	--INNER JOIN SLC_REPL.dbo.IssuerCustomer i WITH (NOLOCK) ON p.IssuerCustomerID= i.ID

-- Proposed unambiguous version - choose the highest SourceUID
	UPDATE h SET
		CIN = x.SourceUID
	FROM [Staging].[CTLoad_InitialStage] h
	CROSS APPLY (
		SELECT TOP(1) i.SourceUID
		FROM SLC_REPL.dbo.IssuerPaymentCard p
		INNER JOIN SLC_REPL.dbo.IssuerCustomer i
			ON i.ID = p.IssuerCustomerID
		LEFT JOIN SLC_REPL.dbo.Fan f 
			ON f.SourceUID = i.SourceUID  
			AND ((f.ClubID = 132 AND i.IssuerID = 2) OR (f.ClubID = 138 AND i.IssuerID = 1))    
		LEFT JOIN Warehouse.Relational.Customer c 
			ON c.SourceUID = i.SourceUID
		WHERE p.PaymentCardID = h.PaymentCardID
		ORDER BY f.[Status] DESC, c.[Status] DESC, p.IssuerCustomerID DESC
	) x;

	INSERT INTO Relational.CINList (CIN)
	SELECT CIN
	FROM (
		SELECT CIN
		FROM [Staging].[CTLoad_InitialStage]
		EXCEPT
		SELECT CIN
		FROM Relational.CINList
	) d
	ORDER BY CIN -- CJM added ORDER BY

	UPDATE [Staging].[CTLoad_InitialStage] SET CINID = c.CINID
	FROM [Staging].[CTLoad_InitialStage] h WITH (NOLOCK)
	INNER JOIN Relational.CINList C WITH (NOLOCK) ON h.CIN = c.CIN

	IF OBJECT_ID('tempdb..#VCR') IS NOT NULL DROP TABLE #VCR
	SELECT *
	INTO #VCR
	FROM [Staging].[CTLoad_InitialStage] ct
	WHERE MID LIKE 'VCR%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%'

	UPDATE vcr
	SET vcr.MID = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(MID, '0', ''), '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', ''), '8', ''), '9', '')
	FROM #VCR vcr

	CREATE CLUSTERED INDEX CIX_MID ON #VCR (FileID, RowNum, MID)

	UPDATE ct
	SET ct.MID = LTRIM(RTRIM(vcr.MID)) + '%'
	FROM #VCR vcr
	INNER JOIN [Staging].[CTLoad_InitialStage] ct
		ON vcr.FileID = ct.FileID
		AND vcr.RowNum = ct.RowNum

	UPDATE [Staging].[CTLoad_InitialStage]
	SET	MID = LTRIM(RTRIM(MID))
	,	Narrative = LTRIM(RTRIM(Narrative))
	,	LocationAddress = LTRIM(RTRIM(LocationAddress))	
	,	LocationCountry = LTRIM(RTRIM(LocationCountry))

	UPDATE [Staging].[CTLoad_InitialStage]
	SET InputModeID = c.InputModeID
	FROM [Staging].[CTLoad_InitialStage] i
	INNER JOIN Relational.CardInputMode c on i.CardInputMode = c.CardInputMode
	
END