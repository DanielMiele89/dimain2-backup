
/*
Author:		Stuart Barnley
Date:		23rd September 2013
Purpose:	To Build the Customer table first IN the Staging AND THEN Relational schema of the Warehouse database

Notes:		Amended to remove LaunchedTo AND Control group customers who are no longer needed IN this table.
			19-02-2014 SB - Sort out indexes ON Customer table to speed up population time (unused indexes removed).
			17-04-2014 SC - added 19587579 to exclusion list - this is a fake record
			29-04-2014 SB - Amended to find all customers who ever activated, some tidying done at the same time
			20-08-2014 SC - Removed Account Key FROM Staging.Customer
			09-09-2014 SC - Added Primary Key AND altered all indexing
			30-09-2014 SB - Remove FROM Staging.Customers those customers IN the Staging.Customer_TobeExcluded table.

CJM 20161116 see ln215
*/
CREATE PROCEDURE [WHB].[Customer_Customer_V2_RF_Dev]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	INSERT INTO staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = NULL,
			TableRowCount  = NULL,
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers who's AgreedTCs was removed-------------------------
	----------------------------------------------------------------------------------------------------*/

	IF OBJECT_ID('tempdb..#PrevAct') IS NOT NULL DROP TABLE #PrevAct
	SELECT	FanID
		,	[Date] AS AgreedTCs
	INTO #PrevAct
	FROM [Staging].[InsightArchiveData] iad
	WHERE iad.TypeID = 1 
	
	CREATE CLUSTERED INDEX CIX_PrevAct_Fan ON #PrevAct (FanID)

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers last succesful email-------------------------
	----------------------------------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#LastEmail') IS NOT NULL DROP TABLE #LastEmail
	SELECT	e.FanID
		,	MAX(e.EventDate) AS EventDate
	INTO #LastEmail
	FROM (	SELECT	ee.FanID
				,	MAX(ee.EventDate) AS EventDate
			FROM [Relational].[EmailEvent] ee
			WHERE EmailEventCodeID IN (901, 910)
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[EmailEvent] ee_hb
							WHERE ee.FanID = ee_hb.FanID
							AND ee.CampaignKey = ee_hb.CampaignKey
							AND ee_hb.EmailEventCodeID IN (702))
			GROUP BY FanID
			UNION ALL
			SELECT	ea.FanID
				,	MAX(ea.DeliveryDate) AS DeliveryDate
			FROM [SLC_Report].[dbo].[EmailActivity] ea
			WHERE ea.HardBounceDate IS NOT NULL
			GROUP BY ea.FanID) e
	GROUP BY e.FanID
	
	CREATE CLUSTERED INDEX CIX_EmailEvent_Fan ON #LastEmail (FanID, EventDate)

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers unsubscribed-------------------------
	----------------------------------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#Unsubscribed') IS NOT NULL DROP TABLE #Unsubscribed
	SELECT e.FanID
		 , MAX(UnsubscribedDate) AS UnsubscribedDate
	INTO #Unsubscribed
	FROM (	SELECT	ee.FanID
				,	MAX(ee.Date) AS UnsubscribedDate
			FROM [SLC_Report].[dbo].[EmailEvent] ee
			WHERE EmailEventCodeID IN (301)
			GROUP BY FanID
			--UNION ALL
			--SELECT	ea.FanID
			--	,	MAX(ea.UnsubscribeDate) AS UnsubscribedDate
			--FROM [SLC_Report].[dbo].[EmailActivity] ea
			--WHERE ea.UnsubscribeDate IS NOT NULL
			--GROUP BY ea.FanID
			) e
	GROUP BY e.FanID
	
	CREATE CLUSTERED INDEX CIX_EmailEvent_Fan ON #Unsubscribed (FanID, UnsubscribedDate)

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers hard bounces-------------------------
	----------------------------------------------------------------------------------------------------*/
		
	IF OBJECT_ID('tempdb..#Hardbounced') IS NOT NULL DROP TABLE #Hardbounced
	SELECT e.FanID
		 , MAX(HardbouncedDate) AS HardbouncedDate
	INTO #Hardbounced
	FROM (	SELECT	ee.FanID
				,	MAX(ee.EventDate) AS HardbouncedDate
			FROM [Relational].[EmailEvent] ee
			WHERE EmailEventCodeID IN (702)
			GROUP BY FanID
			UNION ALL
			SELECT	ea.FanID
				,	MAX(ea.HardbounceDate) AS HardbouncedDate
			FROM [SLC_Report].[dbo].[EmailActivity] ea
			WHERE ea.HardbounceDate IS NOT NULL
			GROUP BY ea.FanID) e
	GROUP BY e.FanID

	CREATE CLUSTERED INDEX CIX_FanDate ON #Hardbounced (FanID, HardbouncedDate)
	
	DELETE hb
	FROM #Hardbounced hb
	WHERE EXISTS (	SELECT 1
					FROM [Staging].[Customer_EmailAddressChanges_20150101] eac
					WHERE hb.FanID = eac.FanID
					AND hb.HardbouncedDate < eac.DateChanged)
					
	DELETE hb
	FROM #Hardbounced hb
	WHERE EXISTS (	SELECT 1
					FROM #LastEmail le
					WHERE hb.FanID = le.FanID
					AND hb.HardbouncedDate < le.EventDate)


	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Create CustomerAttribute Table-----------------------------------
	----------------------------------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#CustomerAttribute') IS NOT NULL DROP TABLE #CustomerAttribute
	SELECT	DISTINCT
			FanID
	INTO #CustomerAttribute
	FROM [Relational].[CustomerAttribute] ca
	INNER JOIN [Relational].[CINList] CL
		ON ca.CinID = CL.CinID
	INNER JOIN [Relational].[Customer] c
		ON cl.CIN = c.SourceUID
	WHERE BankID > 2
	
	CREATE CLUSTERED INDEX CIX_CustomerAttribute_Fan ON #CustomerAttribute (FanID)
	
	------------------------------------------------------------------------
	-------------INSERT Main Data IN Staging.Customer Table-----------------
	------------------------------------------------------------------------

	DECLARE @LaunchDate Date = 'Aug 08, 2013'

	TRUNCATE TABLE [Staging].[Customer_RF]
	INSERT INTO [Staging].[Customer_RF]
	SELECT	f.ID AS FanID
		,	CASE
				WHEN f.AgreedTCs = 0 THEN 0
				WHEN f.AgreedTCsDate IS NULL THEN 0
				ELSE f.Status
			END AS [Status]
		,	CONVERT(VARCHAR(20), f.SourceUID) AS SourceUID   --this links to CIN IN the data FROM RBS
		,	f.DOB AS DOB
		,	CONVERT(VARCHAR(20), f.Title) AS Title
		,	CONVERT(VARCHAR(50), f.FirstName) AS FirstName
		,	CONVERT(VARCHAR(50), f.LastName) AS LastName
		,	CONVERT(VARCHAR(100), f.Address1) AS Address1
		,	CONVERT(VARCHAR(100), f.Address2) AS Address2
		,	CONVERT(VARCHAR(100), f.City) AS City
		,	CONVERT(VARCHAR(100), f.County) AS County
		,	CONVERT(VARCHAR(10), ISNULL(LTRIM(RTRIM(f.Postcode)), '')) AS PostCode
		,	CONVERT(VARCHAR(10), ISNULL(REPLACE(REPLACE(f.Postcode, Char(160), ''), ' ', ''), '')) AS Postcode_SpacesRemoved
		,	CONVERT(VARCHAR(100), f.Email) AS Email
		,	CONVERT(DATE, COALESCE(pa.AgreedTCs, f.AgreedTCsDate)) AS AgreedTCsDate		--Date Activated
		,	CONVERT(BIT, COALESCE(OfflineOnly,0)) AS OfflineOnly			--Activated at contact centre
		,	CONVERT(BIT, ContactByPost) AS ContactByPost		--This is set by a tick box within the CBP Site. It is ticked by default, indicating agreement to receive direct mail
			--***************************************************************************
			--*******************Start To be reviewed at later point*********************
			--***************************************************************************
		,	CASE
				WHEN CONVERT(BIT, f.Unsubscribed) = 1 THEN 1
				WHEN us.UnsubscribedDate IS NOT NULL THEN 1
				ELSE 0
			END AS Unsubscribed
		,	CASE
				WHEN EXISTS (SELECT 1 FROM #Hardbounced hb WHERE f.ID = hb.FanID) THEN 1
				ELSE 0 
			END AS Hardbounced
			--***************************************************************************
			--********************END To be reviewed at later point**********************
			--***************************************************************************
		,	CONVERT(BigInt, f.CompositeID) AS CompositeID
		,	CONVERT(Char(1), a.Primacy) AS Primacy
		,	CONVERT(BIT, a.IsJoint) AS IsJoint
		,	CONVERT(TinyInt, a.ControlGroupNumber) AS ControlGroupNumber
		,	CONVERT(TinyInt, a.ReportGroup) AS ReportGroup
		,	CONVERT(TinyInt, a.TreatmentGroup) AS TreatmentGroup
		,	CONVERT(Char(4), a.LaunchGroup) AS LaunchGroup
		,	CONVERT(BIT, a.OriginalEmailPermission) AS OriginalEmailPermission
		,	CONVERT(BIT, a.OriginalDMPermission) AS OriginalDMPermission
		,	CONVERT(BIT, a.EmailOriginallySupplied) AS EmailOriginallySupplied
		,	CONVERT(TinyInt,	CASE	
									WHEN f.DOB > CONVERT(Date, GetDate()) THEN 0
									WHEN month(f.DOB) > month(GetDate()) THEN DateDiff(yyyy, f.DOB, GetDate()) - 1 
									WHEN month(f.DOB) < month(GetDate()) THEN DateDiff(yyyy, f.DOB, GetDate()) 
									WHEN month(f.DOB) = month(GetDate()) THEN CASE
																			  	  WHEN day(f.DOB) > day(GetDate()) THEN DateDiff(yyyy, f.DOB,GetDate()) - 1 
																			  	  ELSE DateDiff(yyyy,f.DOB,GetDate()) 
																			  END 
								END) AS AgeCurrent
		,	CONVERT(TinyInt, NULL) AS AgeAtLaunch
		,	CONVERT(TinyInt, NULL) AS AgeCurrentBandNumber
		,	CONVERT(Char(1),	CASE
									WHEN f.Sex = 1 THEN 'M'
									WHEN f.Sex = 2 THEN 'F'
									ELSE 'U'
								END) AS Gender
		,	CONVERT(VARCHAR(6), NULL) AS PostalSector
		,	CONVERT(VARCHAR(4),		CASE 
										WHEN f.Postcode IS NULL THEN ''
										WHEN CharIndex(' ', f.PostCode) = 0 THEN CONVERT(VARCHAR(4), f.PostCode) 
										ELSE Left(f.PostCode, CharIndex(' ', f.PostCode) - 1) 
									END) AS PostCodeDistrict
		,	CONVERT(VARCHAR(2), CASE 
									WHEN f.Postcode IS NULL THEN ''
									WHEN f.PostCode Like '[A-Z][0-9]%' THEN Left(f.PostCode, 1) 
									ELSE Left(f.PostCode, 2) 
								END) AS PostArea
		,	CONVERT(VARCHAR(30), NULL) AS Region
		,	CONVERT(BIT,	CASE 
								WHEN f.Email Like '%@%.%' AND f.Email NOT Like '%@%.'			
									 AND f.Email NOT Like '@%.%' AND f.Email NOT Like '@.%'		
									 AND f.Email NOT Like '%@%@%' AND f.Email NOT Like '%[:-?]%' 
									 AND f.Email NOT Like '%,%' AND LTrim(RTrim(f.Email)) NOT Like '% %' 
									 AND Len(LTrim(RTrim(f.Email))) >= 9 THEN 1 
								ELSE 0 
							END) AS EmailStructureValid
		,	CONVERT(BIT, NULL) AS MarketableByEmail
		,	CONVERT(BIT, NULL) AS MarketableByDirectMail
		,	CONVERT(BIT,	CASE
								WHEN eno.FanID IS NULL THEN 0
								ELSE 1
							END) AS EmailNonOpener
		,	f.MobileTelephone AS MobileTelephone
		,	CONVERT(BIT,	CASE
								WHEN (Left(Replace(f.MobileTelephone, ' ', ''), 2) Like '07' OR Left(Replace(f.MobileTelephone,' ',''),4) Like '+447')
									AND Len(Replace(f.MobileTelephone, ' ', '')) >= 11 THEN 1
								ELSE 0
							END) AS ValidMobile
		,	CONVERT(VARCHAR(100),	CASE
										WHEN Len(Replace(f.Title, ' ', '')) > 1 THEN 'Dear ' + f.Title + ' ' + f.LastName
										WHEN (Len(Replace(f.Title, ' ', '')) <= 1 OR f.Title IS NULL) AND f.Sex = 1 THEN 'Dear Mr ' + f.LastName
										ELSE NULL
									END) AS Salutation
		,	CONVERT(BIT, a.CurrentEmailPermission) AS CurrentEmailPermission
		,	CONVERT(BIT, a.CurrentDMPermission) AS CurrentDMPermission
		,	f.ClubID
		,	CASE
				WHEN f.Status = 0 OR f.AgreedTCs = 0 OR f.AgreedTCsDate IS NULL THEN ca.DeactivatedDate
				ELSE NULL
			END AS DeactivatedDate
		,	CASE
				WHEN f.Status = 0 OR f.AgreedTCs = 0 OR f.AgreedTCsDate IS NULL THEN ca.OptedOutDate
				ELSE NULL
			END AS OptedOutDate
		,	CONVERT(BIT, NULL) AS CurrentlyActive
		,	CASE
				WHEN cb.FanID IS NULL THEN 0
				WHEN cb.Activated = 1 THEN 1
				ELSE 0
			END AS POC_Customer
		,	CASE
				WHEN Rainbow.FanID IS NULL THEN 0
				ELSE 1
			END AS Rainbow_Customer
	FROM [SLC_Report].[dbo].[Fan] f
	LEFT JOIN #Unsubscribed us
		on f.ID = us.FanID
	LEFT JOIN [Archive_Light].[Prod].[NobleFanAttributes] a 
		on f.CompositeID = a.CompositeID
	LEFT JOIN #PrevAct AS pa
		on f.ID = pa.FanID
	LEFT JOIN [MI].[CustomerActiveStatus] ca
		on f.ID = ca.FanID
	LEFT JOIN [InsightArchive].[Customer_Backup20130724] AS cb
		on f.ID = cb.FanID
	LEFT JOIN #CustomerAttribute AS Rainbow
		on f.ID = Rainbow.FanID
	LEFT JOIN [Staging].[EmailNonOpener] eno
		ON f.ID = eno.FanID
	WHERE f.ClubID IN (132,138)
	AND (f.AgreedTCs = 1 OR Not(pa.AgreedTCs IS NULL))
	AND f.ID NOT IN (19587579)

	------------------------------------------------------------------------
	-----------------------Enchance Customer Data Part 1--------------------
	------------------------------------------------------------------------

	CREATE NONCLUSTERED INDEX IX_Postcode_SpacesRemoved ON [Staging].[Customer_RF] (Postcode_SpacesRemoved)

	UPDATE cu
	SET	PostalSector =	CASE
							WHEN cu.Postcode_SpacesRemoved Like '[a-z][0-9][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 2) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 3), 1)

							WHEN cu.Postcode_SpacesRemoved Like '[a-z][0-9][0-9][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 4), 1)
							WHEN cu.Postcode_SpacesRemoved Like '[a-z][a-z][0-9][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 4), 1)
							WHEN cu.Postcode_SpacesRemoved Like '[a-z][0-9][a-z][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 4), 1)

							WHEN cu.Postcode_SpacesRemoved Like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 4) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 5), 1)
							WHEN cu.Postcode_SpacesRemoved Like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]' THEN LEFT(cu.Postcode_SpacesRemoved, 4) + ' ' + RIGHT(LEFT(cu.Postcode_SpacesRemoved, 5), 1)
							ELSE ''
						END
	,	cu.AgeCurrentBandNumber =	CASE 
										WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN 1
										WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN 2
										WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN 3
										WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN 4
										WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN 5
										WHEN cu.AgeCurrent BETWEEN 65 AND 80 THEN 6
										WHEN cu.AgeCurrent BETWEEN 81 AND 110 THEN 7
										ELSE 0
									END
	,	cu.AgeCurrentBandText =		CASE
										WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '18 to 24'
										WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '25 to 34'
										WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '35 to 44'
										WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '45 to 54'
										WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '55 to 64'
										WHEN cu.AgeCurrent BETWEEN 65 AND 80 THEN '65 to 80'
										WHEN cu.AgeCurrent BETWEEN 81 AND 110 THEN '81+' 
										ELSE 'Unknown'
									END
	FROM [Staging].[Customer_RF] cu

	UPDATE cu
	SET cu.Region = pa.Region
	FROM [Staging].[Customer_RF] cu
	LEFT JOIN [Staging].[PostArea] pa
		ON	CASE
				WHEN cu.PostCode LIKE '[A-Z][0-9]%' THEN LEFT(Postcode_SpacesRemoved, 1)
				ELSE LEFT(cu.Postcode_SpacesRemoved, 2)
			END = pa.PostAreaCode

	DROP INDEX IX_Postcode_SpacesRemoved ON [Staging].[Customer_RF]

	------------------------------------------------------------------------
	-----------------------Enchance Customer Data Part 3--------------------
	------------------------------------------------------------------------

	DECLARE @Today DATE = GetDate()

	UPDATE cu
	SET	MarketableByEmail =		CASE
									WHEN Unsubscribed = 0			--customer has NOT unsubscribed.
										AND	Hardbounced = 0				--email address has NOT hardbounced.
										AND EmailStructureValid = 1		--result of basic structutral validation above
										AND 3 <= LEN(Postcode)			--customer has at least partial postcode
										AND Status > 0					--account is active
										--AND OfflineOnly = 0			--customer has NOT activated offline at contact centre
										AND AgreedTCsDate IS NOT NULL
										THEN 1
									ELSE 0 
								END
	 , MarketableByDirectMail =	CASE 
									WHEN LaunchGroup IS NOT NULL			--as above
										 AND NOT LaunchGroup = 'INIT'		--etc
										 AND Status > 0						--etc
										 AND ContactByPost = 1				--This is set by a tick box within the CBP Site. It is ticked by default, indicating agreement to receive direct mail
										 AND (EmailStructureValid = 0 OR HardBounced = 1)  --In the DM cells OR activated but have undeliverable email address					 
										 AND NOT (EmailStructureValid = 1 AND Hardbounced = 0 AND Unsubscribed = 0)
								  --	 AND IsControl = 0					--etc
									THEN 1
									ELSE 0 
							    END
	 , CurrentlyActive =		CASE
									WHEN DeactivatedDate IS NULL
										AND OptedOutDate IS NULL
										AND Status = 1
										AND AgreedTCsDate <= @Today
									THEN 1
									ELSE 0
								END
	FROM [Staging].[Customer_RF] cu

	/*--------------------------------------------------------------------------------------------------
	---------------------------------Delete Customer who need excluding---------------------------------
	----------------------------------------------------------------------------------------------------*/

	DELETE cu
	FROM [Staging].[Customer_RF] cu
	WHERE EXISTS (	SELECT 1
					FROM [Staging].[Customer_TobeExcluded] ctbe
					WHERE cu.FanID = ctbe.FanID)

	/*--------------------------------------------------------------------------------------------------
	---------------------------Call Store Procedure to look for Deactivation Dates----------------------
	----------------------------------------------------------------------------------------------------*/

			---------------------------------------------------------------------------------------
			-----------Find those customers who are deactivated with no DeactivatedDate------------
			---------------------------------------------------------------------------------------
			/*DeactivatedDate is populated off of a table end produces based on an assessment of the
			  changelog, therefore I am finding dates for those catered for by this*/

			IF OBJECT_ID('tempdb..#DeactivatedCustomers') IS NOT NULL DROP TABLE #DeactivatedCustomers
			select FanID,AgreedTCsDate as ActivatedDate
			Into #DeactivatedCustomers 
			from [Staging].[Customer_RF] as c
			where	status = 0 and 
					deactivateddate is NULL
			---------------------------------------------------------------------------------------
			-----------------Find comment that indicates the Fan was Deactivated-------------------
			---------------------------------------------------------------------------------------
			/*This comment is normally generated by an overnight process checking valid Pans and 
			  Fans etc*/
			IF OBJECT_ID('tempdb..#Comm_Deact') IS NOT NULL DROP TABLE #Comm_Deact
			Select c.FanID,Max([Date]) as Deact_Date
			Into #Comm_Deact
			from [SLC_Report].[dbo].[Comments]  as c
			inner join #DeactivatedCustomers as dc
				on	c.FanID = dc.FanID
			Where	c.Comment Like  'Fan Deactivated%' and
					c.[Date] >= DC.ActivatedDate
			Group by c.FanID
			---------------------------------------------------------------------------------------
			----------------------Find Date from DeactivatedCustomer table-------------------------
			---------------------------------------------------------------------------------------
			/*We started populating this table a while ago (July 2012) before the changelog was 
			  even conceived.Every week it stored all the activated customers with Status zero and 
			  the date */
			IF OBJECT_ID('tempdb..#DeactTable') IS NOT NULL DROP TABLE #DeactTable
			Select	Dc.FanID, 
					Min(DataDate) as Deact_Date
			into #DeactTable
			from #DeactivatedCustomers as DC
			inner join [Staging].[DeactivatedCustomers] as c
				on dc.FanID = c.FanID
			Left Outer join #Comm_Deact as cd
				on dc.FanID = cd.FanID
			Where	cd.FanID is NULL
			Group by DC.FanID
				Having Min(DataDate) > 'Jul 17, 2012' -- ignore those from first week.
			---------------------------------------------------------------------------------------
			----------------------Find List of those still without deactivateddate-----------------
			---------------------------------------------------------------------------------------
			IF OBJECT_ID('tempdb..#D') IS NOT NULL DROP TABLE #D
			Select dc.FanID,dc.ActivatedDate
			into #D
			from #DeactivatedCustomers as dc
			Left Outer join #Comm_Deact as cd
				on dc.FanID = cd.FanID
			Left Outer join #DeactTable as d
				on dc.FanID = d.FanID
			Where cd.fanid is NULL and d.fanid is NULL

			---------------------------------------------------------------------------------------
			----------------------Find other Comment entries to use for date-----------------------
			---------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#Comm_Deact2') IS NOT NULL DROP TABLE #Comm_Deact2
			Select c.ObjectID,Max([Date]) as Deact_Date
			Into #Comm_Deact2
			from [SLC_Report].[dbo].[Comments]  as c
			inner join #DeactivatedCustomers as dc
				on	c.ObjectID = dc.FanID
			Left Outer Join
				(Select * 
				 from #Comm_Deact
				 union all
				 Select * 
				 from #DeactTable
				 )as a
				on dc.FanID = a.fanid
			Where	(c.Comment Like '%Opt_Out%' or
					 c.Comment Like '%Account_Close%' or
					 c.Comment Like '%Close_Account%' or
					 c.Comment like '%Disabled%' or
					 c.Comment like '%Deceased%' or
					 c.Comment like '%Died%' or
					 c.Comment like '%Removed_Scheme%' or
					 c.Comment like '%Pan Deactivated%'
					 ) and
					c.[Date] >= DC.ActivatedDate and
					a.FanID is NULL
			Group by c.ObjectID

			---------------------------------------------------------------------------------------
			-------------------------Create a table of Deac dates----------------------------------
			---------------------------------------------------------------------------------------
			/*Where no other date could be found we put in the Activation Date*/
			IF OBJECT_ID('tempdb..#Deactivations') IS NOT NULL DROP TABLE #Deactivations
			Select Dc.* ,
					Case
						When a.Deact_Date IS NULL then dc.ActivatedDate
						Else a.Deact_Date
					End as DDate
			Into #Deactivations
			from #DeactivatedCustomers as dc
			left outer join
				(Select * 
				 from #Comm_Deact
				 union all
				 Select * 
				 from #DeactTable
				 union all
				 Select * 
				 from #Comm_Deact2) as a
				on dc.FanID = a.fanid
			---------------------------------------------------------------------------------------
			--------------------------------Update Customer Table----------------------------------
			---------------------------------------------------------------------------------------
			Update [Staging].[Customer_RF]
			Set DeactivatedDate = DDate
			From [Staging].[Customer_RF] as c
			Inner join #Deactivations as D
				on C.FanID = D.FanID
			Where	C.AgreedTCsDate is not NULL and
					c.Status = 0

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry IN JobLog Table with END Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  [Staging].[JobLog_temp]
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			EndDate IS NULL
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry IN JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately AS WHEN table grows this AS a task ON its own may take several minutes AND we do
	--not want it included IN table creation times
	Update  [Staging].[JobLog_temp]
	Set		TableRowCount = (SELECT COUNT(*) FROM Staging.Customer)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			TableRowCount IS NULL
	
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	INSERT INTO [Staging].[JobLog_temp]
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = NULL,
			TableRowCount  = NULL,
			AppendReload = 'R'
		
	------------------------------------------------------------------------
	--------------------Create Relational.Customer Table--------------------
	------------------------------------------------------------------------
	
	ALTER INDEX i_SourceUID		ON	[Relational].[Customer_RF] DISABLE
	ALTER INDEX i_CompositeID	ON	[Relational].[Customer_RF] DISABLE
	ALTER INDEX i_PostArea		ON	[Relational].[Customer_RF] DISABLE

	TRUNCATE TABLE [Relational].[Customer_RF]
	INSERT INTO [Relational].[Customer_RF]
	SELECT FanID
		 , SourceUID
		 , CompositeID
		 , [Status]
		 , Gender
		 , Title
		 , FirstName
		 , LastName
		 , Salutation
		 , Address1
		 , Address2
		 , City
		 , County
		 , PostCode
		 , PostalSector
		 , PostCodeDistrict
		 , PostArea
		 , Region
		 , Email
		 , Unsubscribed
		 , Hardbounced
		 , EmailStructureValid
		 , MobileTelephone
		 , ValidMobile
		 , Primacy
		 , IsJoint
		 , ControlGroupNumber
		 , ReportGroup
		 , TreatmentGroup
		 , LaunchGroup
		 , 1/*AgreedTCs*/ AS Activated
		 , AgreedTCsDate AS ActivatedDate
		 , OfflineOnly AS ActivatedOffline
		 , MarketableByEmail
		 , MarketableByDirectMail
		 , EmailNonOpener
		 , OriginalEmailPermission --These fields removed (15 March 2012) AS potentially confusing AND NOT needed
		 , OriginalDMPermission	 --Added back IN 22 March 2012
		 , EmailOriginallySupplied
		 , CurrentEmailPermission
		 , CurrentDMPermission			
		 , DOB
		 , AgeCurrent
		 , AgeCurrentBandNumber
		 , AgeCurrentBandText
		 , ClubID
		 , DeactivatedDate
		 , OptedOutDate
		 , CurrentlyActive
		 , POC_Customer
		 , Rainbow_Customer
		 , 0 AS Registered
	FROM [Staging].[Customer_RF]
		
	ALTER INDEX i_SourceUID		ON	[Relational].[Customer_RF] REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX i_CompositeID	ON	[Relational].[Customer_RF] REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX i_PostArea		ON	[Relational].[Customer_RF] REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry IN JobLog Table with END Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  [Staging].[JobLog_Temp]
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate IS NULL
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry IN JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately AS WHEN table grows this AS a task ON its own may take several minutes AND we do
	--not want it included IN table creation times
	Update  [Staging].[JobLog_Temp]
	Set		TableRowCount = (SELECT COUNT(*) FROM [Relational].[Customer_RF])
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			TableRowCount IS NULL

	INSERT INTO [Staging].[JobLog]
	SELECT [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	FROM [Staging].[JobLog_Temp]
	TRUNCATE TABLE [Staging].[JobLog_Temp]

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
			
	-- INSERT the error INTO the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' IN [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END