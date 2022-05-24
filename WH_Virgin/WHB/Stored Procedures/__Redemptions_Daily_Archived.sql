
/*
-- Replaces this bunch of stored procedures:
EXEC WHB.Redemptions_RedemptionItem_V1_13
EXEC WHB.Redemptions_Redemptions_V1_12
EXEC WHB.Redemptions_Ecodes
EXEC WHB.Redemptions_ElectronicRedemptionsReport_ProcessAndSend
*/

CREATE PROCEDURE [WHB].[__Redemptions_Daily_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_RedemptionItem_V1_13 ###################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_RedemptionItem_V1_13', 'Starting'

	--Insert Suggested Redemptions in RedemptionItem Table------------------
	/*This section is used to add the new redemptions that have been used by CashBack customers to
	  the redemptions table with the suggested Redemption types. The Type identification will need to 
	  be updated in line with the checking phase
	*/
If Object_ID('tempdb..#RedeemItems') Is Not Null Drop Table #RedeemItems
select
	r.ID as RedeemID,
	Case
	When r.ID in (7191,7192) then 'Trade Up'
	When r.Privatedescription like '%Donation to%' Then 'Charity'
	When r.Privatedescription like '%Donate%' Then 'Charity'
	When r.Privatedescription like '%gift card % CashbackPlus Rewards%' Then 'Trade Up'
	When r.Privatedescription like '%gift Code %' Then 'Trade Up'
	When r.Privatedescription like '%tickets % CashbackPlus Rewards%' Then 'Trade Up'
	When r.Privatedescription like 'Cash to bank account' Then 'Cash'
	When r.Privatedescription like '%RBS Current Account%' Then 'Cash'
	When r.Privatedescription like '%Pay towards your Cashback Plus Credit Card%' then 'Cash'
	When r.Privatedescription like '%for £_ Rewards%' then 'Trade Up'
	When r.Privatedescription like '%for £__ Rewards%' then 'Trade Up'
	When r.Privatedescription like '%Caff%Nero%' then 'Trade Up'
	End as RedeemType,
	r.Privatedescription,
	Cast(Null as int) as PartnerID,
	Cast(Null as [varchar](100)) as [PartnerName],
	Cast(Null as [int]) as [TradeUp_WithValue],
	Cast(Null as [smallmoney]) as [TradeUp_ClubcashRequired],
	Cast(Null as [smallmoney]) as [TradeUp_Value],
	Cast(Null as Bit) as [Status]
Into #RedeemItems
from  Derived.Customer c
INNER JOIN slc_report.dbo.Trans t 
	on t.FanID = c.FanID
INNER JOIN slc_report.dbo.Redeem r 
	on r.id = t.ItemID
INNER JOIN slc_report.dbo.RedeemAction ra 
	on t.ID = ra.transid and ra.Status = 1     
LEFT JOIN Staging.RedemptionItem as ri 
	on t.itemid = ri.redeemid
where	t.TypeID=3 
	and ri.redeemid is null
group by r.Privatedescription, r.ID 
	
	

--Deal with Problem redemption items--------------------------------
UPDATE ri
SET RedeemType = 'Trade Up',
	TradeUP_WithValue = 1,
	TradeUp_ClubcashRequired = r.TradeUp_ClubcashRequired,
	TradeUp_Value = r.TradeUp_Value
FROM #RedeemItems as ri
INNER JOIN Derived.RedemptionItem_TradeUpValue  as r
	on ri.RedeemID = r.RedeemID


--Deal with Problem redemption items--------------------------------
/* ChrisM note - this doesn't work, it sets every row of #RedeemItems to Cafe Nero
But it's corrected in the next statement!!
UPDATE #RedeemItems
SET PartnerID = a.PartnerID,
	PartnerName = p.PartnerName
FROM (
	Select Case
		When RedeemType = 'Trade Up' and PrivateDescription like '%digital magazines for %Rewards%' then 1000000
		When RedeemType = 'Trade Up' and replace(replace(PrivateDescription,' ',''),'&','') like '%CurrysPCWorld%' then 4001
		When PrivateDescription like '%Caff_ Nero%' then 4319
		When RedeemType = 'Trade Up' Then P.PartnerID
		Else NULL
		End as PartnerID,
		r.RedeemID
	From #RedeemItems as r
	left join Derived.Partner as p
		on	r.PrivateDescription like '%'+p.partnername+'%' 
		and r.PrivateDescription not like '%Currys%' 
		and r.PrivateDescription not like '%PC World%'
) as a
INNER JOIN Derived.Partner as p
	on a.PartnerID = p.PartnerID
*/

UPDATE ri
SET		PartnerID = p.PartnerID,
		PartnerName = p.PartnerName
FROM #RedeemItems as ri
INNER JOIN Derived.RedemptionItem_TradeUpValue as t
	on	ri.RedeemID = t.RedeemID
INNER JOIN Derived.partner as p
	on  t.PartnerID = p.PartnerID
WHERE	ri.PartnerID is null and
		t.partnerid is not null

--Create Relational.RedemptionItem lookup Table-------------------------
TRUNCATE TABLE Derived.RedemptionItem
INSERT INTO Derived.RedemptionItem
SELECT RedeemID
		, RedeemType
		, PrivateDescription
		, Status
FROM #RedeemItems ri


EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_RedemptionItem_V1_13', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_Redemptions_V1_12 ######################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Redemptions_V1_12', 'Starting'

-- Pull out a list of Cancelled redemptions --------------------------
if object_id('tempdb..#Cancelled') is not null drop table #Cancelled
select ItemID as TransID,1 as Cancelled
Into #Cancelled
from SLC_Report.dbo.trans t2 where t2.typeid=4

Create Clustered index cix_Cancelled_ItemID on #Cancelled (TransID)

--Pull out a list of redemptions including those later cancelled-----------------------
if object_id('tempdb..#Redemptions') is not null drop table #Redemptions
SELECT	t.FanID, -- 50% of overall sp cost
		c.CompositeID,
		t.id as TranID,
		Min(t.Date) as RedeemDate,
		ri.RedeemType,
		r.Description as PrivateDescription,
		t.Price,
		tuv.TradeUp_Value,
		tuv.PartnerID,
		Coalesce(Cancelled.Cancelled,0) Cancelled, 
		CAST(CASE WHEN t.[Option] = 'Yes I am a UK tax payer and eligible for gift aid' then 1 else 0 end AS BIT) AS GiftAid
INTO #Redemptions        
FROM Derived.Customer c
inner join SLC_Report.dbo.Trans t 
	on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r 
	on r.id = t.ItemID
LEFT JOIN #Cancelled as Cancelled 
	ON Cancelled.TransID = T.ID
inner join SLC_Report.dbo.RedeemAction ra 
	on t.ID = ra.transid and ra.Status in (1,6)
left join Derived.RedemptionItem as ri 
	on t.ItemID = ri.RedeemID
left join Derived.RedemptionItem_TradeUpValue as tuv
	on ri.RedeemID = tuv.RedeemID    
WHERE t.TypeID = 3
	AND T.Points > 0
GROUP BY t.FanID, c.CompositeID, t.id, ri.RedeemType, r.[Description], t.Price, tuv.TradeUp_Value, Coalesce(Cancelled.Cancelled,0), tuv.PartnerID, t.[Option]
-- (12,720,878 rows affected) / 00:10:38


--Create the redemption description from the Private Description-----------------------
/*The description provided need some changing to make them more accurately represent that which they are supposed to, such as:

		* Remove the amount off the donation option chosen as this doesn't always match the amount given
		* fix fix how '£' and '&' symbols are displayed
		* Remove formatting reference for the name CashbackPlus
*/

ALTER INDEX IDX_FanID ON Derived.Redemptions DISABLE

TRUNCATE TABLE Derived.Redemptions
INSERT INTO Derived.Redemptions
SELECT	
	FanID,
	CompositeID,
	TranID,
	RedeemDate,
	RedeemType,
	replace(replace(replace(replace(
	Case
		When left(Ltrim(rtrim(PrivateDescription)),3) = '£5 ' and RedeemType = 'Charity' 
					then 'D'+ right(ltrim(rtrim(PrivateDescription)),len(ltrim(rtrim(PrivateDescription)))-4)
		When left(Ltrim(PrivateDescription),3) Like '£_0' and RedeemType = 'Charity' 
					then 'D'+right(ltrim(PrivateDescription),len(ltrim(PrivateDescription))-5)
		Else Ltrim(PrivateDescription)
	End, '&pound;','£'),'{em}',''),'{/em}',''),'B&amp;Q','B&Q')
	RedemptionDescription,
	a.PartnerID,
	Coalesce(p.PartnerName,'N/A') as PartnerName,
	Price as CashbackUsed,
	Case
		when TradeUp_Value > 0 then 1
		Else 0
	End as TradeUp_WithValue,
	TradeUp_Value,
	Cancelled,
	GiftAid
FROM #Redemptions a
LEFT JOIN Derived.[partner] p
	ON a.partnerid = p.partnerid

ALTER INDEX IDX_FanID ON Derived.Redemptions REBUILD
		
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Redemptions_V1_12', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_Ecodes #################################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Ecodes', 'Starting'

Declare @Date date = Getdate(),
		@Now datetime = GetDate(),
		@RowCount int

--Find entries for Issued E-Codes-----------------------
IF OBJECT_ID ('tempdb..#eRed_Issues') IS NOT NULL DROP TABLE #eRed_Issues
Select	e.ECodeID,
		StatusChangeDate as IssuedDate
INTO #eRed_Issues
FROM SLC_Report.Redemption.ECodeStatusHistory as e
WHERE e.Status = 1 
	AND e.StatusChangeDate <= @Date
	AND NOT EXISTS (SELECT 1 FROM [Staging].[Redemptions_ECodes] a WHERE e.ecodeid = a.ecodeid)
-- (14 rows affected) / 00:00:05

Create Clustered index cix_eRed_Issues_ECodeID on #eRed_Issues (ECodeID)


--Find some details to fill out records--------------------
IF OBJECT_ID ('tempdb..#RedsData') IS NOT NULL DROP TABLE #RedsData
Select	t.FanID,
		e.TransID as TranID,
		r.IssuedDate as RedeemDate,
		t.ClubCash as CashbackUsed,
		0 as Cancelled,
		ItemID,
		r.ECodeID
Into	#RedsData
From #eRed_Issues as r
inner join SLC_report.Redemption.ECode as e
	on r.ECodeID = e.ID
inner join SLC_report.dbo.trans as t
	on e.TransID = t.id
	
Create Clustered index cix_RedsData_RedeemID on #RedsData (ItemID)


--Finish filling in details to populate records----------------
Insert into [Staging].[Redemptions_ECodes] 
Select  rd.FanID,
		c.CompositeID,
		rd.TranID,
		rd.RedeemDate,
		r.RedeemType,
		r.PrivateDescription as RedemptionDescription,
		ri.PartnerID,
		p.PartnerName,
		rd.CashbackUsed,
		1 as [TradeUp_WithValue],
		ri.TradeUp_Value,
		0 as Cancelled,
		rd.ECodeID
from #RedsData as rd
Left Outer join Derived.RedemptionItem_TradeUpValue as ri
	on rd.ItemID = ri.RedeemID
inner join Derived.RedemptionItem as r
	on rd.ItemID = r.RedeemID
inner join Derived.customer as c
	on rd.FanID = c.FanID
inner join Derived.Partner as p
	on ri.partnerid = p.PartnerID
Left Outer join [Staging].[Redemptions_ECodes] as e
	on rd.TranID = e.TranID
Where e.TranID is null
Order by c.CompositeID

----------------Find those subsequently cancelled in some form-----------------
UPDATE a
SET		Cancelled = 1
FROM [Staging].[Redemptions_ECodes] as a 	
inner join SLC_Report.Redemption.ECodeStatusHistory as e
	on	a.ECodeID = e.ECodeID and
		e.Status >= 1 and
		e.StatusChangeDate > a.RedeemDate and
		a.Cancelled = 0

------------------------Insert final records into table------------------------
Insert into [Derived].[Redemptions]
SELECT	e.FanID,
		e.CompositeID,
		e.TranID,
		e.RedeemDate,
		e.RedeemType,
		e.RedemptionDescription,
		e.PartnerID,
		e.PartnerName,
		e.CashbackUsed,
		e.TradeUp_WithValue,
		e.TradeUp_Value,
		e.Cancelled,
		CAST(0 AS BIT) AS GiftAid
FROM [Staging].[Redemptions_ECodes] as e
WHERE NOT EXISTS (SELECT 1 FROM Derived.Redemptions r WHERE e.tranid = r.tranid)


EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_Ecodes', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Redemptions_ElectronicRedemptionsReport_ProcessAndSend #############
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_ElectronicRedemptionsReport_ProcessAndSend', 'Starting'

/*
RF Commented as might interfere with MyRewards Jobs 

DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @DateName VARCHAR(50) = DATENAME(dw, @Today);	

DECLARE @WorkingDaysIntoMonth date = (SELECT MI.AddWorkingDays(DATEADD(day, -(DATEPART(day, @Today)-1), @Today), 4));

DECLARE @WorkingDaysIntoMonthNotMonTue date = ( -- Adjust trigger so it only falls on a Tues or Wed (server less likely to be busy)
	SELECT CASE DATENAME(dw, @WorkingDaysIntoMonth)
		WHEN 'Monday' THEN DATEADD(day, 2, @WorkingDaysIntoMonth)
		WHEN 'Tuesday' THEN DATEADD(day, 1, @WorkingDaysIntoMonth)
		ELSE @WorkingDaysIntoMonth
	END
);

DECLARE @WorkingDaysIntoMonth2 date = (SELECT MI.AddWorkingDays(DATEADD(day, -(DATEPART(day, @Today)-1), @Today), 6));

DECLARE @FirstMondayOfMonth date = DATEADD(week,DATEDIFF(week, 0, DATEADD(day, 6-DATEPART(day, @Today), @Today)), 0);



IF @DateName != 'Saturday' AND @DateName != 'Sunday'
BEGIN
	EXEC [WHB].[Redemptions_ElectronicRedemptions_And_Stock_Populate]
	EXEC [WHB].[Redemptions_Card_Redemptions_Populate]
	EXEC msdb.dbo.sp_start_job 'BDB5DD45-365C-427C-8A03-A95455BB0F14' -- eVoucher Usage Report
			
	EXEC msdb.dbo.sp_start_job 'DirectDebitFlashReports' -- Trigger the flash transaction and incremental direct debit report ETLs and email subscriptions
END

IF @DateName = 'Tuesday' OR DATEPART(day, @Today) = 2
BEGIN
	EXEC msdb.dbo.sp_start_job 'FC387E8D-53FD-4F0D-BE42-99C9742825C1' -- RedemptionItemActualsByMonth
END

IF DATEPART(day, @Today) = 10
BEGIN
	EXEC msdb.dbo.sp_start_job 'E2CC3A47-5787-4167-A1B8-AF4AE3681ADA' -- DirectDebitOIN
END
	
IF (DATEDIFF(day, '2016-12-08', @Today)-1)%28 = 0 -- Same as above, but uses Modulus operator to check for whole number
BEGIN
	EXECUTE [WHB].[Redemptions_Cycle_Live_OffersCardholders_Populate]
	EXECUTE msdb.dbo.sp_start_job '8B8BA9F4-D619-49A9-B648-F697CD96A766' -- Campaign Cycle Live Offers Report
END

IF @Today = @WorkingDaysIntoMonthNotMonTue
BEGIN
	EXEC Warehouse.Staging.RedemEarnCommReport_Load
	EXEC Warehouse.Staging.RedemEarnCommReport_NewsletterCycles_Load
	EXEC msdb.dbo.sp_start_job '948B5468-1EF2-483F-8D17-B7D1B17510EF' -- RedemEarnCommReport (Engagement Report)
	EXEC Staging.RBSPerformanceKPIReport_Load
	EXEC Staging.RBSPerformanceKPIReport_Load_CreditCardResults
	EXEC msdb.dbo.sp_start_job 'F9B4ED54-9F3C-49DF-93E7-9DB8830851BE' -- RBSPerformanceKPIReport
END

IF @Today = @WorkingDaysIntoMonth2
BEGIN
	EXEC msdb.dbo.sp_start_job '59E3EA7D-DFD3-40F8-8B48-5E02FEF5099A' -- TransactionInvoiceSummary_MTR
END


IF @Today = @FirstMondayOfMonth
BEGIN
	EXEC msdb.dbo.sp_start_job 'F35B3297-D965-4D1F-87F4-FABF6BB50ACA' -- MyRewardsAccountSummary
END

RF Commented as might interfere with MyRewards Jobs

*/


EXEC Monitor.ProcessLog_Insert 'WHB', 'Redemptions_ElectronicRedemptionsReport_ProcessAndSend', 'Finished'

/*
The module 'Redemptions_Daily' depends on the missing object 'WHB.Redemptions_ElectronicRedemptions_And_Stock_Populate'. The module will still be created; however, it cannot run successfully until the object exists.
The module 'Redemptions_Daily' depends on the missing object 'WHB.Redemptions_Card_Redemptions_Populate'. The module will still be created; however, it cannot run successfully until the object exists.
The module 'Redemptions_Daily' depends on the missing object 'WHB.Redemptions_Cycle_Live_OffersCardholders_Populate'. The module will still be created; however, it cannot run successfully until the object exists.
The module 'Redemptions_Daily' depends on the missing object 'Staging.RBSPerformanceKPIReport_Load'. The module will still be created; however, it cannot run successfully until the object exists.
The module 'Redemptions_Daily' depends on the missing object 'Staging.RBSPerformanceKPIReport_Load_CreditCardResults'. The module will still be created; however, it cannot run successfully until the object exists.
*/

RETURN 0