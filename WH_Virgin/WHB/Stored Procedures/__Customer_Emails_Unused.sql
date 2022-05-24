/*
-- Replaces this bunch of stored procedures:
EXEC WHB.Emails_SFD_MasterlistExclusions -- 
EXEC WHB.Emails_SmartFocusEmailData_V2 -- 
EXEC WHB.Emails_DailyLoadChecks_Table --
EXEC WHB.Emails_SmartFocusCampaignKey_UpdateorRead 1 -- 
EXEC WHB.Emails_LionSendTracking_V2
EXEC WHB.Emails_LionSendTracking_UpdateEmailEvents_V2
EXEC WHB.Emails_Populate_SFDPostUploadAssessmentData_Member
*/
CREATE PROCEDURE [WHB].[__Customer_Emails_Unused] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
-- WHB.Emails_SFD_MasterlistExclusions ########################################
--    Purpose:    To provide to the DBAs a list of customers that are not deemed 
--                marketable by email
-------------------------------------------------------------------------------

	TRUNCATE TABLE [Staging].[SLC_Report_DailyLoad_NonMasterListCustomers]
	INSERT INTO [Staging].[SLC_Report_DailyLoad_NonMasterListCustomers]
	SELECT [c].[FanID]
	FROM [Derived].[Customer] c
	WHERE c.MarketableByEmail = 0
	AND c.CurrentlyActive = 1
	AND c.EmailStructureValid = 1

	-- log it
	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to SLC_report_DailyLoad_NonMasterListCustomers [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SFD_MasterlistExclusions', @msg


-------------------------------------------------------------------------------
-- WHB.Emails_SmartFocusEmailData_V2 ##########################################
-- Note that the column EventDate in table EmailEvent is completely redundant
-------------------------------------------------------------------------------

	DECLARE @StartRow BIGINT = (SELECT MAX([Derived].[EmailEvent].[EventID]) FROM [Derived].[EmailEvent])

	IF OBJECT_ID('tempdb..#EmailEvent') IS NOT NULL DROP TABLE #EmailEvent
	SELECT ee.ID AS EventID			--Take the lowest ID. This is arbitrary, but is just needed as a unique key 
		 , ee.Date AS EventDateTime	--The date field is actually a datetime field
		 , ee.FanID
		 , ee.CampaignKey
		 , ee.EmailEventCodeID
	INTO #EmailEvent
	FROM [SLC_Report].[dbo].[EmailEvent] ee
	WHERE ee.ID > @StartRow

	DROP INDEX [CSX_All] ON [Derived].[EmailEvent]

	INSERT INTO [Derived].[EmailEvent] ([Derived].[EmailEvent].[EventID], [Derived].[EmailEvent].[EventDateTime], [Derived].[EmailEvent].[EventDate], [Derived].[EmailEvent].[FanID], [Derived].[EmailEvent].[CompositeID], [Derived].[EmailEvent].[CampaignKey], [Derived].[EmailEvent].[EmailEventCodeID])
	SELECT ee.EventID
		 , ee.EventDateTime
		 , ee.EventDateTime AS EventDate
		 , ee.FanID
		 , #EmailEvent.[fa].CompositeID
		 , ee.CampaignKey
		 , ee.EmailEventCodeID
	FROM #EmailEvent ee
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON ee.FanID = #EmailEvent.[fa].ID
		AND #EmailEvent.[fa].ClubID = 166	--	Virgin Loyalty ClubID

	-- log it
	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailEvent] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SmartFocusEmailData_V2', @msg


	CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Derived].[EmailEvent] 
		([EventDate], [CampaignKey], [FanID], [EmailEventCodeID], [EventDateTime])

	-- log it
	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SmartFocusEmailData_V2', 'Columnstore index created on [Derived].[EmailEvent]'

/*--------------------------------------------------------------------------------------------------
----------------------Build Email Campaign Table in Staging-----------------------------------------
----------------------------------------------------------------------------------------------------*/
--restrict to only the campaigns that appear against customers in CashBackPlus	
--and sent since the launch of CBP.
TRUNCATE TABLE Derived.EmailCampaign	

SET IDENTITY_INSERT Derived.EmailCampaign ON

INSERT INTO	Derived.EmailCampaign ([Derived].[EmailCampaign].[ID],[Derived].[EmailCampaign].[CampaignKey],[Derived].[EmailCampaign].[EmailKey],[Derived].[EmailCampaign].[CampaignName],[Derived].[EmailCampaign].[Subject],[Derived].[EmailCampaign].[SendDateTime],[Derived].[EmailCampaign].[SendDate]	)
SELECT	ec.ID,
		ec.CampaignKey,
		ec.EmailKey,
		ec.CampaignName,
		ec.[Subject],
		ec.SendDate as SendDateTime,
		cast(ec.SendDate as date) as SendDate
