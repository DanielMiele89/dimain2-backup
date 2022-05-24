/*
Author:		Suraj Chahal	
Date:		15 March 2013
Purpose:	Extract last 90 days daily transaction data for trigger offer.
		Limited to just transactions that have a FanID against them
			
Notes:		Usually 40-50minutes to run
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.

*/

CREATE PROCEDURE [Staging].[SP_AnalyticsLoad_90DayTransactionalData]
AS
BEGIN

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



/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Warehouse.Staging.JobLog_Temp
Select	StoredProcedureName = 'SP_AnalyticsLoad_90DayTransactionalData',
		TableSchemaName = 'dbo',
		TableName = 'TransRecent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

-----------------------------------------------------------------------------------------------------
--get the IDs of all the files loaded within the 90 days
--this should include all transactions made in the (90  + few days)
if object_id('tempdb..#file') is not null drop table #file
select	*
into	#file
from	slc_report.dbo.NobleFiles
where	cast(indate as date) >= cast(dateadd(dd,-90,getdate()) as date)
		and FileType = 'TRANS'


--Build a temp table of Partner details against outlets.
--This allows us to join efficiently in the next query.
if object_id('tempdb..#outlet') is not null drop table #outlet
select	ro.ID	as RetailOutletID,
	ro.PartnerID,
	cast(p.Name	as varchar(30)) as RetailerName	--reduce length to conserve space, as we'll add this against each transaction
into	#outlet		
from	slc_report.dbo.RetailOutlet ro						
		inner join slc_report.dbo.Partner p on ro.PartnerID = p.ID


if object_id('Analytics.dbo.TransRecent') is not null drop table Analytics.dbo.TransRecent
select	nth.FileID,
		nth.FanID,
		cast(nth.RowNum as int)				as ArchiveRowNumber,
		cast(nth.MerchantID as varchar(15))		as MerchantID,
		cast(nth.LocationName as varchar(22))		as LocationName,
		cast(nth.LocationAddress as varchar(18))	as LocationAddress,
		cast(nth.LocationCountry as varchar(3))		as LocationCountry,
		cast(nth.MCC as varchar(4))			as MerchantCategoryCode,
		cast(nth.TranDate as date)			as TransactionDate,
		cast(nth.Amount as money)			as TransactionAmount,
		cast(nth.PaymentCardID as bigint)		as PaymentCardID,
		cast(nth.CompositeID as bigint)			as CompositeID,
		nth.RetailOutletID,
		o.PartnerID					as LiveSystemPartnerID,
		o.RetailerName
into	Analytics.dbo.TransRecent
from	Archive.dbo.NobleTransactionHistory nth with (nolock)
		inner join #file f on nth.FileID = f.ID
		left outer join #outlet o on o.RetailOutletID = nth.RetailOutletID
where	FanID is not null	

		
--Build indexes
create clustered index i_Fan on Analytics.dbo.TransRecent (FanID)
create nonclustered index i_CompositeID on Analytics.dbo.TransRecent (CompositeID)
create nonclustered index i_MerchantID on Analytics.dbo.TransRecent (MerchantID)
create nonclustered index i_LocationName on Analytics.dbo.TransRecent (LocationName)
create nonclustered index i_MerchantCategoryCode on Analytics.dbo.TransRecent (MerchantCategoryCode)
create nonclustered index i_TransactionDate on Analytics.dbo.TransRecent (TransactionDate)
create nonclustered index i_LiveSystemPartnerID on Analytics.dbo.TransRecent (LiveSystemPartnerID)
create nonclustered index i_RetailerName on Analytics.dbo.TransRecent (RetailerName)


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  warehouse.Staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SP_AnalyticsLoad_90DayTransactionalData' and
		TableSchemaName = 'dbo' and
		TableName = 'TransRecent' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Warehouse.Staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Analytics.dbo.TransRecent)
where	StoredProcedureName = 'SP_AnalyticsLoad_90DayTransactionalData' and
		TableSchemaName = 'dbo' and
		TableName = 'TransRecent' and
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
END