Create Procedure [Staging].[ShareofWallet_EligibleCustomersV1_5]
As
Begin

--Create Table Staging.ShareofWallet_EndDate (EndDate date)
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_temp
Select	StoredProcedureName = 'ShareofWallet_EligibleCustomersV1_5',
		TableSchemaName = '',
		TableName = 'Eligibility Calculation',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------*/

Truncate Table Staging.ShareofWallet_EndDate
Insert into Staging.ShareofWallet_EndDate
Select Max(TransactionDate) as EndDate from Relational.PartnerTrans with (nolock)
------------------------------------------------------------------------------------------------------------------
------------------------------------Create a Customer Base--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
--Use Warehouse

if object_id('tempdb..#CustBase') is not null drop table #CustBase
Create table #CustBase (	RowNo int,
							CINID int ,
							CBCustomer Bit,
							PRIMARY KEY (CINID))

Insert into #CustBase
Select	ROW_NUMBER() OVER(ORDER BY CINId) as RowNo,
		CinID,
		Cast(Max(cast(CBCustomer as int)) as bit)
from 
(
	select	CinID,
			cast(1 as bit) as CBCustomer
	from Relational.Customer as c
	inner join Relational.CINList as cl
		on c.SourceUID = cl.CIN
	where	c.Activated = 1 and 
			c.SourceUID not in (select SourceUID from Staging.Customer_DuplicateSourceUID)
	Union All

	Select	cl.CINID,
			Cast(0 as bit) as CBCustomer
	from
	(
		select u.FanID
		from [Relational].[Control_Unstratified] as u
		left outer join Relational.Customer as c
			on u.FanID = c.FanID
		Where c.FanID is null and u.EndDate is null
	) as a
	inner join slc_report.dbo.fan as f
		on a.FanID = f.id
	inner join Relational.CINList as cl
		on f.SourceUID = cl.CIN
) as a
Group by CinID

if object_id('Staging.Headroom_ActInitialBase') is not null drop table Staging.Headroom_ActInitialBase
Create table Staging.Headroom_ActInitialBase (
					RowNo [int] IDENTITY(1,1) NOT NULL,
					CinID int not null,
					CBCustomer bit not null,
					Primary Key (RowNo)
					)
Create NonClustered index idx_Headroom_ActInitialBase_CinID on Staging.Headroom_ActInitialBase (CINID)

Insert into Staging.Headroom_ActInitialBase
Select	CB.CINID,
		CB.CBCustomer		
from #CustBase as cb
Order by RowNo

