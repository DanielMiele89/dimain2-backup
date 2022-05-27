/*
	Author:			Stuart Barnley

	Date:			17-06-2015

	Purpose:		It was discovered that a group of customers were not being emailed because
					the hard bounced calculation was using data from archive light that was not
					being updated.

					This is taking a static set of data and checking if they hardbounced since, if
					not removing the hardbounced

*/

CREATE Procedure [Staging].[WarehouseLoad_Customer_HardbounceEmailChangePart2]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_CustomerHardbounceEmailChangePart2',
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'

	---------------------------------------------------------------------------------------------------
	----------- Take Static list who changed emails in early 2015 and check they are valid ------------
	---------------------------------------------------------------------------------------------------
	if object_id('tempdb..#ChangedEmailAddress') is not null drop table #ChangedEmailAddress
	select Distinct c.FaniD,DateChanged as EmailchangeDate
	Into #ChangedEmailAddress
	from staging.Customer_EmailAddressChanges_20150101 as eac
	inner join relational.customer as c
		on eac.FanID = c.FanID
	Where	hardbounced = 1 and 
			eac.email = c.email and
			CurrentlyActive = 1 and
			EmailStructureValid = 1 and
			c.Unsubscribed = 0
	---------------------------------------------------------------------------------------------------
	----------------------- Check if they have bounced since email address was changed ----------------
	---------------------------------------------------------------------------------------------------
	if object_id('tempdb..#BouncedSince') is not null drop table #BouncedSince
	Select distinct ee.FanID
	Into #BouncedSince
	from Relational.emailevent as ee
	inner join #ChangedEmailAddress as cea
		on ee.fanid = cea.fanid
	Where	EmailEventCodeID = 702 and
			ee.EventDate > cea.EmailchangeDate
	---------------------------------------------------------------------------------------------------
	--------------------------------------- Update Hardbounced Flag -----------------------------------
	---------------------------------------------------------------------------------------------------
	Update Relational.Customer
	Set Hardbounced = 0
	Where fanid in (
						Select cea.FanID 
						from #ChangedEmailAddress as cea
						left outer join #BouncedSince as bs
							on cea.fanid = bs.FanID
						Where bs.fanid is null
					)
	---------------------------------------------------------------------------------------------------
	------------------------------------- Update MarketableByEmail Flag -------------------------------
	---------------------------------------------------------------------------------------------------				
	Update Relational.Customer
	Set MarketableByEmail = 1
	Where	(	LaunchGroup is not null	or ActivatedDate >= 'Aug 08, 2013')	and				--not control
			CurrentlyActive = 1 and
			Unsubscribed = 0 and					 
   			Hardbounced = 0 and
			EmailStructureValid = 1 and
   			ActivatedOffline = 0 and 
			Len(Postcode) >= 3 and
			SourceUID not in (Select Distinct SourceUID from Staging.Customer_DuplicateSourceUID) and
			Marketablebyemail = 0
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_CustomerHardbounceEmailChangePart2' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null

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