Create Procedure [Staging].[ShareOfWallet_SegmentAssignment_02_V1_4]
				 @PartnerName varchar(200),
				 @PartnerID int,
				 @PartnerString varchar(200)
As
Begin			
declare @Qry nvarchar(max),@TableName nvarchar(300),		@Mth varchar(3)
set @Mth = Cast((Select Mth from Staging.ShareOfWallet_PartnerSettings where PartnerID = @PartnerID)as varchar(3))


-----------------------------------------------------------------------------------------
-----------------Calculate Partner Share Percentage--------------------------------------
-----------------------------------------------------------------------------------------
Set @TableName = 'Staging.Headroom_ActSpend'+@Mth+'Mths'
--Select @TableName
if object_id('tempdb..##ActSpend_Pct') is not null drop table ##ActSpend_Pct
Set @Qry ='
select	*,
		Case
			When PartnerSpend > CategorySpend then 1
			Else PartnerSpend/CategorySpend 
		End as PartnerShare_Pct
Into	##ActSpend_Pct
from ' + @TableName + '
Where PartnerSpend > 0 and CategorySpend > 0'--only for those with spend with partner and overall
exec sp_ExecuteSQL @Qry
-----------------------------------------------------------------------------------------
-----------------------Calculate Loyalty and Spend Scores--------------------------------
-----------------------------------------------------------------------------------------

Declare @CategorySpend real,@Loyalty real
Set @CategorySpend = (Select CategorySpend 
					  from [Staging].[ShareOfWallet_PartnerSettings] as b where PartnerID = @PartnerID)
Set @Loyalty = (Select (Cast(Loyalty as real)/100) 
				from [Staging].[ShareOfWallet_PartnerSettings] as b where PartnerID = @PartnerID)
if object_id('tempdb..##ActSpendAndLoyaltyGroups') is not null drop table ##ActSpendAndLoyaltyGroups
Set @Qry = 
'select b.*,isnull(a.PartnerShare_Pct,0) as PartnerShare_Pct,
		Case
			When b.CategorySpend <= 0 then 0
			When b.CategorySpend < '+cast(@CategorySpend as varchar)+' then 1
			Else 2
		End as Spend,
		Case
			When isnull(a.PartnerShare_Pct,0) <= 0 then 0
			When a.PartnerShare_Pct < '+Cast(@Loyalty as varchar)+' then 1
			Else 2
		End as Loyalty
Into ##ActSpendAndLoyaltyGroups
from '+@TableName+' as b
left outer join ##ActSpend_Pct as a
	on b.CINID = a.CINID
'
--Select @Qry
eXEC sp_ExecuteSQL @Qry
------------------------------------------------------------------
-------------------------------
---------
Select	a.*,
		h.CBCustomer,
		Case
			When Spend = 0 then 10
			When Spend = 1 and Loyalty = 0 then 11
			When Spend = 2 and Loyalty = 0 then 12
			When Spend = 1 and Loyalty = 1 then 13
			When Spend = 2 and Loyalty = 1 then 14
			When Spend = 1 and Loyalty = 2 then 15
			When Spend = 2 and Loyalty = 2 then 16
		End as Segment
into #HeadroomTM
from ##ActSpendAndLoyaltyGroups as a
inner join Staging.Headroom_ActInitialBase as h
	on a.CinID = h.CinID



-----------------------------------------------------------------------------------------------
---------------------Remove Activated Customers if Restricted Customer Base--------------------
-----------------------------------------------------------------------------------------------

--Check for Restricted Audience Partner
--if @PartnerString in (select PartnerString from [Relational].[HeadroomTargetingModel_RestrictedAudience])
--Begin
--Declare @IronOfferIDs varchar(100)
----Pull in IronOfferIDs to find out restricted audience members
--Set @IronOfferIDs = 
--		(select IronOfferString from [Relational].[HeadroomTargetingModel_RestrictedAudience] where PartnerString = @PartnerString)
----Delete all headroom customers that are not in named offers
--Set @Qry = 'Delete from #HeadroomTM
--			from #HeadroomTM as h
--			Left join relational.cinlist as cl
--				on h.cinid = cl.cinid
--			Left join relational.customer as c
--				on cl.cin = c.sourceuid
--			left outer join relational.ironoffermember as iom
--				on c.compositeid = iom.compositeid and
--				iom.IronOfferID in ('+@IronOfferIDs+')
--			inner join Staging.Headroom_ActInitialBase as a
--				on	h.cinid = a.CinID and
--					CBCustomer = Cast(1 as Bit)
--			Where iom.Compositeid is null'
--Exec sp_ExecuteSQL @Qry
--End

----Select * from #HeadroomTM
-------------------------------------------------------------------------------------------------
--------------------------------------Insert Data into Table-------------------------------------
-------------------------------------------------------------------------------------------------
Set @TableName = 'Staging.ShareOfWallet_'+ @PartnerName+convert(varchar,Cast(GETDATE()as DATE),112)
Set @Qry =
'if object_id('+char(39)+@TableName+CHAR(39)+') is not null drop table ' + @TableName + '
 Select		htm.*--,
			--Cast(a.CBCustomer as bit) as CBCustomer
 Into ' + @TableName + ' 
 From #HeadroomTM as htm
 inner join Staging.Headroom_ActInitialBase as a
	on htm.CinID = a.CinID
 '
-- --Select @Qry
 Exec sp_ExecuteSQL @Qry
 
-------------------------------------------------------------------------------------------------
--------------------------------Get data ready to add the Customer_Headroom Table----------------
-------------------------------------------------------------------------------------------------

