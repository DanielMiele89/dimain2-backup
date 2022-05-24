CREATE Procedure Prototype.CampaignEmails_ExtraData (@TableName nvarchar(200),@LowerEarnLimit SmallInt,@UpperEarnLimit smallint)

AS
--Declare @TableName nvarchar(200),@LowerEarnLimit SmallInt,@UpperEarnLimit smallint
--Set @TableName = 'Warehouse.InsightArchive.DirectDebit_EmailCampaign_20160317'
--Set @LowerEarnLimit = 15
--Set @UpperEarnLimit = 150
	--------------------------------------------------------------------------------------
	--------------------------Create list of Customers with RowNo-------------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#Customers') is not null 
										drop table #Customers

	Select	*,
			ROW_NUMBER() OVER(ORDER BY IssuerCustomerID ASC) AS RowNo
	into #Customers
	From (
	Select	Distinct
			F.ID as FanID,
			f.SourceUID,
			ic.ID as IssuerCustomerID,
			f.ClubID,
			f.CompositeID
	from SLC_Report.dbo.Fan as f
	inner join Staging.SLC_Report_DailyLoad_Phase2DataFields as a
		on	f.id = a.fanid and
			LoyaltyAccount = 0
	inner join SLC_Report.[dbo].[IssuerCustomer] as ic
		on	f.SourceUID = ic.SourceUID and
			Case
				When f.CLUBID = 132 then 2
				Else 1
			End = ic.issuerID
	inner join SLC_Report.[dbo].IssuerCustomerAttribute as ica
		on	ic.ID = ica.IssuerCustomerID and
			ica.EndDate is null
	) as a

	Create Clustered index IX_Customers_IssuerIDRowNo 
										on #Customers (IssuerCustomerID,RowNo)
		
--	(1875469 row(s) affected)

													
	--------------------------------------------------------------------------------------
	--------------------------------- Create Temporary Tables ----------------------------
	--------------------------------------------------------------------------------------

	if object_id('tempdb..#Accounts') is not null
										drop table #Accounts
	---------------************ Create table to hold a list of accounts****************----------------
	Create Table #Accounts (	id int identity(1,1) not null,
								FanID int not null, 
								SourceUID varchar(20) not null, 
								IssuerCustomerID int not null, 
								[Type] Varchar(3) not null,
								BankAccountID int not null,
								AccountNumber varchar(3) not null,
								ClubID INT
								
								)

	--------------------------------------------------------------------------------------
	------------------------------- Loop Around pulling base data ------------------------
	--------------------------------------------------------------------------------------
	Declare @ChunkSize int,@RowNo int, @RowNoMax int

	Set @RowNo = 1
	Set @RowNoMax = (Select MAX(RowNo) from #Customers as c) 
	Set @ChunkSize = 50000
						
	------------------------

	While @RowNo <= @RowNoMax
	Begin
		--Pull list of accounts
		
		Insert into #Accounts
		Select	c.FanID,
				c.SourceUID,
				c.IssuerCustomerID,
				bah.[Type],
				bah.BankAccountID,
				Right(ba.MaskedAccountNumber,3) as AccountNumber,
				ClubID
		from #Customers as c
		inner join SLC_Report.[dbo].[IssuerBankAccount] as iba
			on	c.IssuerCustomerID = iba.IssuerCustomerID and
				COALESCE(IBA.CustomerStatus, 1) = 1
		inner join SLC_Report.dbo.BankAccount as BA 
			ON	IBA.BankAccountID = BA.ID AND COALESCE(BA.[Status], 1) = 1
		INNER JOIN SLC_Report.dbo.BankAccountTypeHistory AS BAH 
			ON	BAH.BankAccountID = IBA.BankAccountID AND BAH.EndDate IS NULL	
		Where	RowNo between @RowNo and @RowNo + (@ChunkSize-1)
			
		Set @RowNo = @RowNo+@ChunkSize
	
	End	

---------------------------------------------------------------------------------------
-------------------------------Find Joint Accounts ------------------------------------
---------------------------------------------------------------------------------------
if object_id('tempdb..#JointAccounts') is not null
										drop table #JointAccounts
	
Select BankAccountID,[Type],ClubID,Count(Distinct FanID) as AccountMembers
into #JointAccounts
from #Accounts as a
Group by BankAccountID,[Type],ClubID Having Count(Distinct FanID) > 1
--(118223 row(s) affected)

if object_id('tempdb..#JointAccountNames') is not null
										drop table #JointAccountNames
Select a.*,AccountName,Ranking
Into #JointAccountNames
from #JointAccounts as a
INNER JOIN staging.DirectDebit_EligibleAccounts AS B
	ON	A.[Type] = B.[AccountType] and
		a.ClubID = b.ClubID


if object_id('tempdb..#AccountRows') is not null
										drop table #AccountRows
Select *
into #AccountRows
From (
Select b.*,a.FanID,ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Ranking ASC) AS RowNo
From #Accounts as a
inner join #JointAccountNames as b
	on a.BankAccountID = b.BankAccountID
) as a