--Select * from Staging.Headroom_ActInitialBase
------------------------------------------------------------------------------------------------------------------
---------------------------------Pull through 4 month transaction counts per month--------------------------------
------------------------------------------------------------------------------------------------------------------
Declare @StartNo int,@ChunkSize int,@CBSize int, @Mth int,@EndDate date,@StartDate date
Set @StartNo = 1
Set @ChunkSize = 100000
Set @CBSize = (select COUNT(*) from #CustBase)

if object_id('Staging.Activated4MthDistinct') is not null drop table Staging.Activated4MthDistinct
Create table Staging.Activated4MthDistinct(CINID int,DistinctMonths int)

--*********************Looping section to pull transcounts for each of the last four months*****************--

While @StartNo < @CBSize
Begin

if object_id('tempdb..#CB') is not null drop table #CB
Select top (@ChunkSize) CINID
Into #CB
from #CustBase
Where	RowNo between @StartNo and 
		(@StartNo+@ChunkSize)-1
Order by RowNo
create clustered index ixc_CB_CinID on #CB(CinID)
-------------------------------------------------------------------------------------------------------------
--------------------Find out the number of distinct months in the last 4 have a transaction------------------
-------------------------------------------------------------------------------------------------------------
--Declare @Mth tinyint, @StartDate Date, @EndDate Date
Set @Mth = 4
Set @EndDate = (Select EndDate From Staging.ShareofWallet_EndDate)
Set @StartDate = DateAdd(Day,1,DateAdd(month,-4,@EndDate))

Insert Into Staging.Activated4MthDistinct
--Select * from 
Select	a.CINID,
		Count(Distinct a.TranMonth) as DistinctMonths
--into #t1
from
(
select	Distinct
		cb.CINID,
		ct.ConsumerCombinationID,
		dateadd(day,-(datepart(day,ct.TranDate)-1),ct.TranDate) as TranMonth

from Relational.ConsumerTransaction as ct with (nolock) 
inner join #CB as cb
	on ct.CINID = cb.CINID
Where TranDate between @StartDate and @EndDate
Group by cb.CINID,
		ct.ConsumerCombinationID,
		dateadd(day,-(datepart(day,ct.TranDate)-1),ct.TranDate)

) as a
inner join Relational.ConsumerCombination as cc --- All MIDs in this table belong to Retailers
	on a.ConsumerCombinationID = cc.ConsumerCombinationID
inner join Relational.Brand as b
	on cc.BrandID = b.BrandID
inner join Relational.mcclist as mcc
	on cc.mccid = mcc.mccid
Where (	(	b.SectorID not in (1,2,35,38) and -- These relate to 'Financial Transfer','Business To Business','Vehicle Parking' and 'Gambling'
			b.BrandID <> 944
		)
		or
		(	mcc.SectorID not in (1,2,35,38) and 
			b.BrandID = 944	and -- Unmapped/Unknown Brands
			replace(cc.LocationCountry,' ','') = 'GB' --- for unknown brands we only want transactions in the UK.
		)
	)
Group by CINID


Set @StartNo = @StartNo+@ChunkSize
End

--*********************End of looping section to pull transcounts for each of the last four months*****************--




-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
Declare @Cases nvarchar(max),@Fields nvarchar(150)

--Create table to hold the different month amounts required
if object_id('tempdb..#Months') is not null drop table #Months
Select Distinct Mth
into #Months
from Staging.ShareOfWallet_PartnerSettings
Where Mth < 37
---Pull through the month amounts that are less than the meximum and greater than 4 months (as already have data for
---and create case statements for each different amount
if object_id('tempdb..#Cases') is not null drop table #Cases
Select 'Case When datediff(Month,TranDate,cast('''+CONVERT(varchar,@EndDate,107)+''' as date)) < '+ cast(Mth as varchar) + ' Then 1 Else 0 End as ['+Cast(Mth as Varchar)+'],' as [Case]
Into #Cases
from #Months as M
Where Mth < (Select MAX(Mth) from #Months)
--Join Case statements together
-------------------------------------------------------------------------------------------------------------
---------------------------------Generate Case Statments as one string --------------------------------------
-------------------------------------------------------------------------------------------------------------
Set @Cases = 
 Replace(	(select  [Case] as 'text()' 				
	from #Cases
	for xml path('')),'&lt;','<')
  
-------------------------------------------------------------------------------------------------------------
--------------------------------Create list of Month sizes as one solid string-------------------------------
-------------------------------------------------------------------------------------------------------------

Set @Fields =
(select 'Sum(['+ cast(Mth as varchar)+']) as ['+ cast(Mth as varchar)+'],'  from #Months
where Mth < (Select MAX(Mth) from #Months)
For xml path(''))
--Select @Fields

Declare @Columns nvarchar(300)
Set @Columns =
(select '['+ cast(Mth as varchar)+'] int,'  from #Months
--where Mth < (Select MAX(Mth) from #Months)
For xml path(''))
--Select @Fields

Set @Columns = Left(@Columns,Len(@Columns)-1)

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
--Declare @StartNo int,@ChunkSize int,@CBSize int, @Mth int,--@EndDate date,
	--	@StartDate date
Declare @TableName nvarchar(100),@Qry nvarchar(max), @Dates nvarchar(60)
		
Set @StartNo = 1
Set @ChunkSize = 100000
Set @CBSize = (select COUNT(*) from #CustBase)

Set @Mth = (Select Max(Mth) from #Months)
Set @StartDate = DateAdd(Day,1,DateAdd(month,-@Mth,@EndDate))
Set @Dates = Char(39)+ convert(varchar,@StartDate, 107) + CHAR(39) + ' and ' + Char(39)+convert(varchar,@EndDate, 107)+CHAR(39)
set @TableName = 'staging.Headroom_ActMths'

--Truncate Table Staging.Headroom_ActMths
if object_id('staging.Headroom_ActMths') is not null drop table staging.Headroom_ActMths

Set @Qry = '
Create table Staging.Headroom_ActMths (
					CinID int,
				'+ @Columns+')'
Exec sp_ExecuteSQL @Qry

While @StartNo < @CBSize
Begin

if object_id('tempdb..#CB2') is not null drop table #CB2
Select top (@ChunkSize) CINID
Into #CB2
from #CustBase
Where	RowNo between @StartNo and 
		(@StartNo+@ChunkSize)-1
Order by RowNo
create clustered index ixc_CB2_CinID on #CB2(CinID)
-----(606067 row(s) affected)

-------------------------------------------------------------------------------------------------------------
----------------------------------------Insert into staging.Headroom_ActMths---------------------------------
-------------------------------------------------------------------------------------------------------------

Set @Qry = '
Insert Into ' + @TableName + '
Select	a.CINID,
		'+@Fields+'
		COUNT(*) as ['+cast((@Mth) as varchar)+']
from
(
select	cb.CINID,
		' + @Cases + '
		ct.ConsumerCombinationID

from relational.consumerTransaction ct with (nolock)
inner join #CB2 as cb
	on ct.CINID = cb.CINID
Where TranDate between ' + @Dates + '
) as a
inner join Relational.ConsumerCombination as cc with (nolock)--- All MIDs in this table belong to Retailers
	on a.ConsumerCombinationID = cc.ConsumerCombinationID
inner join Relational.Brand as b
	on cc.BrandID = b.BrandID
inner join Relational.mcclist as mcc
	on cc.mccid = mcc.mccid
Where (	(	b.SectorID not in (1,2,35,38) and 
			b.BrandID <> 944
		)
		or
		(	mcc.SectorID not in (1,2,35,38) and 
			b.BrandID = 944	and 
			replace(cc.LocationCountry,'' '','''') = ''GB''
		)
	)
