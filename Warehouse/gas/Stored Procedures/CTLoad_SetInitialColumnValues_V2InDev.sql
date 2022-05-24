-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Sets unpopulated columns in the initial staging table
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_SetInitialColumnValues_V2InDev]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE STATISTICS [Staging].[CTLoad_InitialStage]

	--	MCC

	CREATE NONCLUSTERED INDEX IX_MCC ON [Staging].[CTLoad_InitialStage] (MCC, MCCID)

	IF OBJECT_ID('tempdb..#CT_MCC') IS NOT NULL DROP TABLE #CT_MCC
	SELECT	DISTINCT 
			ct.MCC
		,	NULL AS MCCID
	INTO #CT_MCC
	FROM [Staging].[CTLoad_InitialStage] ct

	INSERT INTO [Relational].[MCCList](	MCC
									,	MCCGroup
									,	MCCCategory
									,	MCCDesc
									,	SectorID)
	SELECT	DISTINCT 
			ct_mcc.MCC
		,	'' AS MCCGroup
		,	'' AS MCCCategory
		,	'' AS MCCDesc
		,	1 AS SectorID
	FROM #CT_MCC ct_mcc
	WHERE NOT EXISTS (	SELECT 1
						FROM [Relational].[MCCList] mcc
						WHERE ct_mcc.MCC = mcc.MCC)

	UPDATE STATISTICS [Relational].[MCCList]

	UPDATE ct_mcc
	SET ct_mcc.MCCID = mcc.MCCID
	FROM #MCC ct_mcc
	INNER JOIN [Relational].[MCCList] mcc
		ON ct_mcc.MCC = mcc.MCC

	CREATE CLUSTERED INDEX CIX_MCC ON #MCC (MCC, MCCID)
	
	UPDATE ct
	SET ct.MCCID = mcc.MCCID
	FROM [Staging].[CTLoad_InitialStage] ct
	INNER JOIN #MCC mcc
		ON ct.MCC = mcc.MCC

	UPDATE ct
	SET ct.MCCID = (SELECT mcc.MCCID FROM #MCC mcc WHERE ct.MCC = mcc.MCC)
	FROM [Staging].[CTLoad_InitialStage] ct

	--	CIN

	CREATE NONCLUSTERED INDEX IX_CINPaymentCardID ON [Staging].[CTLoad_InitialStage] (PaymentCardID, CIN, CINID)

	IF OBJECT_ID('tempdb..#IssuerPaymentCard') IS NOT NULL DROP TABLE #IssuerPaymentCard
	SELECT	ipc.PaymentCardID
		,	ipc.IssuerCustomerID
	INTO #IssuerPaymentCard
	FROM [SLC_REPL].[dbo].[IssuerPaymentCard] ipc
	WHERE EXISTS (	SELECT 1
					FROM [Staging].[CTLoad_InitialStage] ct
					WHERE ipc.PaymentCardID = ct.PaymentCardID)

	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IssuerPaymentCard (IssuerCustomerID)

	IF OBJECT_ID('tempdb..#IssuerCustomer') IS NOT NULL DROP TABLE #IssuerCustomer
	SELECT	DISTINCT
			ipc.PaymentCardID
		,	ipc.IssuerCustomerID
		,	ic.SourceUID
		,	ic.IssuerID
	INTO #IssuerCustomer
	FROM [SLC_REPL].[dbo].[IssuerCustomer] ic
	INNER JOIN #IssuerPaymentCard ipc
		ON ic.ID = ipc.IssuerCustomerID



	SELECT *
	FROM [SLC_REPL].[dbo].[IssuerCustomer] ic
	INNER JOIN  [SLC_REPL].[dbo].[IssuerPaymentCard] ipc
		ON ic.ID = ipc.IssuerCustomerID
	WHERE PaymentCardID = 86653187


	CREATE CLUSTERED INDEX CIX_CIN ON #IssuerCustomer (PaymentCardID, SourceUID)
	
	INSERT INTO [Relational].[CINList] (CIN)
	SELECT	DISTINCT
			SourceUID
	FROM #IssuerCustomer
	EXCEPT
	SELECT	CIN
	FROM [Relational].[CINList]
	
	IF OBJECT_ID('tempdb..#CIN') IS NOT NULL DROP TABLE #CIN
	SELECT	ic.PaymentCardID
		,	cl.CIN
		,	cl.CINID
		,	fa.ID
		,	fa.ClubID
		,	ic.IssuerID
	INTO #CIN
	FROM #IssuerCustomer ic
	INNER JOIN [Relational].[CINList] cl
		ON ic.SourceUID = cl.CIN
	INNER JOIN [SLC_Repl].[dbo].[Fan] fa
		ON ic.SourceUID = fa.SourceUID
		AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)

	CREATE CLUSTERED INDEX CIX_CIN ON #CIN (PaymentCardID, CIN, CINID)


	SELECT PaymentCardID
	FROM #CIN
	GROUP BY PaymentCardID
	HAVING COUNT(*) > 1

	SELECT *
	FROM #CIN
	WHERE PaymentCardID = 85920413



	UPDATE ct
	SET ct.CIN = (SELECT ci.CIN FROM #CIN ci WHERE ct.PaymentCardID = ci.PaymentCardID)
	,	ct.CINID = (SELECT ci.CINID FROM #CIN ci WHERE ct.PaymentCardID = ci.PaymentCardID)
	FROM [Staging].[CTLoad_InitialStage] ct





    UPDATE ct
	SET ct.BankID = ctb.BankID
	FROM [Staging].[CTLoad_InitialStage] ct
	INNER JOIN [Relational].[CardTransactionBank] ctb
		ON ct.BankIDString = ctb.BankIdentifier
	
	UPDATE [Staging].[CTLoad_InitialStage]
	SET IsOnline =	CASE
						WHEN CardholderPresentData = 5 THEN 1
						ELSE 0
					END
	,	IsRefund = CASE
						WHEN Amount < 0 THEN 1
						ELSE 0
					END



	

	UPDATE [Staging].[CTLoad_InitialStage] SET PostStatusID = p.PostStatusID
	FROM [Staging].[CTLoad_InitialStage] H
	INNER JOIN [Relational].PostStatus p ON h.PostStatus = p.PostStatusDesc


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
	INNER JOIN [Relational].CardInputMode c on i.CardInputMode = c.CardInputMode
	
END