CREATE Procedure [Staging].[CustomerUnsubscribesV1_2]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_temp
	Select	StoredProcedureName = 'CustomerUnsubscribesV1_2',
			TableSchemaName = 'Staging',
			TableName = 'Customer_UnsubscribeDates',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'
	/*--------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Declare @LaunchDate Date, -- Date scheme Launched
			@SFDDate Date -- Date to assess SFD Unsubscribes from
	Set @LaunchDate = 'Aug 08, 2013'
	Set @SFDDate = 'Nov 20, 2013'

	-----------------------------------------------------------------------------------------
	------------------------------Find Unsubscribes ChangeLog--------------------------------
	-----------------------------------------------------------------------------------------
	if object_id('tempdb..#UnSub') is not null drop table #UnSub

	Select	Cast([Date] as date) as EntryDate,
			FanID
	Into #UnSub
	from Staging.InsightArchiveData as iad
	Where TypeID = 3 and
			iad.Date > @LaunchDate

	Order by EntryDate,FanID


	-----------------------------------------------------------------------------------------
	--------------------------Find Unsubscribes ChangeLog where Status = 1-------------------
	-----------------------------------------------------------------------------------------
	if object_id('tempdb..#Unsubs_StillActive') is not null drop table #Unsubs_StillActive
	Select a.FanID,Dateadd(day,-1,a.EntryDate) as EventDate
	into #Unsubs_StillActive
	From
	(select	u.*--,
			--Cast(i.Date as date) as [StatusDate],
			--i.Value,
			--ROW_NUMBER() OVER(PARTITION BY u.EntryDate,u.FanID ORDER BY Cast(i.Date as date) DESC) AS RowNo
	from #UnSub as u
	inner join Relational.customer as c
		on	u.FanID = c.fanid and
			Cast(c.ActivatedDate as date) <= EntryDate
	) as a


	--------------------------------------------------------------------------
	----------------Combine ChangeLog entries with SFD Events 301-------------
	--------------------------------------------------------------------------
	if object_id('tempdb..#Unsubscribes') is not null drop table #Unsubscribes
	Select FanID,Min(EventDate) as EventDate, 1 as Accurate
	Into #Unsubscribes
	From
		( Select *
		  from #Unsubs_StillActive
		  Union all
		  select Distinct ee.FanID,ee.EventDate
		  from relational.EmailEvent as ee
		  Where	ee.EmaileventCodeID = 301 and 
				ee.EventDate >= @LaunchDate
		) as a
	Group by FanID 
	--------------------------------------------------------------------------------
	-----------Pull off other SFD Unusbcribes not including initial list------------
	--------------------------------------------------------------------------------
	/*	By-weekly we receive a list of those who have unsubscribed and we add new 
		ones to the table 
	*/
	if object_id('tempdb..#UnsubsSFD') is not null drop table #UnsubsSFD
	Select a.FanID,Min(StartDate) as EventDate,0 as Accurate
	Into #UnsubsSFD
	from relational.SmartFocusUnSubscribes as a
	Left Outer join #Unsubscribes as u
		on a.FanID = u.Fanid
	Where EndDate is null and StartDate > @SFDDate and u.FanID is null
	Group by a.FanID

	---------------------------------------------------------------------------------
	------------Pull off last email accessed for SFD initial list data---------------
	---------------------------------------------------------------------------------
	/*  The initial list was received in November and included people who has 
		unsubscribed over the previous few months, so we are going to supply the date
		the last email was accessed as this should be when they unsubscribed
	*/
	if object_id('tempdb..#UnSubsSFD2') is not null drop table #UnSubsSFD2
	Select FanID,EventDate,0 as Accurate
	into #UnSubsSFD2
	from
	(Select a.FanID,StartDate,Max(ee.EventDate) as EventDate
	from relational.SmartFocusUnSubscribes as a
	inner join relational.EmailEvent as ee
		on a.FanID = ee.FanID
	inner join relational.CampaignLionSendIDs as cls
		on ee.CampaignKey = cls.CampaignKey
	Where EndDate is null and StartDate = @SFDDate
	Group by a.FanID,StartDate
	) as a
	Where EventDate <= @SFDDate
	Order by EventDate

	---------------------------------------------------------------------------------
	--------------------------------------Dedup--------------------------------------
	---------------------------------------------------------------------------------
	if object_id('tempdb..#UnSubsSFD2_DeDuped') is not null drop table #UnSubsSFD2_DeDuped
	Select u2.* 
	Into #UnSubsSFD2_DeDuped
	from #UnSubsSFD2 as u2
	Left Outer Join #UnsubsSFD as u
		on u2.FanID = u.FanID
	Left Outer Join #Unsubscribes as a
		on u2.FanID = a.FanID
	Where u.FanID is null and a.FanID is null
	---------------------------------------------------------------------------------
	---------------------------------Combine all Lists together----------------------
	---------------------------------------------------------------------------------
	if object_id('tempdb..#Final_UnSubs') is not null drop table #Final_UnSubs
	Select a.* 
	Into #Final_UnSubs
	from
	(Select * from #Unsubscribes
	union all
	Select * from #UnsubsSFD
	union all
	Select * from #UnSubsSFD2_DeDuped
	) as a
	inner join relational.customer as c
		on a.fanid = c.fanid
	Where c.Unsubscribed = 1

	---------------------------------------------------------------------------------
	----------------------------Add to Customer_UnsubscribeDates---------------------
	---------------------------------------------------------------------------------
	--ALTER INDEX ALL ON Relational.Customer_UnsubscribeDates Disable

	TRUNCATE TABLE Staging.Customer_UnsubscribeDates

	Insert Into Staging.Customer_UnsubscribeDates
	Select	FanID,
			EventDate,
			Cast(Accurate as bit) as Accuracy
	from #Final_UnSubs

	--ALTER INDEX ALL ON Relational.Customer_UnsubscribeDates Rebuild


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.Customer_UnsubscribeDates)
	where	StoredProcedureName = 'CustomerUnsubscribesV1_2' and
			TableSchemaName = 'Staging' and
			TableName = 'Customer_UnsubscribeDates' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = getdate()
	where	StoredProcedureName = 'CustomerUnsubscribesV1_2' and
			TableSchemaName = 'Staging' and
			TableName = 'Customer_UnsubscribeDates' and
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