
-- ***************************************************************************
-- Author: Rory Francis
-- Create date: 2019-01-18
-- Description: Fetch the most recent Direct Debit transactions for SkyMobile 
--				from Archive_Light.dbo.CBP_DirectDebit_TransactionHistory
--				and insert them into the SkyMobile Direct Debit table
-- ***************************************************************************
CREATE PROCEDURE [Staging].[DirectDebit_FetchSkyMobileDDs]
			
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/

INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID),
	TableSchemaName = 'Staging',
	TableName = 'CBP_DirectDebit_TransactionHistory_SkyMobile_DD',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


/*******************************************************************************************************************************************
	1. Fetch all DD File IDs that have not yet been processed
*******************************************************************************************************************************************/

	INSERT INTO Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed (FileID
																							   , DateProcessed
																							   , InsertCompleted)
	SELECT ID as FileID
		 , NULL AS DateProcessed
		 , 0 AS InsertCompleted
	FROM SLC_REPL.dbo.NobleFiles nf
	WHERE FileType = 'DDTRN'
	AND InStatus = 1
	AND NOT EXISTS (SELECT 1
					FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed fap
					WHERE nf.ID = fap.FileID)
	AND EXISTS (SELECT 1
				FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory th
				WHERE nf.ID = th.FileID)


/*******************************************************************************************************************************************
	2. Find all SkyMobile Service User Numbers (oins / OINs)
*******************************************************************************************************************************************/

	IF OBJECT_ID ('tempdb..#OINs') IS NOT NULL DROP TABLE #OINs
	SELECT OIN
	INTO #OINs
	FROM Relational.DirectDebit_MFDD_IncentivisedOINs
	WHERE PartnerID = 5555
	AND EndDate IS NULL

	CREATE CLUSTERED INDEX IDX_OIN ON #OINs (OIN)
	

/*******************************************************************************************************************************************
	3. Loop through the FileIDs and insert to temp table
*******************************************************************************************************************************************/

	DECLARE	@FileID INT

	TRUNCATE TABLE Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding
	
	WHILE EXISTS (SELECT 1 FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed WHERE InsertCompleted = 0)
	BEGIN
	
		SET @FileID = (SELECT MIN(FileID) FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed WHERE InsertCompleted = 0)

		INSERT INTO Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding (FileID
																			 , RowNum
																			 , OIN
																			 , Narrative
																			 , TranDate
																			 , Amount
																			 , ClubID
																			 , BankAccountID
																			 , SourceUID
																			 , FanID)
		SELECT dd.FileID
			 , dd.RowNum
			 , dd.OIN
			 , dd.Narrative
			 , dd.Date as TranDate
			 , dd.Amount
			 , dd.ClubID
			 , dd.BankAccountID
			 , dd.SourceUID
			 , dd.FanID
		FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
		WHERE FileID = @FileID
		AND EXISTS (SELECT 1
					FROM #OINs oin
					WHERE dd.OIN = oin.OIN)

		UPDATE Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed
		SET DateProcessed = GETDATE()
		  , InsertCompleted = 1
		  , RowCountInserted = @@ROWCOUNT
		WHERE FileID = @FileID

	END
	

