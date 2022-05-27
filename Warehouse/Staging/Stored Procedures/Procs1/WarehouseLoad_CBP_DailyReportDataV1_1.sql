/*	Author:			Stuart Barnley
	Description:	Procedures creates the data that is needed for the Data Warehouse assessment reporting

	Update:			20-02-2014 SB - Updated to remove references to Warehouse
*/

CREATE Procedure [Staging].[WarehouseLoad_CBP_DailyReportDataV1_1] (@Date date)
AS
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_CBP_DailyReportDataV1_1',
		TableSchemaName = 'Staging',
		TableName = 'DailyCashBackPlusReport_Data',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
/*--------------------------------------------------------------------------------------------------
-----------------------------Delete Previous Entries if re-run--------------------------------------
----------------------------------------------------------------------------------------------------*/

Delete from Staging.DailyCashBackPlusReport_Data
Where DataDate = @Date
---------------------------------------------------------------------------------------------------
---------------------------Calculate extra rows added to tables------------------------------------
---------------------------------------------------------------------------------------------------
if object_id('tempdb..#DailyReport') is not null drop table #DailyReport
Select * 
into #DailyReport
from 
(Select	1 as TypeID,
		c.TableID,
		Cast('Tables (extra rows added)' as varchar(200)) as [Type],
		Cast(a.TableName as varchar(200)) as Description1,
		Cast(a.SchemaName as varchar(250))  as Description2,
		a.[RowCount]-b.[RowCount] as [Count]
from [Staging].[Database_TableRowCounts] as A
inner join [Staging].[Database_TableRowCounts] as B
	on	a.TableName = b.TableName and
		a.SchemaName = b.SchemaName and
		a.DatabaseName = b.DatabaseName and
		a.[Date] = @Date and
		b.[Date] = Dateadd(day,-1,@Date)
inner join [Staging].[Database_TablesToBeAssessed] as c
	on	a.TableName = c.TableName and
		a.SchemaName = c.SchemaName and
		a.DatabaseName = c.DatabaseName and
		c.ToBeAssessed = 1
Union all
--***********************************************************************************************--
--*********************************Customer Journeys - Begin*************************************--
--***********************************************************************************************--


---------------------------------------------------------------------------------------------------
---------------------------Calculate genuine movement between customer journeys--------------------
---------------------------------------------------------------------------------------------------
Select	3 as TypeID, 
		(ROW_NUMBER() OVER(ORDER BY Case	
										When left(CJ.CJ_Status,1) = 'M' then 1 
										When left(CJ.CJ_Status,1) = 'S' then 2 
										When left(CJ.CJ_Status,1) = 'R' then 3 
										Else 4 
									End,CJ.CJ_Status))+1 AS TableID,
		'Customer Journey' as [Type],
		'Moved into' as Description1, 
		cj.CJ_Status as Description2,
		isnull(a.RecordCount,0) as [Count]
from
	(Select Distinct 
			Case
				When left(CustomerJourneyStatus,3) like 'MOT' then CustomerJourneyStatus
				When left(CustomerJourneyStatus,3) like 'Red' then 'Redeemer'
				When left(CustomerJourneyStatus,3) like 'Sav' then 'Saver'
				Else CustomerJourneyStatus
			End as CJ_Status
	from relational.customerJourney
	Where CustomerJourneyStatus <> 'Deactivated' 
	) as cj
Left outer join 
	(Select CJ_Status,Count(*) as RecordCount
	 from 
		(Select	FanID,
				Case
					When left(CustomerJourneyStatus,3) like 'MOT' then CustomerJourneyStatus
					When left(CustomerJourneyStatus,3) like 'Red' then 'Redeemer'
					When left(CustomerJourneyStatus,3) like 'Sav' then 'Saver'
					Else CustomerJourneyStatus
				End as CJ_Status
		 from relational.CustomerJourney as CJ with (NoLock)
		 Where EndDate is null and StartDate = Dateadd(day,-1,@Date)
		) as a
	inner join relational.CustomerJourney as CJ with (NoLock)
	on a.FanID = cj.FanID and
		EndDate = Dateadd(day,-2,@Date)
	Where a.CJ_Status <> Left(cj.CustomerJourneyStatus,len(a.CJ_Status))
	Group by CJ_Status
	) as a
	on cj.CJ_Status = a.CJ_Status
Union all
---------------------------------------------------------------------------------------------------
--------------------------Calculate first ever customer journey statues created--------------------
---------------------------------------------------------------------------------------------------
Select	3 as TypeID,
		1 as TableID,
		'Customer Journey' as [Type],
		'New Customers' as Description1, 
		'N/A' as Description2,
		Count(FanID) as RecordCount
From 
(Select a.fanID
From
(Select cj.FanID
from relational.CustomerJourney as cj with (nolock)
Where Startdate = Dateadd(day,-1,@Date)
) as a
inner join relational.CustomerJourney as cj with (nolock)
	on a.fanid = cj.fanid
Group by a.FanID
	Having Count(*) = 1
) as a
) as a
Order by TypeID,TableID