if object_id('tempdb..#JointPackagedAccounts') is not null
										drop table #JointPackagedAccounts
CREATE TABLE #JointPackagedAccounts(
	[BankAccountID] [int] NOT NULL,
	[Type] [varchar](3) NOT NULL,
	[ClubID] [int] NULL,
	[AccountMembers] [int] NULL,
	[AccountName] [varchar](75) NOT NULL,
	[Ranking] [smallint] NULL,
	[FanID] [int] NOT NULL,
	[RowNo] [bigint] NULL,
	[RoundedDown_Value] [money] NULL,
	[RowNum] [bigint] NULL
) ON [PRIMARY]

Declare @Qry nvarchar(max)

Set @Qry = '
Insert Into #JointPackagedAccounts
Select *
from (
Select a.*,
b.RoundedDown_Value,ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY b.RoundedDown_Value DESC) AS RowNum
from #AccountRows as a
Left Outer join '+@TableName+' as b
	on a.BankAccountID = b.BankAccountID
Where (AccountName like ''Select%'' or AccountName like ''Black%'') and AccountName <> ''Select Account''
) as a
Where RowNum = 1
'

Exec sp_ExecuteSQL @Qry


if object_id('tempdb..#JointAccounts_NP') is not null
										drop table #JointAccounts_NP
Select a.FanID
Into #JointAccounts_NP
from #AccountRows as a
left Outer join #JointPackagedAccounts as b
	on a.FanID = b.fanid
Where b.fanid is null

---------------------------------------------------------------------------------------
-------------------------------Find Packaged Customers ------------------------------------
---------------------------------------------------------------------------------------
if object_id('tempdb..#PackagedAccounts') is not null
										drop table #PackagedAccounts
Select a.* ,b.AccountName,b.Ranking
Into #PackagedAccounts
from #Accounts as a
left outer join #AccountRows as ar
	on a.fanid = ar.fanid
inner join staging.DirectDebit_EligibleAccounts AS B
	ON	A.[Type] = B.[AccountType] and
		a.ClubID = b.ClubID
Where ar.fanid is null and b.Ranking between 1 and 4

if object_id('tempdb..#PackagedAccountsRanking') is not null
										drop table #PackagedAccountsRanking

CREATE TABLE #PackagedAccountsRanking(
	[FanID] [int] NOT NULL,
	[AccountName] [varchar](75) NOT NULL,
	[RowNum] [bigint] NULL,
	[RoundedDown_Value] [money] NULL
) ON [PRIMARY]

Set @Qry = '
Insert into #PackagedAccountsRanking
Select * 
from (
Select	a.FanID, a.AccountName,ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY b.RoundedDown_Value DESC) AS RowNum, b.RoundedDown_Value
		--Count(*) 
from #PackagedAccounts as a
Left Outer join '+@TableName+' as b
	on a.BankAccountID = b.BankAccountID	
) as a
Where RowNum = 1
'
Exec sp_ExecuteSQL @Qry

Set @Qry = '

if object_id(''Warehouse.InsightArchive.CampaignEmail'+convert(varchar,Cast(GETDATE()as DATE),112)+'_ConversionAccountNames'') is not null
										drop table Warehouse.InsightArchive.CampaignEmail'+convert(varchar,Cast(GETDATE()as DATE),112)+'_ConversionAccountNames
Select	c.FanID,
		Case
			When a.fanid is not null then a.AccountName
			When d.fanid is not null then ''''
			When b.fanid is not null then b.AccountName
			Else ''''
		End as ConversionAccountNames
Into	Warehouse.InsightArchive.CampaignEmail'+convert(varchar,Cast(GETDATE()as DATE),112)+'_ConversionAccountNames
from #Customers as c
left Outer join #JointPackagedAccounts as a
	on c.fanid = a.fanid
Left Outer join #PackagedAccountsRanking as b
	on c.fanid = b.FanID
Left Outer join #JointAccounts_NP as d
	on c.fanid = d.fanid
'

Exec SP_ExecuteSQL @Qry

Set @Qry = '
Select a.ConversionAccountNames,Count(*)
from Warehouse.InsightArchive.CampaignEmail'+convert(varchar,Cast(GETDATE()as DATE),112)+'_ConversionAccountNames as a
Group by ConversionAccountNames'

Exec SP_ExecuteSQL @Qry
---------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Find Earnings-------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PotentialEarnings') is not null
										drop table #PotentialEarnings
CREATE TABLE #PotentialEarnings(
	[FanID] [int] NOT NULL,
	[CouldHaveEarned] [money] NULL
) ON [PRIMARY]

Set @Qry = ''
Set @Qry = @Qry+'
Select a.FanID,Sum(b.RoundedDown_Value) as RoundedDown,Count(*) as accounts
Into #AmountEarned
From #Accounts as a
inner join '+@TableName+' as b
	on a.BankAccountID = b.BankAccountID
