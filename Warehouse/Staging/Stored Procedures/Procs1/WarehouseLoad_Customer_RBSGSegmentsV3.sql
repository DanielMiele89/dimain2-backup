/*
	Author:				Stuart Barnley

	Date:				2015-07-23

	Purpose:			Code created to update a new table to log the customersegment

	Updates:			Re-written to deal with anomalies in the data (multi segment customers)
						17-11-2016 SB - This table had a fragmented index that wasn't being rebuilt,
										therefore I have added code to do this. Also nolock on original count

*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_RBSGSegmentsV3]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	Declare @TableRows int
	Set @TableRows = (Select Count(*) From Relational.Customer_RBSGSegments with (nolock))
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_RBSGSegmentsV3',
			TableSchemaName = 'Relational',
			TableName = 'Customer_RBSGSegments',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	-------------------------------------------------------------------------------------------------
	-----------------------------------Create Customer Table-----------------------------------------
	-------------------------------------------------------------------------------------------------
	if object_id('tempdb..#Customer') is not null drop table #Customer
	Create table #Customer (	FanID int,
								ActivatedDate Date,
								SourceUID Varchar(20), 
								ClubID int,
								RowNo int,
								Primary Key (FanID)
							)

	Declare @FanID int,@FanIDMax int,@Lap smallint, @Chunksize int
	Set @FanID = 0
	Set @FanIDMax = (Select Max(FanID) from Relational.Customer with (nolock))
	Set @Lap = 0
	Set @Chunksize = 250000

	While @FanID < @FanIDMax
	Begin
	
		Insert Into #Customer
		Select	Top (@Chunksize)
				FanID,
				ActivatedDate,
				SourceUID,
				ClubID,
				ROW_NUMBER() OVER(ORDER BY FanID ASC) + (@Lap * @Chunksize) AS RowNo
		From Relational.Customer as c
		Where FanID > @FanID
		Order by FanID

		Set @FanID = (Select Max(FanID) From #Customer)
		Set @Lap = @Lap+1
	End

	Create nonclustered index Customer_SourceUID on #Customer (SourceUID)
	-------------------------------------------------------------------------------------------------
	-----------------------------------Assess for new entries----------------------------------------
	-------------------------------------------------------------------------------------------------
	Declare @LaunchDate as Date,@RowNo int,@RowNoMax int
	Set @LaunchDate = '2015-07-20'
	Set @RowNo = 1
	Set @RowNoMax = (Select Max(RowNo) from #Customer)

	if object_id('tempdb..#CS') is not null drop table #CS
	Create Table #CS (FanID int, CustomerSegment varchar(5), StartDate Date,RowNo tinyint)

	While @RowNo <= @RowNoMax
	Begin
		-----------------------------------------------------------------------------------------------------
		----------------------------------------------Find Segments------------------------------------------
		-----------------------------------------------------------------------------------------------------
		Insert into #CS
		Select	a.FanID,
				Case
					When a.CustomerSegment is null then ''
					When a.CustomerSegment = 'V' then 'V'
					Else ''
				End as CustomerSegment,
				StartDate,
				--Cast(NULL as date) as EndDate
				ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY a.CustomerSegment DESC) AS RowNo
		From 
		(	select	Distinct
				FanID,
				ica.Value as CustomerSegment,
				Case
					when ica.IssuerCustomerID is null and ActivatedDate >= @LaunchDate then ActivatedDate
					when ica.IssuerCustomerID is null then @LaunchDate
					When ica.StartDate < @Launchdate then @LaunchDate
					Else ica.StartDate
				End as StartDate
			from #Customer as c
			left outer join SLC_Report.dbo.IssuerCustomer as ic
				on c.SourceUID = ic.SourceUID
			Left Outer join slc_report.dbo.issuer as i
				on ic.IssuerID = i.ID
			Left join slc_report.dbo.IssuerCustomerAttribute as ica
				on ic.ID = ica.IssuerCustomerID and
					ica.EndDate is null and ica.AttributeID = 1
			Where	((c.ClubID = 138 and i.ID = 1)Or(c.ClubID = 132 and i.ID = 2)or i.id is null) and
					c.RowNo Between @RowNo and @RowNo+(@Chunksize-1) and
					EndDate is null
		) as a
		-----------------------------------------------------------------------------------------------------
		--------------------------------delete where more than one segment-----------------------------------
		-----------------------------------------------------------------------------------------------------
		Delete from #CS where RowNo > 1
		-----------------------------------------------------------------------------------------------------
		------------------------------------------Insert new segments----------------------------------------
		-----------------------------------------------------------------------------------------------------
		Insert into Relational.Customer_RBSGSegments
		Select	c.FanID,
				c.CustomerSegment,
				c.StartDate,
				NULL as EndDate
		from #CS as c
		Left Outer join Relational.Customer_RBSGSegments as cs
			on	c.fanid = cs.fanid and
				cs.enddate is null and
				(Case
					When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
					Else c.CustomerSegment
				 End) =
						(Case
								When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
								Else cs.CustomerSegment
						 End)
		Where	cs.fanid is null
		-----------------------------------------------------------------------------------------------------
		------------------------------------------Insert new segments----------------------------------------
		-----------------------------------------------------------------------------------------------------
		Update	Relational.Customer_RBSGSegments
		Set		EndDate = dateadd(day,-1,c.StartDate)
		from	Relational.Customer_RBSGSegments as cs
		inner join #CS as c
				on	cs.fanid = c.fanid and
				cs.enddate is null and
				(Case
					When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
					Else c.CustomerSegment
				 End) <>
						(Case
								When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
								Else cs.CustomerSegment
						 End)
	
		Truncate Table #cs

		Set @RowNo= @RowNo+@Chunksize
	
	End

	Alter Index [ix_Customer_RBSGSegments_FanID_EndDate] ON Relational.Customer_RBSGSegments  REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_RBSGSegmentsV3' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_RBSGSegments' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = ((Select COUNT(*) from Relational.Customer_RBSGSegments)-@TableRows)
	where	StoredProcedureName = 'WarehouseLoad_Customer_RBSGSegmentsV3' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_RBSGSegments' and
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

	--(2000934 row(s) affected)
	

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