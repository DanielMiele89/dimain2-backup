
CREATE Procedure [Staging].[WarehouseLoad_Customer_MarketableByEmailStatus_MI]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	truncate table staging.JobLog_Temp
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_MarketableByEmailStatus_MI',
			TableSchemaName = 'Relational',
			TableName = 'Customer_MarketableByEmailStatus_MI',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Count Rows in Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RowCount int
	Set @RowCount = (Select Count(*) from Relational.Customer_MarketableByEmailStatus_MI)
	/*--------------------------------------------------------------------------------------------------
	-----------------------Create initial list of customer marketing preferences------------------------
	----------------------------------------------------------------------------------------------------*/

	Declare @MaxFanID int,@Chunksize int,@FanID int
	Set @MaxFanID = (Select Max(FanID) from Relational.Customer as c)
	Set @ChunkSize = 250000
	Set @FanID = 0

	Create Table #Cust (FanID int, MarketableByEmail tinyint,Primary Key (FanID))

	While @FanID < @MaxFanID
	Begin
		Insert into #Cust
		Select	Top (@ChunkSize)
				FanID,
				Case
					When CurrentlyActive = 0 then 3
					When MarketableByEmail = 1 then 1
					When Hardbounced = 1 then 3
					When EmailStructureValid = 0 then 3
				Else 2
				End as MarketableByEmail
		from Relational.Customer as c
		Where FanID > @FanID
		Order by FanID

		Set @FanID = (Select Max(FanID) from #Cust)
	End
	/*--------------------------------------------------------------------------------------------------
	--------------------------------------------End Date old Entries------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update Relational.Customer_MarketableByEmailStatus_MI
	Set EndDate = dateadd(day,-1,Cast(getdate()as date))
	from #Cust as c
	inner join Relational.Customer_MarketableByEmailStatus_MI as m
		on	c.fanid = m.fanid and
			m.EndDate is null and
			m.MarketableID <> c.MarketableByEmail
	/*--------------------------------------------------------------------------------------------------
	--------------------------------------------Create New Entries------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into Relational.Customer_MarketableByEmailStatus_MI
	Select	c.FanID,
			c.MarketableByEmail,
			StartDate = Cast(getdate()as date),
			EndDate = Cast(Null as date)
	from #Cust as c
	Left Outer join Relational.Customer_MarketableByEmailStatus_MI as m
		on	c.fanid = m.fanid and
			m.EndDate is null and
			m.MarketableID = c.MarketableByEmail
	Where m.Fanid is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_MarketableByEmailStatus_MI' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_MarketableByEmailStatus_MI' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.Customer_MarketableByEmailStatus_MI)-@RowCount
	where	StoredProcedureName = 'WarehouseLoad_Customer_MarketableByEmailStatus_MI' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_MarketableByEmailStatus_MI' and
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