/*
Author:		Suraj Chahal
Date:		11th March 2013
Purpose:	To Build a Redemption table in the staging schema
		then Relational schema of the Warehouse database
		
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.		
			
			28/01/2014 SB - Amended to allow trade up values to be added for trades up where value is not 
						    obvious using new table 'Warehouse.Relational.RedemptionItem_TradeUpValue'
			05/02/2014 SB - Extra code added to deal with Caffe Nero redemption labelled as 'Caffé Nero'
			06/02/2014 SB - Amend to allow for Redemptions Fulfilled that were not ordered (speicifc 
							issue that needed to be resolved).
			20-02-2014 SB - Amended to remove Warehouse referencing
			10-09-2014 SC - Added Index Rebuild
			19-03-2015 SB - Extra code to deal with Zinio offers
			16-12-2015 SB - Coded to link to RI Staging table to pull through Partner Info
			09-08-2017 SB - Speed Up process to find extra time in ETL load
			27-02-2018 JEA - Add gift aid for charity redemptions
*/

CREATE PROCEDURE [WHB].[Redemptions_Redemptions_V2]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

/*******************************************************************************************************************************************
	1.	Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID)
		,	TableSchemaName = 'Staging'
		,	TableName = 'Redemptions'
		,	StartDate = GETDATE()
		,	EndDate = NULL
		,	TableRowCount  = NULL
		,	AppendReload = 'R'


/*******************************************************************************************************************************************
	2.	Fetch Cancelled redemptions & update existing entries that have been cancelled
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Cancelled') IS NOT NULL DROP TABLE #Cancelled
	SELECT	tr.ItemID AS TransID
		,	1 AS Cancelled
		,	tr.Date AS CancelledDate
	INTO #Cancelled
	FROM [SLC_Report].[dbo].[Trans] tr
	WHERE tr.TypeID = 4

	CREATE CLUSTERED INDEX CIX_TransID ON #Cancelled (TransID)
	
	UPDATE re
	SET re.Cancelled = 1
	FROM [Staging].[Redemptions] re
	INNER JOIN #Cancelled ca
		ON re.TranID = ca.TransID
		AND re.RedeemDate < ca.CancelledDate
		AND re.Cancelled = 0


/*******************************************************************************************************************************************
	3.	Fetch [SLC_Report].[dbo].[RedeemAction] into a temp table entries for indexing / performance
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RedeemAction') IS NOT NULL DROP TABLE #RedeemAction
	SELECT TransID
	INTO #RedeemAction
	FROM [SLC_Report].[dbo].[RedeemAction] ra
	WHERE ra.Status IN (1, 6)

	CREATE CLUSTERED INDEX CIX_TransID ON #RedeemAction (TransID)


/*******************************************************************************************************************************************
	4.	Fetch all redemptions, flagging those that are cancelled & where gift aid has been added
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	tr.FanID
		,	cu.CompositeID
		,	tr.ID AS TransID
		,	tr.Date AS RedeemDate
		,	tr.Price
		,	COALESCE(ca.Cancelled, 0) AS Cancelled
		,	CASE
				WHEN tr.[Option] = 'Yes I am a UK tax payer and eligible for gift aid' THEN 1
				ELSE 0
			END AS GiftAid
		,	tr.ItemID
	INTO #Trans
	FROM [SLC_Report].[dbo].[Trans] tr
	INNER JOIN [Relational].[Customer] cu
		ON tr.FanID = cu.FanID
	LEFT JOIN #Cancelled ca
		ON tr.ID = ca.TransID
	WHERE tr.TypeID = 3
	AND 0 < tr.Points
	AND EXISTS (	SELECT 1
					FROM #RedeemAction ra
					WHERE tr.ID = ra.TransID)
	AND NOT EXISTS (SELECT 1
					FROM [Staging].[Redemptions] re
					WHERE tr.ID = re.TranID)

	CREATE CLUSTERED INDEX CIX_ItemID ON #Trans (ItemID)


/*******************************************************************************************************************************************
	5.	Fetch all redemption offer details, fomatting the offer descriptions
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RedemptionItem') IS NOT NULL DROP TABLE #RedemptionItem
	SELECT	re.ID AS RedeemID
		,	re.Description AS PrivateDescription
		,	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(re.Description, '&pound;', '£'), '{em}', ''), '{/em}', ''), 'B&amp;Q', 'B&Q'))) AS RedemptionDescription
		,	ri.RedeemType
		,	tuv.PartnerID
		,	COALESCE(pa.PartnerName, 'N/A') AS PartnerName
		,	CASE
				WHEN TradeUp_Value > 0 THEN 1
				ELSE 0
			END AS TradeUp_WithValue
		,	tuv.TradeUp_Value
	INTO #RedemptionItem
	FROM [SLC_Report].[dbo].[Redeem] re
	LEFT JOIN [Relational].[RedemptionItem] ri
		ON re.ID = ri.RedeemID
	LEFT JOIN [Relational].[RedemptionItem_TradeUpValue] tuv
		ON ri.RedeemID = tuv.RedeemID
	LEFT JOIN [Relational].[Partner] pa
		ON tuv.PartnerID = pa.PartnerID

	UPDATE #RedemptionItem
	SET RedemptionDescription = CASE
									WHEN LEFT(RedemptionDescription, 3) = '£5 ' THEN 'D' + RIGHT(RedemptionDescription, LEN(RedemptionDescription) - 4)
									WHEN LEFT(RedemptionDescription, 3) LIKE '£_0' THEN 'D' + RIGHT(RedemptionDescription, LEN(RedemptionDescription) - 5)
									ELSE RedemptionDescription
								END
	WHERE RedeemType = 'Charity'

	CREATE CLUSTERED INDEX CIX_RedeemID ON #RedemptionItem (RedeemID)


/*******************************************************************************************************************************************
	6.	Insert new redemptions to Staging table
*******************************************************************************************************************************************/

	DECLARE @Rowcount BIGINT

	--TRUNCATE TABLE [Staging].[Redemptions]
	INSERT INTO [Staging].[Redemptions]
	SELECT	tr.FanID
		,	tr.CompositeID
		,	tr.TransID
		,	tr.RedeemDate
		,	ri.RedeemType
		,	ri.RedemptionDescription
		,	ri.PartnerID
		,	ri.PartnerName
		,	tr.Price
		,	ri.TradeUp_WithValue
		,	ri.TradeUp_Value
		,	tr.Cancelled
		,	tr.GiftAid
	FROM #Trans tr
	LEFT JOIN #RedemptionItem ri
		ON tr.ItemID = ri.RedeemID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Staging].[Redemptions] re
						WHERE tr.TransID = re.TranID)

	SET @Rowcount = @@ROWCOUNT
						
