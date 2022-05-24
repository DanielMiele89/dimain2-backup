/*
-- Replaces this bunch of stored procedures:
EXEC WHB.Customer_HomeMover_Details_V1_3
EXEC WHB.Customer_EmailChange1
EXEC WHB.Customer_Customer_V1_20
EXEC WHB.Customer_Registrations
EXEC WHB.Customer_SmartFocusUnsubscribes_V1_3
EXEC WHB.Customer_SmartFocusUnsubscribes_Part2
EXEC WHB.Customer_HardBounceEmailChange_V1_2
EXEC WHB.Customer_HardbounceEmailChangePart2
EXEC WHB.Customer_InvalidEmail
EXEC WHB.Customer_Marketable_ButDeceased
EXEC WHB.Customer_Deactivations_V1_2
EXEC WHB.Customer_WebLogins_V1_1
EXEC WHB.Customer_EmailEngaged_V1_1
EXEC WHB.Customer_DuplicateSourceUID_V1_2
EXEC WHB.Customer_Cashback_Balances_V1_2
EXEC WHB.Customer_Unsubscribes_V1_2
EXEC WHB.Customer_UnsubscribeCampaigns_V1_1
EXEC WHB.Customer_PaymentMethodsAvailable_V1_1
EXEC WHB.Customer_Deactivate_Deceased_Customers
EXEC WHB.Customer_WGUpdate_V1_0
*/
CREATE PROCEDURE [WHB].[__Customer_Processing_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @msg VARCHAR(200), @RowsAffected INT




-------------------------------------------------------------------------------
--EXEC WHB.Customer_HomeMover_Details_V1_3 ####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HomeMover_Details_V1_3', 'Starting'

--This pulls through the address data for anyone that has had their postcode changed since last run
INSERT INTO Staging.Homemover_Details
SELECT h.FanID
		, h.OldPostcode
		, h.NewPostCode
		, h.LoadDate
		, c.Address1 as OldAddress1
		, c.Address2 as OldAddress2
		, c.City as OldCity
		, c.County as OldCounty
FROM Staging.Homemover as h
INNER JOIN Staging.Customer as c
	ON h.FanID = c.FanID
WHERE NOT EXISTS (
	SELECT 1 FROM Staging.Homemover_Details hd
	WHERE h.FanID = hd.FanID
	and h.LoadDate = hd.LoadDate
	and h.NewPostCode = hd.NewPostCode
	and h.OldPostCode = hd.OldPostCode
)
And Not (Right(h.OldPostCode, 3) = Right(h.NewPostCode, 3)	--	Added to deal with Partial Postcodes being fully populated
			And Len(h.OldPostCode) < 5
			And Len(h.NewPostCode) > 4)
And Not (Len(h.OldPostCode) < 5	--	Added as Nirupam advised do not include anyone where old postcode < 4 characters long
			Or h.OldPostCode Is Null)
			

ALTER INDEX IDX_FanID ON Relational.Homemover_Details DISABLE

TRUNCATE TABLE Relational.Homemover_Details

INSERT INTO Derived.Homemover_Details
	SELECT * FROM Staging.Homemover_Details

ALTER INDEX IDX_FanID ON Relational.Homemover_Details REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HomeMover_Details_V1_3', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_EmailChange1 ##############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_EmailChange1', 'Starting'

--Insert Into staging.Customer_EmailAddressChanges_20150101
INSERT INTO Derived.Customer_EmailAddressChanges
SELECT f.ID as FanID
		, f.Email
		, Convert(Date, GetDate()) as DateChanged
FROM SLC_Report.dbo.Fan as f
INNER JOIN Derived.Customer as c
	ON f.id = c.fanid
WHERE f.Email != c.Email
	AND f.Email Is Not Null
	AND Len(f.Email) > 5

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_EmailChange1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Customer_V1_20 ############################################
-- includes WHB.Customer_UpdateDeactivatedDate_V1_2
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Customer_V1_20', 'Starting'
EXEC WHB.Customer_Customer_V1_20
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Customer_V1_20', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Registrations #############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Registrations', 'Starting'

------------------------------------------------------------------------
----------------Update Registered field in Customer Table---------------
------------------------------------------------------------------------
--Field set to 0 initially this overwrites with correct value

UPDATE c
	SET Registered = 1
FROM Derived.customer as c
INNER JOIN SLC_Report..FanCredentials as r
	ON c.fanid = r.FanID
WHERE r.HashedPassword is not null and 
		r.HashedPassword <> ''

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Registrations', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_SmartFocusUnsubscribes_V1_3 ###############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_SmartFocusUnsubscribes_V1_3', 'Starting'

/*--------------------------------------------------------------------------------------------------
---------------------------------Find customer records to be updated--------------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Deactivations') is not null drop table #Deactivations
Select Distinct c.fanid
Into #Deactivations
from Derived.customer as c
inner join Relational.SmartFocusUnsubscribes as sfu
	on c.fanid = sfu.fanid 
	and c.email = sfu.email 
Where sfu.enddate is null

/*--------------------------------------------------------------------------------------------------
-----------------------------------------update customer records------------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE c SET 
	MarketableByEmail = CASE WHEN c.MarketableByEmail = 1 THEN 0 ELSE c.MarketableByEmail END,
	Unsubscribed = CASE WHEN c.Unsubscribed = 0 THEN 1 ELSE c.Unsubscribed END
FROM Derived.customer c
WHERE EXISTS (SELECT 1 FROM #Deactivations sfu WHERE sfu.fanid = c.fanid)
	AND (c.MarketableByEmail = 1 OR c.Unsubscribed = 0)

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_SmartFocusUnsubscribes_V1_3', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_SmartFocusUnsubscribes_Part2 ##############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_SmartFocusUnsubscribes_Part2', 'Starting'

--Find customers Marked as ContactByPost using modern website-----------------------
--Mark customers as not MarketableByEmail------------------------------
UPDATE c
	SET MarketableByEmail = 0
FROM Derived.Customer c
INNER JOIN SLC_Report..Fan f
	ON c.FanID = f.ID
WHERE c.ActivatedDate >= '2016-06-01' 
	AND c.MarketableByEmail = 1 
	AND f.ContactByPost = 1

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_SmartFocusUnsubscribes_Part2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_HardBounceEmailChange_V1_2 ################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HardBounceEmailChange_V1_2', 'Starting'
EXEC WHB.Customer_HardBounceEmailChange_V1_2
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HardBounceEmailChange_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_HardbounceEmailChangePart2 ################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HardbounceEmailChangePart2', 'Starting'

-- Take Static list who changed emails in early 2015 and check they are valid ------------
if object_id('tempdb..#ChangedEmailAddress') is not null drop table #ChangedEmailAddress
select Distinct c.FaniD, DateChanged as EmailchangeDate
Into #ChangedEmailAddress
from Derived.Customer_EmailAddressChanges as eac
inner join Derived.customer as c
	on eac.FanID = c.FanID
Where	hardbounced = 1 and 
		eac.email = c.email and
		CurrentlyActive = 1 and
		EmailStructureValid = 1 and
		c.Unsubscribed = 0

-- Check if they have bounced since email address was changed ----------------
if object_id('tempdb..#BouncedSince') is not null drop table #BouncedSince
Select distinct ee.FanID
Into #BouncedSince
from Derived.emailevent as ee
inner join #ChangedEmailAddress as cea
	on ee.fanid = cea.fanid
Where	EmailEventCodeID = 702 and
		ee.EventDate > cea.EmailchangeDate

-- Update Hardbounced Flag -----------------------------------
Update Derived.Customer
Set Hardbounced = 0
Where fanid in (
	Select cea.FanID 
	from #ChangedEmailAddress as cea
	WHERE NOT EXISTS (SELECT 1 FROM #BouncedSince as bs WHERE cea.fanid = bs.FanID)
)

-- Update MarketableByEmail Flag -------------------------------
UPDATE Relational.Customer
SET MarketableByEmail = 1
WHERE (LaunchGroup is not null or ActivatedDate >= 'Aug 08, 2013')	
	and CurrentlyActive = 1 
	and Unsubscribed = 0 
	and Hardbounced = 0 
	and EmailStructureValid = 1 
	and ActivatedOffline = 0 
	and Len(Postcode) >= 3 
	and SourceUID not in (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
	and Marketablebyemail = 0

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_HardbounceEmailChangePart2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_InvalidEmail ##############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_InvalidEmail', 'Starting'

UPDATE c
	SET MarketableByEmail = 0
FROM Derived.Customer c
WHERE MarketableByEmail = 1
	and EmailStructureValid = 1
	and (       
		email like '%com[a-z]' or 
		email like '%com[a-z][a-z]' or
		email like '%co[a-z][a-z]' or
		email like '%hotmali%'
		) 
	and email not like '%comp' 
	and email not like '%coop' 
	and email not like '%come' 

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_InvalidEmail', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Marketable_ButDeceased ####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Marketable_ButDeceased', 'Starting'

-----------------------------------------------------------------------------------
------Find a list of customers who are currently active but deemed Deceased-------
-----------------------------------------------------------------------------------
UPDATE  c
	SET MarketableByEmail = 0
FROM Derived.Customer as c
INNER JOIN SLC_Report.dbo.Fan as f
	ON f.ID = c.FanID
WHERE c.MarketableByEmail = 1
	AND f.AgreedTCs = 1 
	and f.AgreedTCsDate is not null 
	and f.Status = 1 
	and f.DeceasedDate IS NOT NULL 
	and f.ClubID in (132,138)

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Marketable_ButDeceased', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Deactivations_V1_2 ########################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Deactivations_V1_2', 'Starting'

Insert Into Derived.DeactivatedCustomers
SELECT	
	f.ID as FanID,
	f.[Status],
	f.AgreedTCs,
	f.AgreedTCsDate,
	Dateadd(day,-1,Convert(Date,GetDate())) as DataDate,	--This is the date the data was last loaded
	Convert(Date,GetDate()) as LoadedDate	--This is the date the data was copied to this new table
FROM  slc_report.dbo.Fan f
INNER JOIN Derived.ReportBaseMay2012 rb 
	ON f.ID = rb.FanID
WHERE f.[status] = 0				---This indicates record deactivated
	AND rb.IsControl = 0		---Not part of the control group

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Deactivations_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_WebLogins_V1_1 ############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_WebLogins_V1_1', 'Starting'

DELETE FROM Derived.WebLogins  
WHERE trackdate > DATEADD(DAY,-2,CAST(GETDATE() AS DATE))
--(166 row(s) affected)


INSERT INTO Derived.WebLogins
SELECT	fanid,
	trackdate,
	fandata
FROM SLC_Report.dbo.Fan f 
INNER JOIN SLC_Report.dbo.TrackingData td 
	ON td.fanid = f.ID
WHERE f.ClubID IN (132,138)
	AND td.fandata LIKE 'login ip=%'
	AND td.tracktypeid = 1
	AND td.trackdate > DATEADD(DAY,-2,CAST(GETDATE() AS DATE))

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_WebLogins_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_EmailEngaged_V1_1 #########################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_EmailEngaged_V1_1', 'Starting'
EXEC WHB.Customer_EmailEngaged_V1_1
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_EmailEngaged_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_DuplicateSourceUID_V1_2 ###################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_DuplicateSourceUID_V1_2', 'Starting'

/*--------------------------------------------------------------------------------------------------
----------------------------------Find duplicate SourceUIDs-----------------------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#DuplicateSourceUID') is not null drop table #DuplicateSourceUID
SELECT SourceUID 
INTO #DuplicateSourceUID
FROM Derived.Customer 
GROUP BY SourceUID
HAVING COUNT(*) > 1

/*--------------------------------------------------------------------------------------------------
------------------Re-Populate Staging.Customer_DuplicateSourceUID Table with latest list------------
----------------------------------------------------------------------------------------------------*/
INSERT Staging.Customer_DuplicateSourceUID
SELECT	d.SourceUID,
		Cast(getdate() as date) as StartDate,
		Cast(Null as Date) as EndDate
FROM #DuplicateSourceUID as d
WHERE NOT EXISTS (
	SELECT 1 FROM Staging.Customer_DuplicateSourceUID c
	WHERE d.SourceUID = c.SourceUID
		AND c.enddate is null)

/*--------------------------------------------------------------------------------------------------
------------------------------Add EndDates when a sourceUID is resolved-----------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE c SET EndDate = dateadd(day,-1,Cast(getdate() as date))
FROM Staging.Customer_DuplicateSourceUID as c
WHERE NOT EXISTS (
	SELECT 1 FROM #DuplicateSourceUID d
	WHERE c.SourceUID = d.SourceUID)
AND c.EndDate is null

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_DuplicateSourceUID_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Cashback_Balances_V1_2 ####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Cashback_Balances_V1_2', 'Starting'

IF NOT EXISTS (SELECT 1 FROM Derived.Customer_CashbackBalances ccb WHERE ccb.[Date] = CAST(GETDATE() AS DATE))
INSERT INTO Derived.Customer_CashbackBalances WITH (TABLOCKX) 
	(FanID, ClubCashPending, ClubCashAvailable, [Date])
SELECT	
	f.ID as FanID,
	ClubCashPending,
	ClubCashAvailable,
	[Date] = CAST(GETDATE() AS DATE)
FROM SLC_Report.dbo.Fan f
WHERE AgreedTCs = 1 
	AND [Status] = 1 
	AND clubid in (132,138);

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Cashback_Balances_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Unsubscribes_V1_2 #########################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Unsubscribes_V1_2', 'Starting'
EXEC WHB.Customer_Unsubscribes_V1_2
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Unsubscribes_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_UnsubscribeCampaigns_V1_1 #################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_UnsubscribeCampaigns_V1_1', 'Starting'

TRUNCATE TABLE Staging.Customer_LastEmailReceived
INSERT INTO Staging.Customer_LastEmailReceived (FanID, SendDate, CampaignKey, RowNo)
SELECT * 
FROM (
	SELECT	c.FanID,
		ec.SendDate,
		ec.CampaignKey,
		ROW_NUMBER() OVER(PARTITION BY c.FanID ORDER BY ec.SendDate DESC) AS RowNo
	FROM Derived.customer as c
	inner join Derived.emailevent as ee
		on c.fanid = ee.fanid
	inner join Derived.CampaignLionSendIDs as cls
		on ee.CampaignKey = cls.CampaignKey
	inner join slc_report.dbo.emailcampaign as ec
		on ee.CampaignKey = ec.CampaignKey
	WHERE c.unsubscribed = 1
) a
WHERE RowNo = 1

TRUNCATE TABLE Relational.Customer_UnsubscribeDates
INSERT INTO Derived.Customer_UnsubscribeDates
SELECT cud.FanID, cud.EventDate, cud.CampaignKey, cud.Accuracy
FROM Derived.Customer_UnsubscribeDates as cud
LEFT JOIN staging.Customer_LastEmailReceived as ler
	on cud.FanID = ler.FanID and
		cud.EventDate >= Cast(ler.SendDate as date) and
		cud.EventDate < dateadd(day,21,Cast(ler.SendDate as date))

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_UnsubscribeCampaigns_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_PaymentMethodsAvailable_V1_1 ##############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_PaymentMethodsAvailable_V1_1', 'Starting'

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
	FROM (
		SELECT	c.FanID,
			Cast(coalesce(Max(Case When CardTypeID = 1 then 1 Else 0 End),0) as bit) as IsCredit,
			Cast(Coalesce(Max(Case When CardTypeID = 2 then 1 Else 0 End),0) as bit) as IsDebit
	FROM Derived.Customer as c with (nolock)
	Left Join SLC_Report..Pan p with (nolock)
			on	c.CompositeID = p.CompositeID and 
				p.RemovalDate IS NULL
	Left JOIN SLC_Report..PaymentCard pc WITH (NOLOCK)
			ON p.PaymentCardID = pc.ID
	Group by c.FanID
	) as a

	---------------------------------------------------------------------------------------
	-----------------------Close off any no longer valid entries-------------------------------
	---------------------------------------------------------------------------------------
	Update cpm
		set EndDate = Dateadd(day,-1,CAST(getdate() as DATE))
	from Derived.CustomerPaymentMethodsAvailable as cpm
	inner join #CardTypes as ct
		on cpm.FanID = ct.FanID
	Where cpm.EndDate is null 
		and cpm.PaymentMethodsAvailableID <> ct.PaymentMethodsAvailableID

	---------------------------------------------------------------------------------------
	----------------------------------Add new entries--------------------------------------
	---------------------------------------------------------------------------------------
	INSERT INTO Derived.CustomerPaymentMethodsAvailable
	SELECT	dc.FanID,
			dc.PaymentMethodsAvailableID,
			Cast(getdate() as date) as StartDate,
			Null as EndDate
	FROM #CardTypes as dc
	LEFT JOIN Derived.CustomerPaymentMethodsAvailable as a
		on	dc.FanID = a.FanID 
		and dc.PaymentMethodsAvailableID = a.PaymentMethodsAvailableID 
		and a.EndDate is null
	WHERE a.FanID is null

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_PaymentMethodsAvailable_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_Deactivate_Deceased_Customers #############################
-------------------------------------------------------------------------------
Declare @RowCount int

UPDATE c
	SET	CurrentlyActive = 0,
		DeactivatedDate = (Case	
							When d.DeceasedDate <= c.ActivatedDate then Dateadd(day,1,c.ActivatedDate)
							Else d.DeceasedDate
						End)
FROM Derived.Customer as c 
INNER JOIN slc_report.dbo.fan d
	ON d.ID = c.FanID 
WHERE d.DeceasedDate IS NOT NULL 
	AND d.ClubID IN (132,138) 
	AND d.[Status] = 1
	AND c.CurrentlyActive = 1

SET @RowCount = @@ROWCOUNT

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_Deactivate_Deceased_Customers', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Customer_WGUpdate_V1_0 #############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_WGUpdate_V1_0', 'Starting'

UPDATE c 
	SET Rainbow_Customer = a.WG
FROM Derived.Customer as c
INNER JOIN Staging.SLC_Report_DailyLoad_Phase2DataFields as a
	ON c.FanID = a.FanID
WHERE c.Rainbow_Customer <> a.WG

EXEC Monitor.ProcessLog_Insert 'WHB', 'Customer_WGUpdate_V1_0', 'Finished'




RETURN 0