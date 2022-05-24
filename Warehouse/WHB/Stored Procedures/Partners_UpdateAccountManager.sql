-- *******************************************************************************
-- Author: Rory Francis
-- Create date: 19/11/2018
-- Description: Updates the Account Manager field on the Partner Table. 
-- Update:		
-- *******************************************************************************
CREATE PROCEDURE [WHB].[Partners_UpdateAccountManager]
		
As
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/***********************************************************************************************************************
		1.	Write entry to JobLog Temp Table
	***********************************************************************************************************************/

		Insert into Staging.JobLog_Temp
		Select StoredProcedureName = OBJECT_NAME(@@PROCID)
			 , TableSchemaName = 'Relational'
			 , TableName = 'Partner'
			 , StartDate = GETDATE()
			 , EndDate = Null
			 , TableRowCount  = Null
			 , AppendReload = 'U'

	/***********************************************************************************************************************
		2.	Fetch current lists of account managers
	***********************************************************************************************************************/

		/*******************************************************************************************************************
			2.1. Fetch current partner details from [APW].[Retailer]
		*******************************************************************************************************************/

			IF OBJECT_ID('tempdb..#PartnerAccountManager') IS NOT NULL DROP TABLE #PartnerAccountManager
			SELECT *
			INTO #PartnerAccountManager
			FROM [Selections].[PartnerAccountManager]
			WHERE EndDate IS NULL


		/*******************************************************************************************************************
			2.2. Fetch partner details from [APW].[Retailer]
		*******************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#Retailer') IS NOT NULL DROP TABLE #Retailer
			SELECT *
			INTO #Retailer
			FROM [APW].[Retailer]
			WHERE AccountManager != ''	


	/***********************************************************************************************************************
		3.	Add missing retailers
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#MissingRetailer') IS NOT NULL DROP TABLE #MissingRetailer
		SELECT ID AS RetailerID
			 , RetailerName
			 , AccountManager
		INTO #MissingRetailer
		FROM [APW].[Retailer] re
		WHERE AccountManager != ''
		AND NOT EXISTS (SELECT 1
						FROM #PartnerAccountManager pam
						WHERE re.ID = pam.PartnerID)	
						
		INSERT INTO #MissingRetailer
		SELECT pa.ID
			 , pa.Name
			 , mr.AccountManager
		FROM #MissingRetailer mr
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON mr.RetailerID = pri.PrimaryPartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		WHERE NOT EXISTS (SELECT 1
						  FROM #PartnerAccountManager pam
						  WHERE pa.ID = pam.PartnerID)
	
		INSERT INTO [Selections].[PartnerAccountManager]
		SELECT RetailerID
			 , RetailerName
			 , AccountManager
			 , GETDATE()
			 , NULL
		FROM #MissingRetailer


	/***********************************************************************************************************************
		4.	Update retailers who have changed AM
	***********************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#UpdatedAccountManagers') IS NOT NULL DROP TABLE #UpdatedAccountManagers
		SELECT pam.ID
			 , r.ID AS RetailerID
			 , r.RetailerName AS RetailerName
			 , pam.AccountManager AS CurrentAccountManager
			 , r.AccountManager AS NewAccountManager
		INTO #UpdatedAccountManagers
		FROM #Retailer r
		INNER JOIN #PartnerAccountManager pam
			ON pam.PartnerID = r.ID
			AND r.AccountManager != pam.AccountManager
		WHERE r.AccountManager != 'Nick'
		AND r.AccountManager != 'Nick / Tom'

		INSERT INTO #UpdatedAccountManagers
		SELECT pam.ID
			 , pa.ID
			 , pa.Name
			 , uam.CurrentAccountManager
			 , uam.NewAccountManager
		FROM #UpdatedAccountManagers uam
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON uam.RetailerID = pri.PrimaryPartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		INNER JOIN #PartnerAccountManager pam
			ON pa.ID = pam.PartnerID

		UPDATE pam
		SET EndDate = DATEADD(DAY, -1, GETDATE())
		FROM [Selections].[PartnerAccountManager] pam
		INNER JOIN #UpdatedAccountManagers uam
			ON pam.ID = uam.ID
	
		INSERT INTO [Selections].[PartnerAccountManager]
		SELECT RetailerID
			 , RetailerName
			 , NewAccountManager
			 , GETDATE()
			 , NULL
		FROM #UpdatedAccountManagers

	/***********************************************************************************************************************
		5.	Update the Relational.Partner table, setting AccountManager to Unassigned where no entry is found
	***********************************************************************************************************************/

		Update pa
		Set pa.AccountManager = Case
									When am.AccountManager Is Null Then 'Unassigned'
									Else am.AccountManager
								End
		From Relational.Partner pa
		Left join #PartnerAccountManager am
			on pa.PartnerID = am.PartnerID


	/***********************************************************************************************************************
		6.	Update entry to JobLog Temp Table
	***********************************************************************************************************************/

		/*******************************************************************************************************************
			6.1.	Update entry to JobLog Temp Table - Execution time
		*******************************************************************************************************************/

			Update Staging.JobLog_Temp
			Set EndDate = GetDate()
			Where StoredProcedureName = OBJECT_NAME(@@PROCID) 
			And TableSchemaName = 'Relational'
			And TableName = 'Partner' 
			And EndDate Is Null


		/*******************************************************************************************************************
			6.2.	Update entry to JobLog Temp Table - Row count
		*******************************************************************************************************************/

			Update Staging.JobLog_Temp
			Set TableRowCount = (Select Count(1) From Relational.Partner)
			Where StoredProcedureName = OBJECT_NAME(@@PROCID) 
			And TableSchemaName = 'Relational'
			And TableName = 'Partner' 
			And TableRowCount Is Null


	/***********************************************************************************************************************
		7.	Insert entry to JobLog Table
	***********************************************************************************************************************/

		Insert into Staging.JobLog
		Select StoredProcedureName
			 , TableSchemaName
			 , TableName
			 , StartDate
			 , EndDate
			 , TableRowCount
			 , AppendReload
		From Staging.JobLog_Temp

		Truncate Table Staging.JobLog_Temp

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

End