/*******************************************************************************************************************************************
	7.	Update entry in JobLog Table with End Date & rowcount
*******************************************************************************************************************************************/
	
	UPDATE [Staging].[JobLog_Temp]
	SET EndDate = GETDATE()
	  , TableRowCount = @Rowcount
	WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
	AND TableSchemaName = 'Staging'
	AND TableName = 'Redemptions'
	AND EndDate IS NULL


/*******************************************************************************************************************************************
	8.	Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID)
		,	TableSchemaName = 'Staging'
		,	TableName = 'Redemptions_ECodes'
		,	StartDate = GETDATE()
		,	EndDate = NULL
		,	TableRowCount  = NULL
		,	AppendReload = 'R'

/*******************************************************************************************************************************************
	9.	Fetch Cancelled E Code redemptions & update existing entries that have been cancelled
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CancelledECodes') IS NOT NULL DROP TABLE #CancelledECodes
	SELECT	ech.ECodeID
		,	1 AS Cancelled
		,	ech.StatusChangeDate AS CancelledDate
	INTO #CancelledECodes
	FROM [SLC_Report].[Redemption].[ECodeStatusHistory] ech
	WHERE 1 <= ech.Status

	CREATE CLUSTERED INDEX CIX_ECodeIDCancelledDate ON #CancelledECodes (ECodeID, CancelledDate)
	
	UPDATE ec
	SET ec.Cancelled = 1
	FROM [Staging].[Redemptions_ECodes] ec
	INNER JOIN #CancelledECodes cec
		ON ec.ECodeID = cec.ECodeID
		AND ec.RedeemDate < cec.CancelledDate
		AND ec.Cancelled = 0


/*******************************************************************************************************************************************
	10.	Fetch Redemption Offer details for eCode offers
*******************************************************************************************************************************************/

	IF OBJECT_ID ('tempdb..#RedemptionItem_eCode') IS NOT NULL DROP TABLE #RedemptionItem_eCode
	SELECT	ri.RedeemID
		,	ri.RedeemType
		,	LTRIM(RTRIM(ri.PrivateDescription)) AS PrivateDescription
		,	tuv.PartnerID
		,	pa.PartnerName
		,	CASE
				WHEN TradeUp_Value > 0 THEN 1
				ELSE 0
			END AS TradeUp_WithValue
		,	tuv.TradeUp_Value
	INTO #RedemptionItem_eCode
	FROM [Relational].[RedemptionItem] ri
	LEFT JOIN [Relational].[RedemptionItem_TradeUpValue] tuv
		ON ri.RedeemID = tuv.RedeemID
	LEFT JOIN [Relational].[Partner] pa
		ON tuv.PartnerID = pa.PartnerID
	
	CREATE CLUSTERED INDEX CIX_RedeemID ON #RedemptionItem_eCode (RedeemID)


