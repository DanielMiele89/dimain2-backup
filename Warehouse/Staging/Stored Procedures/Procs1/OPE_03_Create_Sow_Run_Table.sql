CREATE Procedure [Staging].[OPE_03_Create_Sow_Run_Table]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'OPE_03_Create_Sow_Run_Table',
		TableSchemaName = 'Staging',
		TableName = 'OPE_SOWRunDate',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
------------------------------------------------------------------------------------------------------
----------------------------------------Create List of Partners---------------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Partners') is not null drop table #Partners
select	p.*,
		ROW_NUMBER() OVER(ORDER BY p.PartnerID Asc) AS RowID
into #Partners
from Relational.Partner as p
Left Outer join Relational.PartnerGroups as pg
	on p.PartnerID = pg.PartnerID and UseForReport = 1
Where	pg.PartnerID is null and
		p.BrandID is not null
------------------------------------------------------------------------------------------------------
---------------------------------------Find latest Share of wallet run--------------------------------
------------------------------------------------------------------------------------------------------
if object_id('Staging.OPE_SOWRunDate') is not null drop table Staging.OPE_SOWRunDate
Select a.PartnerID,a.PartnerName,a.BrandID,a.BrandName,SoW.Mth,SoW.PartnerName_Formated,LastRun,StartDate,EndDate,
		ROW_NUMBER() OVER(ORDER BY a.PartnerID) AS RowNo
Into Staging.OPE_SOWRunDate
from 
(
Select p.PartnerID,p.PartnerName,p.BrandID,p.BrandName,MAX(RunTime) as LastRun
From #Partners as p
inner join Relational.ShareofWallet_RunLog as SoW
	on ltrim(rtrim(Cast(p.PartnerID as char))) = SoW.PartnerString
Group by p.PartnerID,p.PartnerName,p.BrandID,p.BrandName
) as a
inner join Warehouse.Relational.ShareofWallet_RunLog as SoW
	on a.LastRun = SoW.RunTime
inner join Warehouse.Relational.ShareOfWallet_Dates as d
	on SoW.ID = d.ShareofWalletID
Where LastRun > Dateadd(day,-45,CAST(getdate() as DATE))

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'OPE_03_Create_Sow_Run_Table' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_SOWRunDate' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(*) from Staging.OPE_SOWRunDate)
where	StoredProcedureName = 'OPE_03_Create_Sow_Run_Table' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_SOWRunDate' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
------------------------------------------Add entry in JobLog Table --------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
------------------------------------------Truncate JobLog temporary Table --------------------------
----------------------------------------------------------------------------------------------------*/
Truncate Table staging.JobLog_Temp
