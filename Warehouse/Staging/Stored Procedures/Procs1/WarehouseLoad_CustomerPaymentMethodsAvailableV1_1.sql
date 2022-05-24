CREATE Procedure [Staging].[WarehouseLoad_CustomerPaymentMethodsAvailableV1_1]
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
	Select	StoredProcedureName = 'WarehouseLoad_CustomerPaymentMethodsAvailableV1_1',
			TableSchemaName = 'Relational',
			TableName = 'CustomerPaymentMethodsAvailable',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	/*--------------------------------------------------------------------------------------------------
	-------------------------------------Row Count - Pre Insert-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RowCount int

	Set @RowCount = (Select Count(*) from Relational.CustomerPaymentMethodsAvailable)
	/*--------------------------------------------------------------------------------------------------
	-------------------------------Find PaymentMethods Available per Customer---------------------------
	----------------------------------------------------------------------------------------------------*/

	if object_id('tempdb..#CardTypes') is not null drop table #CardTypes
	Select FanID,
			Case
				When IsCredit = 1 and IsDebit = 1 then 2 -- Both
				When IsCredit = 1 then 1 -- Credit Only
				When IsDebit =  1 then 0 -- Debit Only
				Else 3 -- No Active Cards
			End as PaymentMethodsAvailableID
	INTO #CardTypes
	From
	(SELECT	c.FanID,
			Cast(coalesce(Max(Case
							When CardTypeID = 1 then 1
							Else 0
						 End),0) as bit) as IsCredit,
			Cast(Coalesce(Max(Case
							When CardTypeID = 2 then 1
							Else 0
						 End),0) as bit) as IsDebit

	FROM Relational.Customer as c with (nolock)
	Left Outer Join SLC_Report..Pan p with (nolock)
			on	c.CompositeID = p.CompositeID and 
				p.RemovalDate IS NULL
	Left Outer JOIN SLC_Report..PaymentCard pc WITH (NOLOCK)
			ON p.PaymentCardID = pc.ID
	Group by c.FanID
	) as a

	--Select PaymentMethodsAvailableID ,Count(*)
	--from #cardTypes
	--Group by PaymentMethodsAvailableID
	---------------------------------------------------------------------------------------
	-----------------------Close any no longer valid entries-------------------------------
	---------------------------------------------------------------------------------------
	Update Relational.CustomerPaymentMethodsAvailable
	set EndDate = Dateadd(day,-1,CAST(getdate() as DATE))
	from Relational.CustomerPaymentMethodsAvailable as cpm
	inner join #CardTypes as ct
		on	cpm.FanID = ct.FanID
	Where	cpm.EndDate is null and 
			cpm.PaymentMethodsAvailableID <> ct.PaymentMethodsAvailableID
	---------------------------------------------------------------------------------------
	----------------------------------Add new entries--------------------------------------
	---------------------------------------------------------------------------------------
	Insert into Relational.CustomerPaymentMethodsAvailable
	Select	dc.FanID,
			dc.PaymentMethodsAvailableID,
			Cast(getdate() as date) as StartDate,
			Null as EndDate
	from #CardTypes as dc
	Left Outer join Relational.CustomerPaymentMethodsAvailable as a
		on	dc.FanID = a.FanID and
			dc.PaymentMethodsAvailableID = a.PaymentMethodsAvailableID and
			a.EndDate is null
	Where a.FanID is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_CustomerPaymentMethodsAvailableV1_1' and
			TableSchemaName = 'Relational' and
			TableName = 'CustomerPaymentMethodsAvailable' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.CustomerPaymentMethodsAvailable)-@RowCount
	where	StoredProcedureName = 'WarehouseLoad_CustomerPaymentMethodsAvailableV1_1' and
			TableSchemaName = 'Relational' and
			TableName = 'CustomerPaymentMethodsAvailable' and
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


End