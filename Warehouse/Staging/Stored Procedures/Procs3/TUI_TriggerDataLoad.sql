/*

Author:		Suraj Chahal
Date:		12th April 2013
Purpose:	This statement is to load 90 days worth of TUI data into the Trigger Data 
		table ready to be used to pull the TUI Triggers for the offers
		 
Notes:		Amended to create stored procedure and to later automate

*/

CREATE PROCEDURE [Staging].[TUI_TriggerDataLoad]
AS
BEGIN
/*
if object_id('staging.JobLog_Temp') is not null drop table staging.JobLog_Temp

CREATE TABLE [Staging].[JobLog_Temp](
	[JobLogID] [int] IDENTITY(1,1) NOT NULL,
	[StoredProcedureName] [varchar](100) NOT NULL,
	[TableSchemaName] [varchar](25) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[TableRowCount] [bigint] NULL,
	[AppendReload] [char](1) NULL,
PRIMARY KEY CLUSTERED 
(
	[JobLogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
*/

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'TUI_TriggerDataLoad',
		TableSchemaName = 'Relational',
		TableName = 'TriggerData',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
		

------------------------------------------------------------------------------------------------------
---------------------------------------Build a Customer Base------------------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#CustomerBase') is not null drop table #CustomerBase
select FanID,CompositeID,CINID
into #CustomerBase
from warehouse.relational.Customer as c
inner join warehouse.relational.CINList as cl
	on c.SourceUID = cl.CIN
Where Activated = 1 and ActivatedDate is not null
--(80911 row(s) affected)

------------------------------------------------------------------------------------------------------
------------------------------------------- Set Date Range -------------------------------------------
------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#TUI_T1_Trans_Dates') IS NOT NULL DROP TABLE #TUI_T1_Trans_Dates
CREATE TABLE #TUI_T1_Trans_Dates (Contact_Grp varchar(25) NULL
								  ,Renddate   date NULL
								  ,RTrans_Period int NULL 
								  ,Rstartdate date NULL  
								  )                 


INSERT INTO #TUI_T1_Trans_Dates VALUES ('1.Email'
									    ,GETDATE()    --last date we want to consider recent transactions for 
									    ,'90'            -- Number of days looking back at transactions for
									    ,NULL          
									    )
									    
UPDATE #TUI_T1_Trans_Dates
SET Rstartdate = dateadd(day,-RTrans_Period+1,Renddate )
FROM #TUI_T1_Trans_Dates

--select * from #TUI_T1_Trans_Dates
------------------------------------------------------------------------------------------------------
------------------------------------------- Tui Trigger C --------------------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#TUI_Trigger_Trans_C') is not null drop table #TUI_Trigger_Trans_C

select FanID
      ,CompositeID
      ,ct.CINID
      ,mcc as MerchantCategoryCode
      ,amount as TransactionAmount
      ,TranDate as TransactionDate
      ,Narrative as  LocationName
	  ,case 
			when  Amount<= -20 then 1 
			else 0 
	   end as Neg_Trans
	  ,'C' as TriggerLetter  
into #TUI_Trigger_Trans_C
from	Warehouse.relational.CardTransaction as ct with (nolock)
inner join #CustomerBase as cb
	on ct.CINID = cb.CINID
where MCC in (select MCC from Warehouse.Relational.MCCs_Travel 
								where MCC_Desc like 'Travel Agent' )