--Declare @PartnerString varchar(100),@TableName varchar(200),@Qry nvarchar(max)
--Set @PartnerString = '2365'
--Set @TableName = 'Staging.ShareOfWallet_Cineworld20140303'
if object_id('tempdb..#PartnerIDs') is not null drop table #PartnerIDs
Select LEFT(@PartnerString,4) as PartnerID into #PartnerIDs
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,9),4) as PartnerID where len(@PartnerString) > 4
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,14),4) as PartnerID where len(@PartnerString) > 9
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,19),4) as PartnerID where len(@PartnerString) > 14
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,24),4) as PartnerID where len(@PartnerString) > 19
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,29),4) as PartnerID where len(@PartnerString) > 24

if object_id('tempdb..##HTMMembers') is not null drop table ##HTMMembers
Set @Qry = '
Select	c.ID as FanID,
		a.Segment as HTMID,
		P.PartnerID,
		Cast(getdate() as date) as StartDate, 
		cast(null as Date) as EndDate,
		a.CBCustomer
into ##HTMMembers
from ' + @TableName + ' as a with (Nolock)
inner join Relational.CinList as cl with (nolock)
	on a.CinID = cl.CinID
inner join SLC_Report.dbo.Fan as c with (nolock)
	on cl.cin = c.SourceUID,
#PartnerIDs as P
'

--select @Qry
Exec sp_executeSQL @Qry
--select * from ##HTMMembers
--------------------------------------------------------------------------------------------------------------
-------------------------------Remove those people already in HTM Groups--------------------------------------
--------------------------------------------------------------------------------------------------------------

--CB+ Customers
Delete from ##HTMMembers
from ##HTMMembers as a
inner join [Relational].[ShareOfWallet_Members] as b
	on a.FanID = b.FanID and a.HTMID = b.HTMID and a.PartnerID = b.PartnerID and b.EndDate is null
Where CBCustomer = 1

--Unstratified Control
Delete from ##HTMMembers
from ##HTMMembers as a
inner join [Relational].[ShareOfWallet_Members_UC] as b
	on a.FanID = b.FanID and a.HTMID = b.HTMID and a.PartnerID = b.PartnerID and b.EndDate is null
Where CBCustomer = 0



--------------------------------------------------------------------------------------------------------------
------------------------------Put EndDates for those already in HTM Groups------------------------------------
--------------------------------------------------------------------------------------------------------------
--CB+ Customers
Update  [Relational].[ShareOfWallet_Members]
Set		EndDate = Dateadd(day,-1,CAST(getdate() as DATE))
Where	FanID in (Select Distinct FanID from ##HtmMembers Where CBCustomer = 1) and
		PartnerID in (Select Distinct PartnerID from #PartnerIDs) and
		EndDate is null
		
--Unstratified Control - including closing off those now activated
Update  [Relational].[ShareOfWallet_Members_UC]
Set		EndDate = Dateadd(day,-1,CAST(getdate() as DATE))
Where	FanID in (Select Distinct FanID from ##HtmMembers) and
		PartnerID in (Select Distinct PartnerID from #PartnerIDs) and
		EndDate is null
		
--------------------------------------------------------------------------------------------------------------
------------------------------------------Log Entry for HTM Run ----------------------------------------------
--------------------------------------------------------------------------------------------------------------		
Insert into [Relational].[ShareOfWallet_Members]
Select FanID,HTMID,PartnerID,StartDate,EndDate
from ##HTMMembers
Where CBCustomer = 1

Insert into [Relational].[ShareOfWallet_Members_UC]
Select FanID,HTMID,PartnerID,StartDate,EndDate
from ##HTMMembers
Where CBCustomer = 0

Insert into Relational.ShareofWallet_RunLog
Select ps.PartnerString, ps.PartnerName_Formated,a.Mth,Loyalty,CategorySpend,Getdate() as RunTime 
from Relational.PartnerStrings as ps, Staging.ShareOfWallet_PartnerSettings as a
Where	ps.PartnerString = @PartnerString and 
		a.PartnerID = @PartnerID

--------------------------------------------------------------------------------------------------------------
--------------------------------------- Log Start and End Dates ----------------------------------------------
--------------------------------------------------------------------------------------------------------------	
--Create Table Relational.ShareOfWallet_Dates (
--			ID int identity (1,1),
--			ShareofWalletID int,
--			StartDate Date,
--			EndDate Date)

Declare @EndDate Date, @StartDate Date
Set @EndDate = (Select EndDate From Staging.ShareofWallet_EndDate)
Set @StartDate = DateAdd(Day,1,DateAdd(month,-Cast(@Mth as int),@EndDate))

Insert into Relational.ShareOfWallet_Dates
Select	(Select Max(ID) as ShareOfWalletID from Relational.ShareofWallet_RunLog) as ShareOfWalletID,
		@StartDate,
		@EndDate


--------------------------------------------------------------------------------------------------------------
----------------------------------------Log Segment Counts ---------------------------------------------------
--------------------------------------------------------------------------------------------------------------	
Insert into Relational.ShareOfWallet_SegmentCounts
Select	(Select Max(ID) as ShareOfWalletID from Relational.ShareofWallet_RunLog) as ShareOfWalletID,
		Segment as htmID,
		Count(*) as Members,
		Cast(Count(*) as float)/a.Total_Members as Pct_Customers,
		Cast(Sum(CategorySpend)/Count(*) as money) as AverageSpend,
		Sum(PartnerShare_Pct)/Count(*) as AverageLoyalty
from #HeadroomTM as b,
(Select Count(*) as Total_Members from #HeadroomTM where CBCustomer = 1) as a
Where b.CBCustomer = 1
Group by Segment,Total_Members

--Create Table Relational.ShareOfWallet_SegmentCounts (
--			ID int identity (1,1),
--			ShareofWalletID int,
--			HTMID TinyInt,
--			Members int,
--			PCT_Customer Real,
--			AverageSpend money,
--			AverageLoyalty Real)

End