FROM slc_report.dbo.EmailCampaign ec
WHERE ec.SendDate >= '1 Jan 2012'	
	AND EXISTS (SELECT 1 FROM Derived.EmailEvent ee WHERE ee.CampaignKey = ec.CampaignKey)	
ORDER BY ec.CampaignKey	

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailCampaign] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SmartFocusEmailData_V2', @msg

SET IDENTITY_INSERT Derived.EmailCampaign OFF


/*--------------------------------------------------------------------------------------------------
----------------------Build Email Event Type in Staging---------------------------------------------
----------------------------------------------------------------------------------------------------*/
--NB. 'Used' bit flag doesn't completely agree with the the EventCodes that appear in the EmailEvent table
--Therefore not pulled through here until understood better.
TRUNCATE TABLE Derived.EmailEventCode

INSERT INTO	Derived.EmailEventCode ([Derived].[EmailEventCode].[EmailEventCodeID], [Derived].[EmailEventCode].[EmailEventDesc])	
	SELECT [slc_report].[dbo].[EmailEventCode].[ID], [slc_report].[dbo].[EmailEventCode].[Name]
	FROM slc_report.dbo.EmailEventCode

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailEventCode] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SmartFocusEmailData_V2', @msg





-------------------------------------------------------------------------------
-- WHB.Emails_DailyLoadChecks_Table ###########################################
-------------------------------------------------------------------------------

--Populate Previous Days Table
TRUNCATE TABLE [Staging].[FanSFDDailyUploadData_PreviousDay]
INSERT INTO [Staging].[FanSFDDailyUploadData_PreviousDay]
SELECT [Staging].[FanSFDDailyUploadData].[FanID]
	,[Staging].[FanSFDDailyUploadData].[ClubCashAvailable]
	,[Staging].[FanSFDDailyUploadData].[CustomerJourneyStatus]
	,[Staging].[FanSFDDailyUploadData].[ClubCashPending]
	,[Staging].[FanSFDDailyUploadData].[WelcomeEmailCode]
	,[Staging].[FanSFDDailyUploadData].[DateOfLastCard]
	,[Staging].[FanSFDDailyUploadData].[CJS]
	,[Staging].[FanSFDDailyUploadData].[WeekNumber]
	,[Staging].[FanSFDDailyUploadData].[IsDebit]
	,[Staging].[FanSFDDailyUploadData].[IsCredit]
	,[Staging].[FanSFDDailyUploadData].[RowNumber]
	,[Staging].[FanSFDDailyUploadData].[ActivatedDate]
	,[Staging].[FanSFDDailyUploadData].[CompositeID]
FROM [Staging].[FanSFDDailyUploadData]

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Staging].[FanSFDDailyUploadData_PreviousDay] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_DailyLoadChecks_Table', @msg


--
TRUNCATE TABLE [Staging].[FanSFDDailyUploadData]

INSERT INTO [Staging].[FanSFDDailyUploadData]
SELECT [SLC_Report].[dbo].[FanSFDDailyUploadData].[FanID]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[ClubCashAvailable]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[CustomerJourneyStatus]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[ClubCashPending]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[WelcomeEmailCode]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[DateOfLastCard]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[CJS]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[WeekNumber]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[IsDebit]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[IsCredit]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[RowNumber]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[ActivatedDate]
		,[SLC_Report].[dbo].[FanSFDDailyUploadData].[CompositeID]
FROM SLC_Report.dbo.[FanSFDDailyUploadData]

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Staging].[FanSFDDailyUploadData] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_DailyLoadChecks_Table', @msg


--
Truncate Table [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay]

Insert into [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay]
Select *
From [Staging].[FanSFDDailyUploadData_DirectDebit]

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_DailyLoadChecks_Table', @msg


--
Truncate Table [Staging].[FanSFDDailyUploadData_DirectDebit]

Insert into [Staging].[FanSFDDailyUploadData_DirectDebit]
Select * 
From SLC_Report.dbo.[FanSFDDailyUploadData_DirectDebit]

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Staging].[FanSFDDailyUploadData_DirectDebit] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_DailyLoadChecks_Table', @msg





-------------------------------------------------------------------------------
-- WHB.Emails_SmartFocusCampaignKey_UpdateorRead ##############################
-------------------------------------------------------------------------------