AND FanID in (select distinct FanID from #CustomerBase)
and TranDate <= (select MAX(Renddate) from #TUI_T1_Trans_Dates)
and TranDate >= (select MIN(Rstartdate) from #TUI_T1_Trans_Dates)
--(13792 row(s) affected)
--6m30s
------------------------------------------------------------------------------------------------------
-------------------------------------- Tui Trigger D - Holiday Ancillary------------------------------
------------------------------------------------------------------------------------------------------

-- D Holiday Ancillary

if object_id('tempdb..#TUI_Trigger_Trans_D') is not null drop table #TUI_Trigger_Trans_D

select FanID
      ,CompositeID
      ,ct.CINID
      ,mcc as MerchantCategoryCode
      ,amount as TransactionAmount
      ,TranDate as TransactionDate
      ,Narrative as  LocationName
 -- flag any neg trans as indicate cancellation and exclude customer -- making less £20 to indicate cancellations rather than balance reset.  A lot for -£1 on Enterprise cars
	  ,case 
			when  Amount<= -20 then 1 
			else 0 
	   end as Neg_Trans
	  ,'D' as TriggerLetter  
into #TUI_Trigger_Trans_D
from Warehouse.relational.CardTransaction as ct with (nolock)
inner join #CustomerBase as cb
	on ct.CINID = cb.CINID
where MCC in (select MCC from Warehouse.Relational.MCCs_Travel 
								where MCC_Desc in ('Misc -DM','Car Rental'))
								-- Would be good to include Aiport parking comp of NCP when data cleaner
AND FanID in (select distinct FanID from #CustomerBase)
and TranDate <= (select MAX(Renddate) from #TUI_T1_Trans_Dates)
and TranDate >= (select MIN(Rstartdate) from #TUI_T1_Trans_Dates)

AND MCC not in (7513)   -- Decided to take this out - but better to ammend MCC table
AND Narrative NOT LIKE ('%ZIPCAR%')
AND Narrative NOT LIKE ('%HELPHIRE%')
AND Narrative NOT LIKE ('%CITY CAR%')
AND Narrative NOT LIKE ('%STREETCAR.CO.UK%')      
--(2211 row(s) affected)

------------------------------------------------------------------------------------------------------
------------------------------------------ Tui Trigger E Deposits-------------------------------------
------------------------------------------------------------------------------------------------------

if object_id('tempdb..#TUI_Trigger_Trans_E') is not null drop table #TUI_Trigger_Trans_E

select FanID
      ,CompositeID
      ,ct.CINID
      ,mcc as MerchantCategoryCode
      ,amount as TransactionAmount
      ,TranDate as TransactionDate
      ,ct.Narrative as  LocationName
	  ,Neg_Trans = 0
	  ,'E' as TriggerLetter  
into #TUI_Trigger_Trans_E
from Warehouse.relational.CardTransaction as ct with (nolock)
inner join #CustomerBase as cb
	on ct.CINID = cb.CINID
inner join warehouse.relational.BrandMID as BM
	on ct.BrandMIDID = bm.BrandMIDID
WHERE FanID in (select distinct FanID from #CustomerBase)
and TranDate <= (select MAX(Renddate) from #TUI_T1_Trans_Dates)
and TranDate >= (select MIN(Rstartdate) from #TUI_T1_Trans_Dates)
AND (Amount = 150 OR Amount=200)  --UPDATED B5
and MCC in  (select distinct MCC from Warehouse.Relational.MCCs_Travel 
								where MCC_Desc like 'Travel Agent' )
and bm.BrandID not in (160,443)								
/*and isnull(RetailOutletID,0) not in (select OutletID 
									from warehouse.Relational.Outlet 
									where PartnerID in ('3962', '3963')
									)  -- getting rid of TUI
*/
--(225 row(s) affected)
------------------------------------------------------------------------------------------------------
-------------------------------------- Tui Trigger F - Airlines---------------------------------------
------------------------------------------------------------------------------------------------------

if object_id('tempdb..#TUI_Trigger_Trans_F') is not null drop table #TUI_Trigger_Trans_F

select FanID
      ,CompositeID
	  ,ct.CINID
      ,mcc as MerchantCategoryCode
      ,amount as TransactionAmount
      ,TranDate as TransactionDate
      ,ct.Narrative as  LocationName
		  ,case 
			when  Amount<= -20 then 1 
			else 0 
	   end as Neg_Trans
	  ,'F' as TriggerLetter  
into #TUI_Trigger_Trans_F
from Warehouse.relational.CardTransaction as ct with (nolock)
inner join #CustomerBase as cb
	on ct.CINID = cb.CINID
where MCC in (select MCC from Warehouse.Relational.MCCs_Travel where MCC_Desc like 'Airlines' )
AND FanID in (select distinct FanID from #CustomerBase)
and TranDate <= (select MAX(Renddate) from #TUI_T1_Trans_Dates)
and TranDate >= (select MIN(Rstartdate) from #TUI_T1_Trans_Dates)

-- (8655 row(s) affected)
--4m 40s

------------------------------------------------------------------------------------------------------
-------------------------------------- Tui Trigger G - Lodgings --------------------------------------
------------------------------------------------------------------------------------------------------

if object_id('tempdb..#TUI_Trigger_Trans_G') is not null drop table #TUI_Trigger_Trans_G

select FanID
      ,CompositeID
   	  ,ct.CINID
      ,mcc as MerchantCategoryCode
      ,amount as TransactionAmount
      ,TranDate as TransactionDate
      ,ct.Narrative as  LocationName
	  ,case 
			when  Amount<= -15 then 1 
			else 0 
	   end as Neg_Trans
	  ,'G' as TriggerLetter  
into #TUI_Trigger_Trans_G
from Warehouse.relational.CardTransaction as ct with (nolock)
inner join #CustomerBase as cb
	on ct.CINID = cb.CINID
where MCC in (select MCC from Warehouse.Relational.MCCs_Travel where MCC_Desc like 'Lodgings' )
AND FanID in (select distinct FanID from #CustomerBase)
and TranDate <= (select MAX(Renddate) from #TUI_T1_Trans_Dates)
and TranDate >= (select MIN(Rstartdate) from #TUI_T1_Trans_Dates)
AND Narrative not like ('%NERO%')  -- for some reason Cafe nero in here
--20307


------------------------------------------------------------------------------------------------------
-------------------------------- Create Combined Transaction Table -----------------------------------
------------------------------------------------------------------------------------------------------
if object_id('Warehouse.relational.TriggerData') is not null drop table Warehouse.relational.TriggerData
Select * 
Into Warehouse.relational.TriggerData
from
(Select * from #TUI_Trigger_Trans_C union all 
Select * from #TUI_Trigger_Trans_D union all 
Select * from #TUI_Trigger_Trans_E union all 
Select * from #TUI_Trigger_Trans_F union all 
Select * from #TUI_Trigger_Trans_G 
) as a




/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'TUI_TriggerDataLoad' and
		TableSchemaName = 'Relational' and
		TableName = 'TriggerData' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Warehouse.relational.TriggerData)
where	StoredProcedureName = 'TUI_TriggerDataLoad' and
		TableSchemaName = 'Relational' and
		TableName = 'TriggerData' and
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

--drop table staging.JobLog_Temp

Truncate table staging.JobLog_Temp

END