--***********************************************************************************************--
--*********************************Customer Journeys - End***************************************--
--***********************************************************************************************--


--***********************************************************************************************--
--*******************************Customer - Activations and Deactivations - Start****************--
--***********************************************************************************************--

---------------------------------------------------------------------------------------------------
--------------------------Calculate Activations and Deactivations created--------------------------
---------------------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers
Select	Count(*) as [Customer Count],
		Sum(Case
				When ActivatedDate = dateadd(day,-1,@Date) then 1
				Else 0
			End) as [New Activations],
		Sum(Case
				When ActivatedDate = dateadd(day,-1,@Date) and 
					 clubid = 132 then 1
				Else 0
			End) as [New Activations Natwest],
		Sum(Case
				When ActivatedDate = dateadd(day,-1,@Date) and 
					 clubid = 138 then 1
				Else 0
			End) as [New Activations RBS],
		Sum(Case
				When DeactivatedDate = dateadd(day,-1,@Date) then 1
				Else 0
			End) as [New Deactivators],
		Sum(Case
				When DeactivatedDate = dateadd(day,-1,@Date) and 
					 clubid = 132 then 1
				Else 0
			End) as [New Deactivators Natwest],
		Sum(Case
				When DeactivatedDate = dateadd(day,-1,@Date) and
					 clubid = 138 then 1
				Else 0
			End) as [New Deactivators RBS]
Into #Customers
from relational.customer with (nolock)

---------------------------------------------------------------------------------------------------
--------------------------------unpivot to match report layout-------------------------------------
---------------------------------------------------------------------------------------------------
Insert into #DailyReport
Select	TypeID,
		ROW_NUMBER() OVER(ORDER BY	Description1,
									Case	
										When Description2 = 'Overall' then 1 
										When Description2 = 'NatWest' then 2 
										When Description2 = 'RBS' then 3 
										Else 4 
									End) AS TableID,
		[Type],
		[Description1],
		[Description2],
		[Count]