Group by CINID'

--Select @Qry
exec sp_ExecuteSQL @Qry
Set @StartNo = @StartNo+@ChunkSize
End
--23mins

------------------------------------------------------------------------------------------------------
--------------------------------Take data and populate to Eligible Tables-----------------------------
------------------------------------------------------------------------------------------------------

if object_id('tempdb..#MonthNo') is not null drop table #MonthNo
Select	*, 
		ROW_NUMBER() OVER(ORDER BY Mth ASC) RowNo
Into #MonthNo
from #Months

Declare @Row int,@MonthText varchar(2)--,@Qry nvarchar(max)
Set @Row = (select MIN(RowNo) from #MonthNo)
While @Row <= (select Max(RowNo) from #MonthNo)
Begin 
Set @MonthText = rtrim(Cast((Select Mth from #MonthNo Where RowNo = @Row) as CHAR))
Set @Qry =
'
if object_id(''Staging.HeadroomEligible'+@MonthText+'Mths'') is not null'+
							+' drop table Staging.HeadroomEligible'+@MonthText+'Mths

Select a.CINID, ['+@MonthText+'] as TranCount
into Staging.HeadroomEligible'+@MonthText+'Mths
from staging.Headroom_ActMths as a
inner join Staging.Activated4MthDistinct as b
	on a.CinID = b.CinID
Where ['+@MonthText+ '] >= ('
			+@MonthText+ '*3)  and
	  b.DistinctMonths > 2'
Select @MonthText
Exec sp_ExecuteSQL @Qry
Set @Row =  @Row+1
End


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'ShareofWallet_EligibleCustomersV1_5' and
		TableSchemaName = '' and
		TableName = 'Eligibility Calculation' and
		EndDate is null

/*--------------------------------------------------------------------------------------------------
------------------------------------Insert into JobLog Table----------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

End