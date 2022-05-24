-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--Modified Date: 2017-08-30; Modified By: Rajshikha Jain; Jira Ticket: RBS-1574/1575

CREATE PROCEDURE [SmartEmail].[SFDDailyData]
with Execute as owner	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

---------------------------------------------------------------------------
------------Find customers who are not Marketable by EMail-----------------
---------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Marketable') IS NOT NULL DROP TABLE #Marketable
Select FanID
Into #Marketable
from warehouse.relational.customer as c
Where	c.MarketableByEmail = 0
		
Create clustered index cix_Marketable_FanID on #Marketable (FanID)

---------------------------------------------------------------------------
------------------Find customers who have a Birthday today-----------------
---------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Birthdays') IS NOT NULL DROP TABLE #Birthdays
Select	FanID
Into	#Birthdays
From Warehouse.relational.Customer as c
Where	Day(GETDATE()) = DAY(DOB) and
		Month(GETDATE()) = Month(DOB) and
		CurrentlyActive = 1
		
Create Clustered Index cix_Birthday_FanID on #Birthdays (FanID)

---------------------------------------------------------------------------
------------------Find the last 2 batches of Caffe Nero codes--------------
---------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Batches') IS NOT NULL DROP TABLE #Batches
Select top 2 BatchID
Into #Batches
From warehouse.relational.RedemptionCodeBatch as a
Where CodeTypeID = 1
Order by BatchID Desc

---------------------------------------------------------------------------
-------------------------------Get List of Bounced Customers---------------
---------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Hardbounced') IS NOT NULL DROP TABLE #Hardbounced
Select	Email,
		FanID
Into #Hardbounced
From warehouse.relational.Customer as c
Where Hardbounced = 1

Create Clustered Index cix_Hardbounced_FanID on #Hardbounced (FanID,Email)

---------------------------------------------------------------------------
-------------------Find the codes for people with birthdays----------------
---------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes
Select Max(rc.Code) as Code,rc.FanID
Into #Codes
From warehouse.relational.RedemptionCode as rc
inner join #Batches as b
	on	rc.BatchID = b.BatchID
inner join #Birthdays as a
	on  rc.FanID = a.FanID
Group by rc.FanID

Create Clustered Index cix_Codes_FanID on #Codes (FanID)

IF OBJECT_ID ('tempdb..#Fans') IS NOT NULL DROP TABLE #Fans
Select	--top (100000 )
		f.ID as FanID,
		f.Email,
		f.FirstName AS [FirstName],
		f.LastName as [LastName],
		Cast(f.dob as Date) as DOB,
		f.Sex,
		f.Title,
		f.AgreedTCSDate,
		f.ClubID,
		f.Postcode
Into #Fans
From slc_report.dbo.fan as f
Left Outer join #Hardbounced as hb
	on	f.id = hb.FanID and
		f.Email = hb.Email
Where		f.AgreedTCSDate is not null
		and f.AgreedTCs = 1
		and f.Status = 1
		and ClubID in (132,138)
		and (f.OfflineOnly = 0  or f.OfflineOnly is null)
		and f.DeceasedDate is null
		And Len(f.Email) >= 9
		and f.Email like '%@%._%'
		and f.Email Not like '%@%@%'
		and Right(f.Email,1) Not in ('@','.')
		and Left(f.Email,1)  not in ('@','.')
		and f.Email not like '%[:-?]%'
		and f.Email not like '%[\-^]%'
		and hb.FanID is null
--Select Count(*) From #Fans

Create Clustered Index cix_Fans_FanID on #Fans (FanID)
---2972406

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