Group by a.FanID

Select b.FanID,Sum(RoundedDown_Value) as RoundedDown
Into #OtherEarns
From '+@TableName+' as b
left Outer join #Accounts as a
	on a.BankAccountID = b.BankAccountID
Where a.BankAccountID is null
Group by b.FanID

Insert Into #PotentialEarnings
Select c.FanID,Sum(Coalesce(a.RoundedDown,0)+Coalesce(b.RoundedDown,0)) as CouldHaveEarned
from #Customers as c
left Outer join #AmountEarned as a
	on c.fanid = a.FanID
left outer join #OtherEarns as b
	on c.fanid = b.FanID
Group by c.FanID
'

Exec sp_executeSQl @Qry
--Select * from #PotentialEarnings where CouldHaveEarned Between 10 and 50

---------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------Find ZMs and ZH----------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
Set @Qry = '
if object_id(''Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)+''') is not null
										drop table Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)+'
Select	c.FanID as [Customer ID],
		c.Email,
		WG = 1
Into Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)+'
from Warehouse.relational.Customer as c
inner join SLC_Report.[dbo].[IssuerCustomer] as ic
	on	c.SourceUID = ic.SourceUID and
		Case
			When c.CLUBID = 132 then 2
			Else 1
		End = ic.issuerID
inner join SLC_Report.[dbo].[IssuerBankAccount] as iba
	on	ic.ID = iba.IssuerCustomerID and
		COALESCE(IBA.CustomerStatus, 1) = 1
inner join SLC_Report.dbo.BankAccount as BA 
	ON	IBA.BankAccountID = BA.ID AND COALESCE(BA.[Status], 1) = 1
INNER JOIN SLC_Report.dbo.BankAccountTypeHistory AS BAH 
	ON	BAH.BankAccountID = IBA.BankAccountID AND BAH.EndDate IS NULL	
Where	bah.Type in (''ZH'',''ZM'')

SELECT Count(Distinct [Customer ID]) FROM Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)

Exec SP_ExecuteSQL @Qry 

--SELECT * FROM Warehouse.InsightArchive.CampaignEmail_ZM_ZH_20160304

---------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------Delete ZM and ZH from Account Name List-----------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
Set @Qry = '
if object_id(''Warehouse.InsightArchive.CampaignEmail_ConversionAccountNames_CouldHaveEarned'+convert(varchar,Cast(GETDATE()as DATE),112)+''') is not null
										drop table Warehouse.InsightArchive.CampaignEmail_ConversionAccountNames_CouldHaveEarned'+convert(varchar,Cast(GETDATE()as DATE),112)+'
Select	c.FanID,
		Coalesce(Replace(replace(b.ConversionAccountNames,''Select '',''''),'' Account'',''''),'''') as ConversionAccountNames,
		Coalesce(pe.CouldHaveEarned,'''') as RoundedDown_Value
Into	Warehouse.InsightArchive.CampaignEmail_ConversionAccountNames_CouldHaveEarned'+convert(varchar,Cast(GETDATE()as DATE),112)+'
From Warehouse.relational.Customer as c
inner join Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields as a
	on c.fanid = a.fanid
Left Outer join Warehouse.InsightArchive.CampaignEmail'+convert(varchar,Cast(GETDATE()as DATE),112)+'_ConversionAccountNames as b
	on c.fanid = b.FanID
Left Outer join #PotentialEarnings as pe
	on	a.FanID = pe.FanID and
		pe.CouldHaveEarned between '+Cast(@LowerEarnLimit as varchar(7))+' and '+Cast(@UpperEarnLimit as varchar(7))+'
Where Len(Email) > 8 and email like ''%@%.%'' and
	  LoyaltyAccount <> 1 and
	  (len(b.ConversionAccountNames) > 0 or pe.CouldHaveEarned is not null) and
	  c.FanID not in (Select [Customer ID] from Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)+' as b)

Select ConversionAccountNames,RoundedDown_Value,Count(*) from Warehouse.InsightArchive.CampaignEmail_ConversionAccountNames_CouldHaveEarned'+convert(varchar,Cast(GETDATE()as DATE),112)+'
Group By ConversionAccountNames,RoundedDown_Value
'
--Select @Qry

Exec sp_ExecuteSQL @Qry

-----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------Pull Data ------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Set @qry = '
Select a.*,Email from Warehouse.InsightArchive.CampaignEmail_ConversionAccountNames_CouldHaveEarned'+convert(varchar,Cast(GETDATE()as DATE),112)+' as a
inner join warehouse.relational.Customer as e
	on a.[Customer ID] = e.fanid

Select * from Warehouse.InsightArchive.CampaignEmail_ZM_ZH_'+convert(varchar,Cast(GETDATE()as DATE),112)+'
'

Exec sp_executeSQL @Qry