/*******************************************************************************************************************************************
	11.	Fetch [SLC_Report].[Redemption].[ECodeStatusHistory] entries for issued E-Codes
*******************************************************************************************************************************************/

	DECLARE @GETDATE DATE = GETDATE()

	IF OBJECT_ID ('tempdb..#ECodeStatusHistory') IS NOT NULL DROP TABLE #ECodeStatusHistory
	SELECT	ech.ECodeID
		,	MAX(StatusChangeDate) as IssuedDate
	INTO #ECodeStatusHistory
	FROM [SLC_Report].[Redemption].[ECodeStatusHistory] ech
	WHERE ech.Status = 1
	AND ech.StatusChangeDate <= @GETDATE
	GROUP BY ech.ECodeID
	
	CREATE CLUSTERED INDEX CIX_ECodeID ON #ECodeStatusHistory (ECodeID)


/*******************************************************************************************************************************************
	12.	Fetch all [SLC_Report].[dbo].[Trans] entries relating to E-Code redemptions
*******************************************************************************************************************************************/

	IF OBJECT_ID ('tempdb..#ECode') IS NOT NULL DROP TABLE #ECode
	SELECT	tr.FanID
		,	cu.CompositeID
		,	ec.TransID as TranID
		,	ech.IssuedDate as RedeemDate
		,	tr.ClubCash as CashbackUsed
		,	tr.ItemID
		,	ech.ECodeID
	INTO #ECode
	FROM #ECodeStatusHistory ech
	INNER JOIN [SLC_report].[Redemption].[ECode] ec
		ON ech.ECodeID = ec.ID
	INNER JOIN [SLC_Report].[dbo].[Trans] tr
		ON ec.TransID = tr.ID
	INNER JOIN [Relational].[Customer] cu
		ON tr.FanID = cu.FanID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Staging].[Redemptions_ECodes] rec
						WHERE ec.TransID = rec.TranID)

	CREATE CLUSTERED INDEX CIX_ItemID ON #ECode (ItemID)