From
(Select 2 as TypeID,
	   	'Customer' as [Type], 
		Case	
			When Right([Description],4) = ' RBS' then Left([Description],Len([Description])-4)
			When Right([Description],8) = ' NatWest' then Left([Description],Len([Description])-8)
			Else [Description]
		End as Description1,
		Case	
			When Right([Description],4) = ' RBS' then 'RBS'
			When Right([Description],8) = ' NatWest' then 'NatWest'
			Else 'Overall'
		End as Description2
		,[Count]
From
(Select * from #Customers) as c
Unpivot
([Count] for [Description] in ([Customer Count],[New Activations],[New Activations Natwest],
							   [New Activations RBS],[New Deactivators],[New Deactivators NatWest],
							   [New Deactivators RBS])
) As unPvt
) as a

--***********************************************************************************************--
--********************************Customer - Activations and Deactivations - End*****************--
--***********************************************************************************************--


--***********************************************************************************************--
--**************************************Headroom Targeting Model - Start*************************--
--***********************************************************************************************--
---------------------------------------------------------------------------------------------------------
----------------------------Get list of Partners we regularly HTM----------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Partners') is not null drop table #Partners
Select  Distinct PartnerID
into #Partners
from relational.HeadroomTargetingModel_Members with (nolock)
Where StartDate = dateadd(day,-(datepart(weekday,@Date)-1),@Date)

---------------------------------------------------------------------------------------------------------
---------------------Find Headroom adjustments for those partners we regularly updated-------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#HTM') is not null drop table #HTM
Select	5 as [TypeID],
		'Headroom Targeting Model' as [Type],
		par.PartnerName as Description1,
		g.htmid,
		Case
			When g.HTMID = 1 then 'Insufficient Data'
			Else g.HTM_Description
		End + ' - New to Grouping (Including New Customers)' as Description2,
		Count(1) as [Count]
Into #HTM
from relational.customer as c
inner join relational.HeadroomTargetingModel_Members as htm with (nolock)
	on	c.fanid = htm.fanid and
		EndDate is null and startdate = dateadd(day,-1,@Date)
inner join relational.HeadroomTargetingModel_Groups as g
	on htm.HTMID = g.HTMID
inner join #Partners as p
	on htm.partnerid = p.Partnerid
inner join relational.Partner as Par
	on p.PartnerID = Par.PartnerID
Group by par.PartnerName, g.htmid,g.HTM_Description
Order by par.PartnerName,g.htmid
---------------------------------------------------------------------------------------------------------
----------------------------------Add data to report table-----------------------------------------------
---------------------------------------------------------------------------------------------------------
Insert into #DailyReport
Select	[TypeID],
		ROW_NUMBER() OVER(ORDER BY	Description1,HTMID) AS TableID,
		[Type],
		Description1,
		Description2,
		[Count] 
from #HTM

--***********************************************************************************************--
--**************************************Headroom Targeting Model - End*************************--
--***********************************************************************************************--

---------------------------------------------------------------------------------------------------------
----------------------------------Cashback Balances Updated----------------------------------------------
---------------------------------------------------------------------------------------------------------
Insert into #DailyReport
select	4 as Typeid, 
		1 as TableID, 
		'Cashback Balances' as [Type], 
		'Balances Updated' as Description1, 
		'N/A' as Description2,
		Count(*) as [Count]
from [Staging].[Customer_CashbackBalances] as a with (nolock)
inner join [Staging].[Customer_CashbackBalances] as b with (nolock)
	on a.FanID = b.FanID
Where a.[Date] = @Date and b.[Date] = Dateadd(day,-1,@Date) and
		(a.ClubCashPending <> b.ClubCashPending or a.ClubCashAvailable <> b.ClubCashAvailable)


---------------------------------------------------------------------------------------------
------------------------------Field IDs in Change Log Tables---------------------------------
---------------------------------------------------------------------------------------------
if object_id('tempdb..#DC') is not null drop table #DC
Select ID as TableColumnID,DataType
Into #DC
from Archive.[ChangeLog].[TableColumns] as tc
where ColumnName in ('Title', 'FirstName', 'LastName','Sex','DOB', 'Status','Unsubscribed',
					 'ContactByPost','ContactBySMS','ContactByPhone','DeceasedDate',
					 'Address1','Address2','City','County','PostCode')
---------------------------------------------------------------------------------------------
-----------------------------List of tables of from ChangeLog--------------------------------
---------------------------------------------------------------------------------------------
if object_id('tempdb..#Tables') is not null drop table #Tables
SELECT Name as TableName,ROW_NUMBER() OVER(ORDER BY Name) as RowNo
Into #Tables
FROM Archive.sys.Tables
Where Name like 'DataChangeHistory%' 
---------------------------------------------------------------------------------------------
------------------------------------Counts from each table-----------------------------------
---------------------------------------------------------------------------------------------
Declare @RowNo int,@MaxRowNo int,@Qry nvarchar(max),@DayDate Date
Set @RowNo = 1
set @MaxRowNo = (Select Max(RowNo) From #Tables)
Set @DayDate = Cast(Getdate() as date)
if object_id('tempdb..#T1') is not null drop table #T1
Create table #t1 (TableName nvarchar(250),[Count] int)
While @RowNo <= @MaxRowNo
Begin
	Set @Qry = '
	Insert into #t1
	Select '''+(Select TableName from #Tables Where RowNo = @RowNo)+''' as TableName, Count(*) as [Count] From #dc as dc
	Inner Join Archive.ChangeLog.' + (Select TableName from #Tables Where RowNo = @RowNo) + ' as a with (NoLock)
		on dc.TableColumnID = a.TableColumnsID and Cast(a.Date as date) = '''+Convert(varchar,@DayDate, 107)+''''
	Exec sp_ExecuteSQL @Qry
	Set @RowNo = @RowNo+1
End

Insert Into #DailyReport
select 2 as TypeID,8 as TableID, 'Customer' as [Type], 'Customer Fields Updated' as [Description1], 'N/A' as [Description2], Sum([Count]) as [Count] from #t1

--Create Table Warehouse.Staging.DailyCashBackPlusReport_Data (TypeID int,TableID int, [Type] varchar(200),Description1 varchar(200), Description2 varchar(200), [Count] Int, DataDate Date, RunDate Date)

Insert into Staging.DailyCashBackPlusReport_Data
select *, @Date as DataDate, Cast(getdate() as date) as RunDate
from #DailyReport
Order by TypeID,TableID

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_CBP_DailyReportDataV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'DailyCashBackPlusReport_Data' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.DailyCashBackPlusReport_Data where DataDate = @Date)
where	StoredProcedureName = 'WarehouseLoad_CBP_DailyReportDataV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'DailyCashBackPlusReport_Data' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp