/*
	Author:			Stuart Barnley
	Date:			31-03-2014
	Description:	This Stored procedure is made to update daily the Sandy group to populate the CinIDs
*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_SchemeMembershipV1_1]

As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_SchemeMembership',
			TableSchemaName = 'Relational',
			TableName = 'Customer_SchemeMembership',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
		
	Declare @RowNumber int
	Set @RowNumber = (Select COUNT(*) from Relational.Customer_SchemeMembership)
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Find each customers Scheme Membership type-----------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#SMT') is not null drop table #SMT
	Select	c.FanID,
			Case
				When c.CurrentlyActive = 0 then 8
				When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (2) then 1
				When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (0) then 3
				When dd.OnTrial = 1 then 3
				When cp.PaymentMethodsAvailableID in (0) then 4
				When cp.PaymentMethodsAvailableID in (1) then 5
				When cp.PaymentMethodsAvailableID in (2) then 2
				When cp.PaymentMethodsAvailableID in (3) then 4
				Else null
			End as SchemeMembershipTypeID,
			ActivatedDate,
			DeactivatedDate
	Into #SMT
	From Relational.Customer as c
	inner join Relational.CustomerPaymentMethodsAvailable as cp
		on	c.FanID = cp.FanID and
			cp.EndDate is null
	left outer join SLC_Report.[dbo].[FanSFDDailyUploadData_DirectDebit] as dd
		on c.FanID = dd.FanID

	/*--------------------------------------------------------------------------------------------------
	-----------------Close off existing records in Relational.Customer_SchemeMembership-----------------
	----------------------------------------------------------------------------------------------------*/
	Update #SMT
	Set SchemeMembershipTypeID = 
				(Case
					When b.SchemeMembershipTypeID in (1,2,5) then 6
					When b.SchemeMembershipTypeID in (3,4) then 7
					Else b.SchemeMembershipTypeID
				 End)
				
	From #SMT as b
	inner join Staging.SLC_Report_DailyLoad_Phase2DataFields as a
			on b.FanID = a.FanID
	Where	a.LoyaltyAccount = 1 and
				b.SchemeMembershipTypeID in (1,2,3,4,5)
	--Group by SchemeMembershipTypeID
	/*--------------------------------------------------------------------------------------------------
	-----------------Close off existing records in Relational.Customer_SchemeMembership-----------------
	----------------------------------------------------------------------------------------------------*/
	Update Relational.Customer_SchemeMembership
	Set EndDate = Case
						When DeactivatedDate = Cast(getdate() as date) then Dateadd(day,-1,CAST(getdate() as Date))
						Else Dateadd(day,-2,CAST(getdate() as Date))
					End
	from #SMT as smt
	inner join Relational.Customer_SchemeMembership as cs
		on smt.FanID = cs.FanID
	Where	smt.SchemeMembershipTypeID <> cs.SchemeMembershipTypeID and
			cs.EndDate is null
	/*--------------------------------------------------------------------------------------------------
	-------------------Create new entries in Relational.Customer_SchemeMembership-----------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into Relational.Customer_SchemeMembership
	Select	smt.FanID,
			smt.SchemeMembershipTypeID,
			Case
				When ActivatedDate = CAST(getdate() as Date) then CAST(getdate() as Date)
				Else dateadd(day,-1,CAST(getdate() as Date))
			End as StartDate,
			CAST(NULL as Date) as EndDate
	from #SMT as smt
	Left Outer join Relational.Customer_SchemeMembership as cs
		on	smt.FanID = cs.FanID and
			smt.SchemeMembershipTypeID = cs.SchemeMembershipTypeID and
			cs.EndDate is null
	Where cs.FanID is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_SchemeMembership' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_SchemeMembership' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = ((Select COUNT(1) from Relational.Customer_SchemeMembership))-@RowNumber
	where	StoredProcedureName = 'WarehouseLoad_Customer_SchemeMembership' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_SchemeMembership' and
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