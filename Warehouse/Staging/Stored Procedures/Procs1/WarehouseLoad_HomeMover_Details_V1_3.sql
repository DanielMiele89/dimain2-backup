
/*
Author:		Suraj Chahal
Date:		11th March 2013
Purpose:	To record the address information of those people that we have been informed by RBSG have moved and
		make this available to users of the Warehouse
			
Notes:		Although this data is already being apended to a staging table I thought it wise (while record counts
		are low) to create a new table and to store the whole of the old address.
		
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_HomeMover_Details_V1_3]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @PT_Count int
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3',
			TableSchemaName = 'Staging',
			TableName = 'HomeMover_Details',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Calculate Amended Rows-------------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Set @PT_Count = (Select COUNT(*) 
					 From Staging.Homemover as h
					 Inner join staging.Customer as c
							on h.FanID = c.FanID
					 Left join Staging.Homemover_Details as HD
							on h.FanID = hd.FanID 
							and h.LoadDate = hd.LoadDate
							and h.NewPostCode = hd.NewPostCode
							and h.OldPostCode = hd.OldPostCode
					 Where hd.FanID Is Null)

	--------------------------------------------------------------------------------------------
	----------------------Add new records to HomeMover_Details staging table -------------------
	--------------------------------------------------------------------------------------------
	--This pulls through the address data for anyone that has had there postcode changed since last run
	Insert into Staging.Homemover_Details
	Select h.FanID
		 , h.OldPostcode
		 , h.NewPostCode
		 , h.LoadDate
		 , c.Address1 as OldAddress1
		 , c.Address2 as OldAddress2
		 , c.City as OldCity
		 , c.County as OldCounty
	From Staging.Homemover as h
	Inner join Staging.Customer as c
		on h.FanID = c.FanID
	Left join Staging.Homemover_Details as hd
		on h.FanID = hd.FanID
		and h.LoadDate = hd.LoadDate
		and h.NewPostCode = hd.NewPostCode
		and h.OldPostCode = hd.OldPostCode
	Where hd.FanID Is Null
	And Not (Right(h.OldPostCode, 3) = Right(h.NewPostCode, 3)	--	Added to deal with Partial Postcodes being fully populated
			 And Len(h.OldPostCode) < 5
			 And Len(h.NewPostCode) > 4)
	And Not (Len(h.OldPostCode) < 5	--	Added as Nirupam advised do not include anyone where old postcode < 4 characters long
			 Or h.OldPostCode Is Null)
			

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3' and
			TableSchemaName = 'Staging' and
			TableName = 'HomeMover_Details' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = @PT_Count
	where	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3' and
			TableSchemaName = 'Staging' and
			TableName = 'HomeMover_Details' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3',
			TableSchemaName = 'Relational',
			TableName = 'HomeMover_Details',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'


	--------------------------------------------------------------------------------------------
	------------------------Create new HomeMover_Details Relational table ----------------------
	--------------------------------------------------------------------------------------------
	ALTER INDEX IDX_FanID ON Relational.Homemover_Details DISABLE


	Truncate table Relational.Homemover_Details

	Insert into relational.Homemover_Details
	Select * 
	From Staging.Homemover_Details


	ALTER INDEX IDX_FanID ON Relational.Homemover_Details REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3' and
			TableSchemaName = 'Relational' and
			TableName = 'HomeMover_Details' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.Homemover_Details)
	where	StoredProcedureName = 'WarehouseLoad_HomeMover_Details_V1_3' and
			TableSchemaName = 'Relational' and
			TableName = 'HomeMover_Details' and
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

	Truncate Table staging.JobLog_Temp

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


