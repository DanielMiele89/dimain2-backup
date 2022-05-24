CREATE PROCEDURE [WHB].[Customer_EmailChange1_RF]
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


/*******************************************************************************************************************************************
	1.	Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT StoredProcedureName = OBJECT_NAME(@@PROCID)
		 , TableSchemaName = 'Staging'
		 , TableName = 'Customer_EmailAddressLastChanged'
		 , StartDate = GETDATE()
		 , EndDate = NULL
		 , TableRowCount  = NULL
		 , AppendReload = 'A'
	
	
/*******************************************************************************************************************************************
	2.	Identify customers that have had their email updated by comparing the results of the previous day's population of the Customer
		table to each customers current data
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#EmailAddressChanged') IS NOT NULL DROP TABLE #EmailAddressChanged
	SELECT fa.ID AS FanID
		 , cu.Email AS PreviousEmail
		 , fa.Email AS UpdatedEmail
		 , ActivatedDate
	INTO #EmailAddressChanged
	FROM [SLC_Report].[dbo].[Fan] fa
	INNER JOIN [Relational].[Customer] cu
		ON fa.ID = cu.FanID
	WHERE cu.Email != fa.Email

	
/*******************************************************************************************************************************************
	3.	If a customer has updated their email address to a non-blank value that is different to their lastest non-blank email address
		then update the table with the hashed value of the address they have updated to and todays date
*******************************************************************************************************************************************/

	DECLARE @Today DATE = GETDATE()
		  , @RowCount INT = 0

	UPDATE ealc
	SET ealc.DateChanged = @Today
	  , ealc.HashedEmail = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', LOWER(eac.UpdatedEmail)), 2)
	FROM #EmailAddressChanged eac
	INNER JOIN [Staging].[Customer_EmailAddressLastChanged] ealc
		ON eac.FanID = ealc.FanID
	WHERE eac.UpdatedEmail != ''
	AND CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', LOWER(eac.UpdatedEmail)), 2) != ealc.HashedEmail

	SET @RowCount = @RowCount + @@ROWCOUNT


/*******************************************************************************************************************************************
	4.	Insert customers that have joined or that have added their email address for the first time	
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[Customer_EmailAddressLastChanged]
	SELECT eac.FanID
		 , CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', LOWER(eac.Email)), 2) AS HashedEmail
		 , @Today AS DateChanged
	FROM [Relational].[Customer] eac
	WHERE eac.Email != ''
	AND NOT EXISTS (SELECT 1
					FROM [Staging].[Customer_EmailAddressLastChanged] ealc
					WHERE eac.FanID = ealc.FanID)

	SET @RowCount = @RowCount + @@ROWCOUNT


/*******************************************************************************************************************************************
	5.	Update the JobLog table
*******************************************************************************************************************************************/

	UPDATE [Staging].[JobLog_temp]
	SET EndDate = GETDATE()
	  , TableRowCount = @RowCount
	WHERE StoredProcedureName = OBJECT_NAME(@@PROCID) 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Customer_EmailAddressLastChanged' 
	AND EndDate IS NULL

	INSERT INTO [Staging].[JobLog]
	SELECT StoredProcedureName
		 , TableSchemaName
		 , TableName
		 , StartDate
		 , EndDate
		 , TableRowCount
		 , AppendReload
	FROM [Staging].[JobLog_temp]

	TRUNCATE TABLE [Staging].[JobLog_temp]

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