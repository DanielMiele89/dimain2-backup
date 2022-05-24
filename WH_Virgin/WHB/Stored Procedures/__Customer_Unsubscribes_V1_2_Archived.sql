create PROCEDURE [WHB].[__Customer_Unsubscribes_V1_2_Archived]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @LaunchDate Date, -- Date scheme Launched
			@SFDDate Date -- Date to assess SFD Unsubscribes from
	Set @LaunchDate = 'Aug 08, 2013'
	Set @SFDDate = 'Nov 20, 2013'

	-----------------------------------------------------------------------------------------
	------------------------------Find Unsubscribes ChangeLog--------------------------------
	-----------------------------------------------------------------------------------------
	if object_id('tempdb..#UnSub') is not null drop table #UnSub

	Select	Cast([Staging].[InsightArchiveData].[Date] as date) as EntryDate,
			[Staging].[InsightArchiveData].[FanID]
	Into #UnSub
	from Staging.InsightArchiveData as iad
	Where [Staging].[InsightArchiveData].[TypeID] = 3 and
			iad.Date > @LaunchDate

	Order by EntryDate,[Staging].[InsightArchiveData].[FanID]

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
	inner join Derived.customer as c
		on	u.FanID = c.fanid and
			Cast(#UnSub.[c].ActivatedDate as date) <= [u].[EntryDate]
	) as a

	--------------------------------------------------------------------------
	----------------Combine ChangeLog entries with SFD Events 301-------------
	--------------------------------------------------------------------------
	if object_id('tempdb..#Unsubscribes') is not null drop table #Unsubscribes
	Select #Unsubs_StillActive.[FanID],Min(#Unsubs_StillActive.[EventDate]) as EventDate, 1 as Accurate
	Into #Unsubscribes
	From
		( Select *
		  from #Unsubs_StillActive
		  Union all
		  select Distinct ee.FanID,ee.EventDate
		  from Derived.EmailEvent as ee
		  Where	ee.EmaileventCodeID = 301 and 
				ee.EventDate >= @LaunchDate
		) as a
	Group by #Unsubs_StillActive.[FanID] 

	--------------------------------------------------------------------------------
	-----------Pull off other SFD Unusbcribes not including initial list------------
	--------------------------------------------------------------------------------
	/*	By-weekly we receive a list of those who have unsubscribed and we add new 
		ones to the table 
	*/
	if object_id('tempdb..#UnsubsSFD') is not null drop table #UnsubsSFD
	Select #Unsubscribes.[a].FanID,Min(#Unsubscribes.[StartDate]) as EventDate,0 as Accurate
	Into #UnsubsSFD
	from Derived.SmartFocusUnSubscribes as a
	Left Outer join #Unsubscribes as u
		on #Unsubscribes.[a].FanID = u.Fanid
	Where #Unsubscribes.[EndDate] is null and #Unsubscribes.[StartDate] > @SFDDate and u.FanID is null
	Group by #Unsubscribes.[a].FanID

	---------------------------------------------------------------------------------
	------------Pull off last email accessed for SFD initial list data---------------
	---------------------------------------------------------------------------------
	/*  The initial list was received in November and included people who has 
		unsubscribed over the previous few months, so we are going to supply the date
		the last email was accessed as this should be when they unsubscribed
	*/
	if object_id('tempdb..#UnSubsSFD2') is not null drop table #UnSubsSFD2
	Select FanID,[a].[EventDate],0 as Accurate
	into #UnSubsSFD2
	from
	(Select a.FanID,StartDate,Max(ee.EventDate) as EventDate
	from Derived.SmartFocusUnSubscribes as a
	inner join Derived.EmailEvent as ee
		on a.FanID = ee.FanID
	inner join Derived.CampaignLionSendIDs as cls
		on ee.CampaignKey = cls.CampaignKey
	Where EndDate is null and StartDate = @SFDDate
	Group by a.FanID,StartDate
	) as a
	Where [a].[EventDate] <= @SFDDate
	Order by [a].[EventDate]

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
	inner join Derived.customer as c
		on a.fanid = c.fanid
	Where c.Unsubscribed = 1

	---------------------------------------------------------------------------------
	----------------------------Add to Customer_UnsubscribeDates---------------------
	---------------------------------------------------------------------------------
	--ALTER INDEX ALL ON Relational.Customer_UnsubscribeDates Disable

	TRUNCATE TABLE Derived.Customer_UnsubscribeDates

	Insert Into Derived.Customer_UnsubscribeDates
	Select	#Final_UnSubs.[FanID],
			#Final_UnSubs.[EventDate],
			Cast(#Final_UnSubs.[Accurate] as bit) as Accuracy
	from #Final_UnSubs

	--ALTER INDEX ALL ON Relational.Customer_UnsubscribeDates Rebuild


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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run