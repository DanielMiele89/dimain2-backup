/*
Author:		Stuart Barnley
Date:		29th November 2013
Purpose:	Smartfocus has its own unsubscribe list which is stored in the table Warehouse.Relational.SmartFocusUnsubscribes
			
			This stored procedure is updating the MarketableByEmail flag in the customer to reflect this data

Notes:		******* In the long term this should be done as part of the customer table creation stored procedure *******
			SB - 20/01/2014 - Amended to make sure unsubscribe is ticked as well MarketableByEmail = 0

*/			
CREATE Procedure [Staging].[WarehouseLoad_Customer_SmartFocusUnsubscribes_V1_3]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_SmartFocusUnsubscribes_V1_3',
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'
	/*--------------------------------------------------------------------------------------------------
	---------------------------------Find customer records to be updated--------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Deactivations') is not null drop table #Deactivations
	Select Distinct c.fanid
	Into #Deactivations
	from relational.customer as c
	inner join Relational.SmartFocusUnsubscribes as sfu
		on c.fanid = sfu.fanid and c.email = sfu.email 
	Where sfu.enddate is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------------------update customer records------------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Update MarketablebyEmailFlag
	Update relational.customer
	Set MarketableByEmail = 0
	Where fanid in (select fanid from #deactivations) and MarketableByEmail = 1

	Update relational.customer
	Set Unsubscribed = 1
	Where fanid in (select fanid from #deactivations) and Unsubscribed = 0

	/*--------------------------------------------------------------------------------------------------
	---------------------------------Find customer records to be updated--------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Deact2') is not null drop table #Deact2
	Select -- Distinct 
		c.fanid
	Into #Deact2
	from relational.customer as c
	inner join [Relational].[SmartFocusExclusions_NonUnsubscribes] as sfu
		on c.fanid = sfu.fanid
	Where c.MarketableByEmail = 1

	CREATE CLUSTERED INDEX cx_Stuff ON #Deact2 (fanid) -- CJM 20180312

	/*--------------------------------------------------------------------------------------------------
	-----------------------------------------update customer records------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Update relational.customer
	Set MarketableByEmail = 0
	Where fanid in (select fanid from #Deact2)
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------------update customer records------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Exec [Staging].[WarehouseLoad_Customer_SmartFocusUnsubscribes_Part2]

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Update entry in JobLog Table with enddate------------------------------
	----------------------------------------------------------------------------------------------------*/

	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_SmartFocusUnsubscribes_V1_3' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from #Deactivations)+(Select COUNT(*) from #Deact2)
	where	StoredProcedureName = 'WarehouseLoad_Customer_SmartFocusUnsubscribes_V1_3' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			TableRowCount is null

	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp
	truncate table staging.JobLog_Temp

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