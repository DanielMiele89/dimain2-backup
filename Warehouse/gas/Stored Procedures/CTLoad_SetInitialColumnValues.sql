-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Sets unpopulated columns in the initial staging table

-- check index fill factor - expansive updates
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_SetInitialColumnValues]
	
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	UPDATE STATISTICS Staging.CTLoad_InitialStage;
	UPDATE STATISTICS Relational.MCCList;


	UPDATE i SET 
		InputModeID = ISNULL(c.InputModeID,i.InputModeID),
		BankID = ISNULL(b.bankid,i.BankID),
		PostStatusID = ISNULL(p.PostStatusID,i.PostStatusID),
		MCCID = m.MCCID
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	LEFT JOIN Relational.CardInputMode c 
		ON i.CardInputMode = c.CardInputMode
	LEFT JOIN Relational.CardTransactionBank b 
		ON i.BankIDString = b.BankIdentifier
	LEFT JOIN Relational.PostStatus p 
		ON i.PostStatus = p.PostStatusDesc
	LEFT JOIN Relational.MCCList m 
		ON i.MCC = m.MCC;


-- Unambiguous version 


	--UPDATE h SET
	--	CIN = x.SourceUID
	--FROM [Staging].[CTLoad_InitialStage] h
	--CROSS APPLY ( -- non-deterministic UPDATE
	--	SELECT TOP(1) i.SourceUID
	--	FROM SLC_REPL.dbo.IssuerPaymentCard p
	--	INNER JOIN SLC_REPL.dbo.IssuerCustomer i
	--		ON i.ID = p.IssuerCustomerID
	--	left JOIN SLC_REPL.dbo.Fan f 
	--		ON f.SourceUID = i.SourceUID  
	--		AND ((f.ClubID = 132 AND i.IssuerID = 2) OR (f.ClubID = 138 AND i.IssuerID = 1))    
	--	LEFT JOIN Warehouse.Relational.Customer c 
	--		ON c.SourceUID = i.SourceUID
	--	WHERE p.PaymentCardID = h.PaymentCardID
	--	ORDER BY f.[Status] DESC, c.[Status] DESC, p.IssuerCustomerID DESC
	--) x;

	IF OBJECT_ID('tempdb..#LiveStuff') IS NOT NULL DROP TABLE #LiveStuff; 
	CREATE TABLE #LiveStuff (PaymentCardID INT, SourceUID VARCHAR(20), [Status] INT, IssuerCustomerID INT)
	CREATE CLUSTERED INDEX cx_Stuff ON #LiveStuff (PaymentCardID)
	INSERT INTO #LiveStuff WITH (TABLOCKX) 
		(PaymentCardID, SourceUID, [Status], IssuerCustomerID) 
	SELECT p.PaymentCardID, i.SourceUID, f.[Status], p.IssuerCustomerID
	FROM DIMAIN_TR.SLC_REPL.dbo.IssuerPaymentCard p
	INNER JOIN DIMAIN_TR.SLC_REPL.dbo.IssuerCustomer i
		ON i.ID = p.IssuerCustomerID
	LEFT JOIN DIMAIN_TR.SLC_REPL.dbo.Fan f 
		ON f.SourceUID = i.SourceUID  
		AND ((f.ClubID = 132 AND i.IssuerID = 2) OR (f.ClubID = 138 AND i.IssuerID = 1))
	ORDER BY PaymentCardID
	-- (97,518,113 rows affected) / 00:03:08
	
	UPDATE h SET
		CIN = x.SourceUID
	FROM [Staging].[CTLoad_InitialStage] h
	CROSS APPLY ( -- non-deterministic UPDATE
		SELECT TOP(1) i.SourceUID
		FROM #LiveStuff i    
		LEFT JOIN Warehouse.Relational.Customer c 
			ON c.SourceUID = i.SourceUID
		WHERE i.PaymentCardID = h.PaymentCardID
		ORDER BY i.[Status] DESC, c.[Status] DESC, i.IssuerCustomerID DESC
	) x;

-----------------------------------------------------------------------------------------

	-- MCC's we haven't seen before
	INSERT INTO Relational.MCCList (MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT DISTINCT MCC, '', '', '', 1
	FROM [Staging].[CTLoad_InitialStage]
	WHERE MCCID IS NULL;
	
	-- CINs we haven't seen before
	-- CJM added DISTINCT 
	INSERT INTO Relational.CINList (CIN)
	SELECT CIN
	FROM (
		SELECT DISTINCT CIN
		FROM [Staging].[CTLoad_InitialStage]
		EXCEPT
		SELECT CIN
		FROM Relational.CINList
	) d
	ORDER BY CIN -- CJM added ORDER BY

	-----------------------------------------------------------------------------------------

	UPDATE h SET 
		MCCID = ISNULL(m.MCCID, h.MCCID),
		CINID = ISNULL(c.CINID, h.CINID)
	FROM [Staging].[CTLoad_InitialStage] h WITH (TABLOCK)
	LEFT JOIN Relational.MCCList m 
		ON h.MCC = m.MCC 
	LEFT JOIN Relational.CINList C 
		ON h.CIN = c.CIN 
	WHERE (h.CINID IS NULL OR h.MCCID IS NULL);


END

RETURN 0