/*******************************************************************************************************************************************
	3. Fill in missing customer IDs
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1. Fetch list of bank details for primary account holders -- update heading
	***********************************************************************************************************************/
		
		IF OBJECT_ID ('tempdb..#BankAccount') IS NOT NULL DROP TABLE #BankAccount
		SELECT DISTINCT
			   BankAccountID
		INTO #BankAccount
		FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding
		Where SourceUID IS NULL
		AND FanID IS NULL;

		CREATE UNIQUE CLUSTERED INDEX ucx_BankAccountID ON #BankAccount (BankAccountID);	
		
			
		IF OBJECT_ID ('tempdb..#IssuerBankAccount') IS NOT NULL DROP TABLE #IssuerBankAccount;
		WITH OrderedRows AS (SELECT iba.BankAccountID
							 	  , iba.CustomerStatus
							 	  , ic.ID as FirstCustomerID
							 	  , ROW_NUMBER() OVER (PARTITION BY iba.BankAccountID ORDER BY iba.CustomerStatus DESC, ic.ID ASC) AS CustomerPriority
							 FROM SLC_Report..IssuerBankAccount iba
							 INNER JOIN SLC_Report..IssuerCustomer ic
							 	ON iba.IssuerCustomerID = ic.ID
							 WHERE EXISTS (SELECT 1
							 			   FROM #BankAccount bai
							 			   WHERE bai.BankAccountID = iba.BankAccountID))

		SELECT BankAccountID
			 , CustomerStatus
			 , FirstCustomerID
		INTO #IssuerBankAccount
		FROM OrderedRows
		WHERE CustomerPriority = 1;

		CREATE CLUSTERED INDEX cx_IssuerBankAccount ON #IssuerBankAccount (FirstCustomerID);


	/***********************************************************************************************************************
		3.2. Link the previous bank account to a customer
	***********************************************************************************************************************/
	
		IF OBJECT_ID ('tempdb..#IssuerCustomer') IS NOT NULL DROP TABLE #IssuerCustomer
		SELECT iba.BankAccountID
			 , fa.ID as FanID
			 , fa.SourceUID
		INTO #IssuerCustomer
		FROM SLC_Report.dbo.Fan fa
		INNER JOIN SLC_Report.dbo.IssuerCustomer ic
			ON ic.SourceUID = fa.SourceUID
			AND ((fa.ClubID = 132 and ic.IssuerID = 2) or (fa.ClubID = 138 and ic.IssuerID = 1))
		INNER JOIN #IssuerBankAccount iba 
			ON iba.FirstCustomerID = ic.ID

		CREATE CLUSTERED INDEX cx_IssuerCustomer ON #IssuerCustomer (BankAccountID)


	/***********************************************************************************************************************
		3.3. Link the previous bank account to a customer
	***********************************************************************************************************************/

		UPDATE dd
		SET	dd.FanID = COALESCE(dd.FanID, fa.ID, ic.FanID)
		  , dd.SourceUID = COALESCE(dd.SourceUID, ic.SourceUID)
		FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding dd
		LEFT JOIN SLC_Report.dbo.Fan fa
			ON dd.SourceUID = fa.SourceUID
			AND dd.ClubID = fa.ClubID
		LEFT JOIN #IssuerCustomer ic
			ON ic.BankAccountID = dd.BankAccountID
		Where dd.SourceUID IS NULL
		OR dd.FanID IS NULL

		
/*******************************************************************************************************************************************
	4. Add any new Combinations
*******************************************************************************************************************************************/

	INSERT INTO Relational.ConsumerCombination_DD_Temp (OIN
												 , Narrative_RBS
												 , BrandID)
	SELECT DISTINCT
		   dd.OIN
		 , dd.Narrative AS Narrative_RBS
		 , 2674 AS BrandID
	FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding dd
	WHERE NOT EXISTS (SELECT 1
					  FROM Relational.ConsumerCombination_DD_Temp cc
					  WHERE dd.OIN = cc.OIN
					  AND dd.Narrative = cc.Narrative_RBS)

/*******************************************************************************************************************************************
	5. Insert to Direct Debit MIDI Holding Table
*******************************************************************************************************************************************/

	INSERT INTO Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD
	SELECT cc.ConsumerCombination_DirectDebitID
		 , dd.FileID
		 , dd.RowNum
		 , dd.OIN
		 , dd.Narrative
		 , dd.TranDate
		 , dd.Amount
		 , dd.ClubID
		 , dd.BankAccountID
		 , dd.SourceUID
		 , dd.FanID
	FROM Staging.CBP_DirectDebit_TransactionHistory_SkyMobile_DD_Holding dd
	INNER JOIN Relational.ConsumerCombination_DD_Temp cc
		ON dd.OIN = cc.OIN
		AND dd.Narrative = cc.Narrative_RBS



	/******************************************************************************
	****************Update entry in JobLog Table with End Date*********************
	******************************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) 
		AND TableSchemaName = 'Staging'
		AND TableName = 'MultipleTables' 
		AND EndDate IS NULL

	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = 0
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID)
		AND TableSchemaName = 'Staging'
		AND TableName = 'MultipleTables' 
		AND TableRowCount IS NULL


	INSERT INTO Staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM Staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

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