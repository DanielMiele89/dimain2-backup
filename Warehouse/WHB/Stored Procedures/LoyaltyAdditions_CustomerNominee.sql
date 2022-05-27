CREATE PROCEDURE [WHB].[LoyaltyAdditions_CustomerNominee]
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @TableRows int

	Set @TableRows = (Select COUNT(*) from Relational.Customer_Loyalty_DD_Nominee)
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer_Loyalty_DD_Nominee',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Create Customer table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Customers') is not null drop table #Customers
	Select	c.FanID,
			c.currentlyActive,
			c.ActivatedDate,
			ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	Into #Customers
	From relational.Customer as c
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Find Nominees and update table-----------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RowNo int, @MaxRowNo int, @ChunkSize int
	Set @RowNo = 1
	Set @MaxRowNo = (Select MAX(RowNo) from #Customers)
	Set @ChunkSize = 250000

	if object_id('tempdb..#Nominee') is not null drop table #Nominee
	Create Table #Nominee (FanID int, Nominee bit, ActivatedDate Date, Primary Key(FanID))

	While @RowNo <= @MaxRowNo
	Begin
		Truncate Table #Nominee
		--Find Nominees
		Insert Into #Nominee
		Select Distinct c.FanID,
						Case
							When	dd.FanID is null then 0
							When	dd.Nominee = 1 and
								 (	a.LoyaltyAccount = 1 or dd.OnTrial = 1) then 1
							Else 0
						End Nominee,
						c.ActivatedDate
		from #Customers as c
		Left Outer Join Staging.SLC_Report_DailyLoad_Phase2DataFields as a
			on c.FanID = a.FanID and a.LoyaltyAccount = 1
		Left Outer join SLC_Report.[dbo].[FanSFDDailyUploadData_DirectDebit]  as dd
			on	c.FanID = dd.FanID and
				dd.Nominee = 1 and
				c.CurrentlyActive = 1
		Where c.RowNo Between @RowNo and @RowNo + (@ChunkSize-1)
	
		--Add new entries for change in nominee status
		Insert into Relational.Customer_Loyalty_DD_Nominee
		Select	n.FanID,
				n.Nominee,
				Case
					When ActivatedDate = Cast(getdate() as date) then Cast(getdate() as date)
					Else Dateadd(day,-1,getdate())
				End as StartDate,
				CAST(NULL as DATE) as EndDate
		From #Nominee as n
		Left Outer join Relational.Customer_Loyalty_DD_Nominee as d
			on	n.FanID = d.FanID and
				n.Nominee = d.Nominee and
				EndDate is null
		Where d.FanID is null
	
		--Update old entries for Nominees
	
		Update Relational.Customer_Loyalty_DD_Nominee
		Set EndDate =	Case
							When ActivatedDate = Cast(getdate() as date) then Dateadd(day,-1,Cast(getdate() as date))
							Else Dateadd(day,-2,Cast(GETDATE() as DATE))
						End
		From #Nominee as n
		inner join Relational.Customer_Loyalty_DD_Nominee as d
			on	n.FanID = d.FanID and
				n.Nominee <> d.Nominee and
				EndDate is null
	
		Set @RowNo = @RowNo+@ChunkSize
	End

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_Loyalty_DD_Nominee' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = ((Select COUNT(*) from Relational.Customer_Loyalty_DD_Nominee)-@TableRows)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_Loyalty_DD_Nominee' and
			TableRowCount is null

	Insert into staging.JobLog
	select	[StoredProcedureName],
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