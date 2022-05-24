
CREATE Procedure [Staging].[WarehouseLoad_DailyAboveBaseOffersV1_1]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select		StoredProcedureName = 'WarehouseLoad_DailyAboveBaseOffersV1',
			TableSchemaName = 'Relational',
			TableName = 'Partner_AboveBaseOffers_PerDay',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'



	Declare @StartDate datetime
	Set @StartDate = 'Jan 01, 2013'
	Truncate Table Relational.Partner_AboveBaseOffers_PerDay
	While @StartDate <= Cast(GetDate() as date)
	Begin
		Insert into Relational.Partner_AboveBaseOffers_PerDay
		select Distinct		
				@StartDate	as DayDate,
				p.PartnerID as PartnerID,
				Max(Case
						When i.Partnerid is null then 0
						when  i.AboveBase is null then 0
						Else AboveBase
					End)as AboveBaseOffer
		from relational.Partner as p
		Left Outer join relational.IronOffer as i
			on	p.PartnerID = i.PartnerID and
				@StartDate between i.StartDate and i.EndDate and 
				i.Abovebase = 1 and i.IsTriggerOffer = 0 and i.ironofferName <> '(Demo) special offer'
		Group by p.PartnerID
	
		Set @StartDate = Dateadd(day,1,@StartDate)
	End

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_DailyAboveBaseOffersV1' and
			TableSchemaName = 'Relational' and
			TableName = 'Partner_AboveBaseOffers_PerDay' and
			EndDate is null
		
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set	TableRowCount = (Select COUNT(*) from Relational.Partner_AboveBaseOffers_PerDay)
	where	StoredProcedureName = 'WarehouseLoad_DailyAboveBaseOffersV1' and
			TableSchemaName = 'Relational' and
			TableName = 'Partner_AboveBaseOffers_PerDay' and
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