/*******************************************************************************************************************************************
	13.	Combine Redemptions with their offer details & insert to [Staging].[Redemptions_ECodes]
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[Redemptions_ECodes]
	SELECT  ec.FanID
		,	ec.CompositeID
		,	ec.TranID
		,	ec.RedeemDate
		,	ri.RedeemType
		,	ri.PrivateDescription as RedemptionDescription
		,	ri.PartnerID
		,	ri.PartnerName
		,	ec.CashbackUsed
		,	ri.TradeUp_WithValue
		,	ri.TradeUp_Value
		,	COALESCE(cec.Cancelled, 0) AS Cancelled
		,	ec.ECodeID
	FROM #ECode ec
	LEFT JOIN #RedemptionItem_eCode ri
		ON ec.ItemID = ri.RedeemID
	LEFT JOIN #CancelledECodes cec
		ON ec.ECodeID = cec.ECodeID
		AND ec.RedeemDate < cec.CancelledDate

	SET @RowCount = @@ROWCOUNT
						
/*******************************************************************************************************************************************
	14.	Update entry in JobLog Table with End Date & rowcount
*******************************************************************************************************************************************/
	
	UPDATE [Staging].[JobLog_Temp]
	SET EndDate = GETDATE()
	  , TableRowCount = @Rowcount
	WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
	AND TableSchemaName = 'Staging'
	AND TableName = 'Redemptions_ECodes'
	AND EndDate IS NULL


/*******************************************************************************************************************************************
	15.	Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID)
		,	TableSchemaName = 'Relational'
		,	TableName = 'Redemptions'
		,	StartDate = GETDATE()
		,	EndDate = NULL
		,	TableRowCount  = NULL
		,	AppendReload = 'R'


/*******************************************************************************************************************************************
	16.	Insert to [Relational].[Redemptions] from [Staging].[Redemptions]
*******************************************************************************************************************************************/
	
	ALTER INDEX IDX_FanID ON [Relational].[Redemptions] DISABLE

	TRUNCATE TABLE [Relational].[Redemptions]

	INSERT INTO [Relational].[Redemptions] -- 50% of overall sp cost
	SELECT *
	FROM [Staging].[Redemptions]

	SET @Rowcount = @@ROWCOUNT
	
	INSERT INTO [Relational].[Redemptions]
	SELECT	ec.FanID
		,	ec.CompositeID
		,	ec.TranID
		,	ec.RedeemDate
		,	ec.RedeemType
		,	ec.RedemptionDescription
		,	ec.PartnerID
		,	ec.PartnerName
		,	ec.CashbackUsed
		,	ec.TradeUp_WithValue
		,	ec.TradeUp_Value
		,	ec.Cancelled
		,	0 AS GiftAid
	FROM [Staging].[Redemptions_ECodes] ec
	WHERE NOT EXISTS (	SELECT 1
						FROM [Relational].[Redemptions] re
						WHERE ec.TranID = re.TranID)

	SET @Rowcount = @Rowcount + @@ROWCOUNT

	ALTER INDEX IDX_FanID ON [Relational].[Redemptions] REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212 


/*******************************************************************************************************************************************
	17.	Update entry in JobLog Table with End Date & rowcount
*******************************************************************************************************************************************/
	
	UPDATE [Staging].[JobLog_Temp]
	SET EndDate = GETDATE()
	  , TableRowCount = @Rowcount
	WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
	AND TableSchemaName = 'Relational'
	AND TableName = 'Redemptions'
	AND EndDate IS NULL
	

/*******************************************************************************************************************************************
	19.	Insert to JobLog table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog]
	SELECT	[StoredProcedureName]
		,	[TableSchemaName]
		,	[TableName]
		,	[StartDate]
		,	[EndDate]
		,	[TableRowCount]
		,	[AppendReload]
	FROM [Staging].[JobLog_Temp]

	TRUNCATE TABLE [Staging].[JobLog_Temp]

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END