Truncate table [SmartEmail].[DailyData]
--IF OBJECT_ID ('tempdb..#FinalData') IS NOT NULL DROP TABLE #FinalData
	Insert into [SmartEmail].[DailyData] ( [Email],[FanID],[ClubID],[ClubName],[FirstName],[LastName],[DOB],[Sex],[FromAddress],[FromName],[ClubCashAvailable],[ClubCashPending]
										  ,[PartialPostCode],[Title],[AgreedTcsDate],[WelcomeEmailCode],[IsDebit],[IsCredit],[Nominee],[RBSNomineeChange],[LoyaltyAccount]
										  ,[IsLoyalty],[FirstEarnDate],[FirstEarnType],[Reached5GBP],[Homemover],[Day60AccountName],[Day120AccountName],[JointAccount],[FulfillmentTypeID]
										  ,[CaffeNeroBirthdayCode],[ExpiryDate],[LvTotalEarning],[LvCurrentMonthEarning],[LvMonth1Earning],[LvMonth2Earning],[LvMonth3Earning]
										  ,[LvMonth4Earning],[LvMonth5Earning],[LvMonth6Earning],[LvMonth7Earning],[LvMonth8Earning],[LvMonth9Earning],[LvMonth10Earning],[LvMonth11Earning]
										  ,[LvCPOSEarning],[LvDPOSEarning],[LvDDEarning],[LvOtherEarning],[LvCurrentAnniversaryEarning],[LvPreviousAnniversaryEarning],[LvEAYBEarning]
										  ,[Marketable])
	SELECT
    --top (50000)
	f.Email,
	f.FanID,
	f.ClubID,
	'' as ClubName,
	f.FirstName AS [FirstName],
	f.LastName AS [Lastname],
	f.DOB as dob,
	f.Sex,
	'' as FromAddress,
	'' as FromName,
	bd.ClubCashAvailable AS ClubCashAvailable,
	bd.ClubCashPending-bd.ClubCashAvailable AS ClubCashPending,
	RIGHT(RTRIM(f.POSTCODE),3) AS [partial postcode],
	f.Title AS [Title],
	f.AgreedTcsDate,
	bd.WelcomeEmailCode,
--	f.ActivationChannel,
	bd.[IsDebit],
	bd.[IsCredit],
	Coalesce(CAST(dd.[Nominee] as Bit),0) as Nominee,
	Coalesce(CAST(dd.[RBSNomineeChange] as Bit),0) as RBSNomineeChange,
	CAST(p2df.LoyaltyAccount as Bit) as LoyaltyAccount,
	CAST(p2df.IsLoyalty as Bit) as IsLoyalty,
	p2df.FirstEarnDate,
	p2df.FirstEarnType,
	p2df.Reached5GBP,
	CAST(p2df.Homemover as Bit) as Homemover,
	pm.Day60AccountName,
	pm.Day120AccountName,
	CAST(pm.JointAccount as Bit) as JointAccount,
	Case
		When r.Redeemed = 1 then 1
		Else NULL
	End as FulfillmentTypeID,
	codes.Code as CaffeNeroBirthdayCode,
	Cast(Case
			When codes.Code IS not null then Dateadd(week,2,GETDATE())
			Else null
		 End as Date) as ExpiryDate,
	isnull(ltv.DDEarning,0)+isnull(ltv.DPOSEarning,0)+isnull(ltv.CPOSEarning,0)+isnull(ltv.OtherEarning,0) as LVTotalEarnings,
	0 as LVCurrentMonthEarning,
	0 as LvMonth1Earning,
	0 as LvMonth2Earning,
	0 as LvMonth3Earning,
	0 as LvMonth4Earning,
	0 as LvMonth5Earning,
	0 as LvMonth6Earning,
	0 as LvMonth7Earning,
	0 as LvMonth8Earning,
	0 as LvMonth9Earning,
	0 as LvMonth10Earning,
	0 as LvMonth11Earning,
	isnull(ltv.CPOSEarning,0),
	isnull(ltv.DPOSEarning,0),
	isnull(ltv.DDEarning,0),
	isnull(ltv.OtherEarning,0),
	isnull(ltv.CurrentAnniversaryEarning,0),
	isnull(ltv.PreviousAnniversaryEarning,0),
	0 as LvEAYBEarning,
	Case
		When m.FanID IS null then 1
		Else 0
	End as Marketable
--Into #FinalData
FROM #Fans f WITH (NOLOCK)
	INNER JOIN slc_report.dbo.FanSFDDailyUploadData bd ON f.FanID = bd.FanID
	INNER JOIN slc_report.dbo.FanCredentials c WITH (NOLOCK) ON f.Fanid = c.FanID
	--LEFT JOIN slc_report.Zion.Member_OneClickActivation z WITH (NOLOCK) ON f.FanID = z.FanID AND COALESCE(z.LinkActive,1) = 1
	LEFT JOIN slc_report..[FanSFDDailyUploadData_DirectDebit] dd on f.FanID = dd.FanID
	LEFT JOIN Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields p2df on f.FanID = p2df.FanID
	LEFT JOIN Warehouse.Staging.SLC_Report_ProductMonitoring pm on f.FanID = pm.FanID
	Left JOIN slc_report.zion.Member_LifeTimeValue as ltv on f.FanID = ltv.FanID
	Left JOIN #Marketable as m on f.FanID = m.fanid
	Left Join #Codes as codes on f.FanID = codes.FanID
	Left Outer join [Warehouse].[Relational].[Customers_Reach5GBP] as r on f.FanID = r.FanID

END