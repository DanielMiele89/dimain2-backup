/*
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the Outlet first in the Staging and then Relational schema of 
		the Warehouse database
Notes:		
Update:		09/09/2014 - Removed Index DROP as now table has OutletID as it's PRIMARY KEY
			
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_Outlet_V1_5]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5',
		TableSchemaName = 'Staging',
		TableName = 'Outlet',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

	/*--------------------------------------------------------------------------*/
	/*--------------Extract Data from SLC_Report - Outlet-----------------------*/
	/*--------------------------------------------------------------------------*/
	--if object_id('staging.Outlet') is not null drop table staging.Outlet
	--Delete From staging.Outlet
	Truncate Table staging.Outlet
	Insert into	staging.Outlet
	select	ro.ID as OutletID,
			ro.PartnerID,
			ro.MerchantID,
			ro.Channel,					--1 = Online, 2 = Offline
			LTRIM(RTRIM(f.Address1))				as Address1,
			LTRIM(RTRIM(f.Address2))				as Address2,
			LTRIM(RTRIM(f.City))					as City,		
			LEFT(ltrim(rtrim(f.PostCode)),10)				as Postcode,
			Cast(Null as varchar(6))				as PostalSector,
			Cast(Null as varchar(2))				as PostArea,
			Cast(Null as varchar(30))				as Region,
			Cast(null as bit)						as IsOnline
	from	SLC_Report.dbo.RetailOutlet ro with (nolock)
			left join SLC_Report.dbo.Fan f with (nolock) on ro.FanID = f.ID
			inner join relational.Partner p with (nolock) on ro.PartnerID = p.PartnerID


	/*--------------------------------------------------------------------------*/
	/*--------------Enhance Data in Staging - Start - Outlet--------------------*/
	/*--------------------------------------------------------------------------*/
	update staging.Outlet
	set	PostalSector =	
				Case
					When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]' Then
						 Left(replace(replace(PostCode,char(160),''),' ',''),2)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),3),1)
					When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]' or
						 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]' or 
						 replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]' Then 
						 Left(replace(replace(PostCode,char(160),''),' ',''),3)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),4),1)
					When replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' or
						 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'Then 
						 Left(replace(replace(PostCode,char(160),''),' ',''),4)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),5),1)
					Else ''
				End,
		PostArea =		
				case 
					when PostCode like '[A-Z][0-9]%' then left(PostCode,1) 
					else left(PostCode,2) 
				end,
		IsOnline =		
				case 
					when Channel = 1 then 1 
					else 0 
				end		--Channel = 1 represents an online outlet

	update	staging.Outlet
	set		staging.Outlet.Region = Staging.PostArea.Region
	from	staging.Outlet inner join Staging.PostArea on staging.Outlet.PostArea = Staging.PostArea.PostAreaCode


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5' and
			TableSchemaName = 'Staging' and
			TableName = 'Outlet' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.Outlet)
	where	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5' and
			TableSchemaName = 'Staging' and
			TableName = 'Outlet' and
			TableRowCount is null


	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5',
		TableSchemaName = 'Relational',
		TableName = 'Outlet',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
	
	/*--------------------------------------------------------------------------*/
	/*--------------Build final tables in relational schema - Outlet -----------*/
	/*--------------------------------------------------------------------------*/	

	--if object_id('Relational.Outlet') is not null drop table Relational.Outlet
	--Delete from Relational.Outlet

	TRUNCATE TABLE Relational.Outlet

	INSERT INTO Relational.Outlet
	SELECT	OutletID,
		IsOnline,
		MerchantID,
		PartnerID,
		Address1,
		Address2,
		City,
		PostCode,
		PostalSector,
		PostArea,
		Region
	FROM	Staging.Outlet WITH (NOLOCK)


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5' and
			TableSchemaName = 'Relational' and
			TableName = 'Outlet' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.Outlet)
	where	StoredProcedureName = 'WarehouseLoad_Outlet_V1_5' and
			TableSchemaName = 'Relational' and
			TableName = 'Outlet' and
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

END