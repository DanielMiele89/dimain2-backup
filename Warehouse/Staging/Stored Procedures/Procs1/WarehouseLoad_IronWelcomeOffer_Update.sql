/*

	Author:		Stuart Barnley

	Date:		5th August 2016

	Purpose:	To update Welcome Offers table to check all entries are as expected

*/

CREATE Procedure [Staging].[WarehouseLoad_IronWelcomeOffer_Update]
--With Execute as Owner
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_IronWelcomeOffer_Update',
			TableSchemaName = 'Iron',
			TableName = 'WelcomeOffer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'D'

	Declare @Rows int

	Set @Rows = (Select Count(*) From iron.WelcomeOffer)

	/*--------------------------------------------------------------------------------------------------
	------------------------------------- Count existing rows ------------------------------------------
	----------------------------------------------------------------------------------------------------*/		

	if object_id('tempdb..#OffersForRemoval') is not null drop table #OffersForRemoval
	select	wo.IronOfferID
	Into #OffersForRemoval
	From iron.WelcomeOffer as wo
	inner join SLC_Report.dbo.IronOffer as i
		on wo.IronOfferID = i.ID
	Where	Cast(i.enddate as date) <= Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0) or
			i.IsSignedOff = 0 or
			i.IsDefaultCollateral = 1 or
			--i.StartDate >= Dateadd(day,DATEDIFF(dd, 0, GETDATE())+5,0) or
			i.IsAppliedToAllMembers =1

	/*--------------------------------------------------------------------------------------------------
	------------------------------------- Count existing rows ------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Delete from iron.WelcomeOffer
	Where ironofferid in (Select IronOfferID from #OffersForRemoval)

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_IronWelcomeOffer_Update' and
			TableSchemaName = 'Iron' and
			TableName = 'WelcomeOffer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select @Rows - COUNT(*) from iron.WelcomeOffer)
	where	StoredProcedureName = 'WarehouseLoad_IronWelcomeOffer_Update' and
			TableSchemaName = 'Iron' and
			TableName = 'WelcomeOffer' and
			TableRowCount is null
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp

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