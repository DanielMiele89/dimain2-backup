/*
Author:			Suraj Chahal	
Date:			22nd March 2013
Purpose:		This is used to update specific records where there is a problem with the record that is NOT
				appropriate to fix on GAS
Notes:			Such as Control records processed late against offers that have no impact to GAS or Invoicing 
				but impact reporting

Update:			This version is being amended for use as a stored procedure and to be ultimately automated.
				
				14-02-2014 SB - This version is being amended to stop correcting control group transactions
								as they are no longer loaded
				20-02-2014 SB - Removed reference to Warehouse in joins
				28-03-2014 SB - Correct Cineworld Transactions to use file added date as records amended and
								Added date changed by mistake in live system
*/
CREATE PROCEDURE [WHB].[IronOfferPartnerTrans_Corrections_V1_7]
AS 
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @PT_Count int,@Cust_Count int

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Calculate Amended Rows-------------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Set @Cust_Count = (Select COUNT(*) 
					   from		staging.Customer as c
					   Where	c.LaunchGroup In ('Init','STF1','STF2') and 
								c.Status = 1 and ----------------Customer is still active on the scheme
								c.EmailStructureValid = 1 and ---Email address is valid
								MarketableByEmail = 0	)
							
							
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = @Cust_Count
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			TableRowCount is null
		
		
	-----------------------------------------------------------------------------------------------------------------------------------
	------------------------------Update MarketableByEmail for SEED records that have unsubscribed-------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------
	--***********************This section will update the staging version of the table***********************--
	Update staging.Customer
	Set		MarketableByEmail = 1 -----------Update MarketableByEmail which makes it selectable for campaigns
	from	staging.Customer as c
	Where	c.LaunchGroup In ('Init','STF1','STF2') and 
			c.Status = 1 and ----------------Customer is still active on the scheme
			c.EmailStructureValid = 1 and ---Email address is valid
			MarketableByEmail = 0 -----------Check they are currently not emailable
		
		
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			EndDate is null
			
		
		
		
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'
		
		
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = @Cust_Count
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			TableRowCount is null
		

		
		
		

	--***********************This section will update the relational version of the table***********************--
	Update Relational.Customer
	Set		MarketableByEmail = 1 -----------Update MarketableByEmail which makes it selectable for campaigns
	from	Relational.Customer as c
	Where	c.LaunchGroup in ('Init','STF1','STF2') and 
			c.Status = 1 and ----------------Customer is still active on the scheme
			c.EmailStructureValid = 1 and ---Email address is valid
			MarketableByEmail = 0 -----------Check they are currently not emailable


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Insert into staging.JobLog_temp
	--Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
	--		TableSchemaName = 'Staging',
	--		TableName = 'PartnerTrans',
	--		StartDate = GETDATE(),
	--		EndDate = null,
	--		TableRowCount  = null,
	--		AppendReload = 'C'
	--/*--------------------------------------------------------------------------------------------------
	-------------------------------Create table to use for Cinworld Corrections---------------------------
	------------------------------------------------------------------------------------------------------*/
	----Only run the first time - This takes the MatchIDs and works out the file they imported in, then 
	----find the date the file was imported 

	--/*
	--	use warehouse
	--	Select	pt.MatchID,
	--			Cast(nf.InDate as date) as AddedDate
	--	Into Warehouse.Staging.Correction_Cineworld
	--	from  Relational.PartnerTrans as pt
	--	inner join staging.MatchCardHolderPresent as mchp
	--		on pt.matchid = mchp.MatchID
	--	inner join slc_report.dbo.NobleFiles as nf
	--		on mchp.fileid = nf.id
	--	where	addeddate = 'Feb 21, 2014' and 
	--			transactiondate <= 'Jan 5, 2014' and 
	--			partnerid = 2365
	--	Order by CashbackEarned/Transactionamount

	--	Select * 
	--	into Warehouse.Staging.Correction_Cineworld
	--	from #ptCorrections
	--*/

	--/*--------------------------------------------------------------------------------------------------
	-------------------------------Update Staging.PartnerTrans with corrections---------------------------
	------------------------------------------------------------------------------------------------------*/
	----Updates Staging.PartnerTrans by changing the Added Date to that of the File imported date

	--Update	Staging.PartnerTrans
	--Set		AddedDate = a.AddedDate
	--from	Staging.PartnerTrans as pt
	--inner join Staging.Correction_Cineworld as a
	--	on pt.matchid = a.matchid

	--/*--------------------------------------------------------------------------------------------------
	-----------------------------Update entry in JobLog Table with End Date-------------------------------
	------------------------------------------------------------------------------------------------------*/
	--Update  staging.JobLog_Temp
	--Set		EndDate = GETDATE()
	--where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
	--		TableSchemaName = 'Staging' and
	--		TableName = 'PartnerTrans' and
	--		EndDate is null
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	------------------------------------------------------------------------------------------------------*/
	--Insert into staging.JobLog_temp
	--Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
	--		TableSchemaName = 'Relational',
	--		TableName = 'PartnerTrans',
	--		StartDate = GETDATE(),
	--		EndDate = null,
	--		TableRowCount  = null,
	--		AppendReload = 'C'
	--/*--------------------------------------------------------------------------------------------------
	-------------------------------Update Relational.PartnerTrans with corrections---------------------------
	------------------------------------------------------------------------------------------------------*/
	----Updates Relational.PartnerTrans by changing the Added Date to that of the File imported date
	--Update	Relational.PartnerTrans
	--Set		AddedDate = a.AddedDate
	--from	Relational.PartnerTrans as pt
	--inner join Staging.Correction_Cineworld as a
	--	on pt.matchid = a.matchid

	--/*--------------------------------------------------------------------------------------------------
	-----------------------------Update entry in JobLog Table with End Date-------------------------------
	------------------------------------------------------------------------------------------------------*/
	--Update  staging.JobLog_Temp
	--Set		EndDate = GETDATE()
	--where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
	--		TableSchemaName = 'Relational' and
	--		TableName = 'PartnerTrans' and
	--		EndDate is null
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RecordCount int
	Set @RecordCount = (Select Count(*) from Relational.Customer as c where c.MarketableByEmail = 1 and c.SourceUID in (Select SourceUID  from Staging.Customer_DuplicateSourceUID))

	Update Relational.Customer
	Set   MarketableByEmail = 0
	Where MarketableByEmail = 1 and 
		  SourceUID in (Select SourceUID  from Staging.Customer_DuplicateSourceUID)
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		[TableRowCount] = @RecordCount
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is not null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'PartnerTrans',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'C'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Populate PartnerTrans AboveBase field----------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update rpt
	Set rpt.AboveBase = 0
	FROM Relational.Partnertrans rpt
	Where rpt.AboveBase is null
	AND Cast(rpt.CashbackEarned as real) / rpt.TransactionAmount Between -.0125 and .0125
	AND EXISTS (SELECT 1
				FROM [Staging].[PartnerTrans] spt
				WHERE rpt.MatchID = spt.MatchID)


	Update rpt
	Set AboveBase = 0
	From	Relational.PartnerTrans as rpt
	inner join [Relational].[Partner_NonCoreBaseOffer] as n
		on rpt.IronOfferID = n.IronOfferID
	WHERE EXISTS (	SELECT 1
					FROM [Staging].[PartnerTrans] spt
					WHERE rpt.MatchID = spt.MatchID)

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'PartnerTrans' and
			EndDate is null


	Insert into Staging.JobLog
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

END