--Produce List of new Campaigns to be added
SELECT 
	e.CampaignKey,
	LionSendID = Cast(right(Left([SLC_Report].[dbo].[EmailCampaign].[QueryName],28),3) as int),
	EmailType = 'H',
	Reference = Cast(Round(Cast(Datediff(day,'2016-07-22',[SLC_Report].[dbo].[EmailCampaign].[SendDate]) as real)/7,0,0)+236 as varchar(4))+'H',
	[HardCoded_OfferFrom] = Cast(NULL as int),
	[HardCoded_OfferTo] = Cast(NULL as int),
	[EmailName] = Cast(NULL as varchar(100)),
	ClubID = Case
				When [SLC_Report].[dbo].[EmailCampaign].[CampaignName] Like '%NatWest%' then 132
				Else 138
				End,
	TrueSolus = 0
INTO #NewRows
FROM SLC_Report.dbo.EmailCampaign as e with (nolock)
WHERE NOT EXISTS (
	SELECT 1 FROM [Derived].[CampaignLionSendIDs] f 
	WHERE e.campaignkey = f.campaignkey
)
	AND [SLC_Report].[dbo].[EmailCampaign].[CampaignName] Like '%Newsletter_LSID[0-9][0-9][0-9]_%' 
	and [SLC_Report].[dbo].[EmailCampaign].[CampaignName] not like 'TEST%' 
	and [SLC_Report].[dbo].[EmailCampaign].[SendDate] > '2016-07-22' 

INSERT INTO Derived.CampaignLionSendIDs
SELECT	*
FROM #NewRows

-- log it
SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to Derived.CampaignLionSendIDs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_SmartFocusCampaignKey_UpdateorRead', @msg





-------------------------------------------------------------------------------
-- WHB.Emails_LionSendTracking_V2 #############################################
-------------------------------------------------------------------------------
EXEC [WHB].[Emails_LionSendTracking_V2]




-------------------------------------------------------------------------------
-- WHB.Emails_LionSendTracking_UpdateEmailEvents_V2 ###########################
-------------------------------------------------------------------------------
EXEC [WHB].[Emails_LionSendTracking_UpdateEmailEvents_V2]




-------------------------------------------------------------------------------
-- WHB.Emails_Populate_SFDPostUploadAssessmentData_Member #####################
-------------------------------------------------------------------------------
	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_Populate_SFDPostUploadAssessmentData_Member', 'Starting'


	IF OBJECT_ID ('tempdb..#LionSendsToBeAdded') IS NOT NULL DROP TABLE #LionSendsToBeAdded
	SELECT	ROW_NUMBER() OVER(ORDER BY LionSendID) as RowNo,
		LionSendID
	INTO #LionSendsToBeAdded
	FROM (
		SELECT	DISTINCT
			sfd.LionSendID
		FROM Derived.SFD_PostUploadAssessmentData sfd
		WHERE NOT EXISTS (SELECT 1 FROM Derived.SFD_PostUploadAssessmentData_Member m WHERE m.LionSendID = sfd.LionSendID)
	) a


	ALTER INDEX IDX_FanID ON Derived.SFD_PostUploadAssessmentData_Member DISABLE
	ALTER INDEX IDX_LSID ON Derived.SFD_PostUploadAssessmentData_Member DISABLE
	ALTER INDEX IDX_IOID ON Derived.SFD_PostUploadAssessmentData_Member DISABLE

	INSERT INTO Derived.SFD_PostUploadAssessmentData_Member
	SELECT	
		sfd.[Customer ID] as FanID,
		sfd.LionSendID,
		x.OfferSlot,
		x.IronOfferID
	FROM Derived.SFD_PostUploadAssessmentData sfd 
	CROSS APPLY (VALUES 
		(7, sfd.Offer7),
		(1, sfd.Offer1),
		(2, sfd.Offer2),
		(3, sfd.Offer3),
		(4, sfd.Offer4),
		(5, sfd.Offer5),
		(6, sfd.Offer6)
	) x (OfferSlot, IronOfferID)
	WHERE NOT (sfd.CJS = 'M3' AND [Derived].[SFD_PostUploadAssessmentData].[WeekNumber] = 2)
	AND EXISTS (SELECT 1 FROM #LionSendsToBeAdded a WHERE a.LionSendID = #LionSendsToBeAdded.[sfd].LionSendID)

	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to Derived.SFD_PostUploadAssessmentData_Member [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_Populate_SFDPostUploadAssessmentData_Member', @msg


	ALTER INDEX IDX_FanID ON Derived.SFD_PostUploadAssessmentData_Member REBUILD
	ALTER INDEX IDX_LSID ON Derived.SFD_PostUploadAssessmentData_Member REBUILD
	ALTER INDEX IDX_IOID ON Derived.SFD_PostUploadAssessmentData_Member REBUILD

	EXEC Monitor.ProcessLog_Insert 'WHB', 'Emails_Populate_SFDPostUploadAssessmentData_Member', 'Finished'



RETURN 0

