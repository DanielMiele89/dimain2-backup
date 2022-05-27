/*
	Author:		Stuart Barnley
	Date:		29-04-2014

	Purpose:	Everytime a SoW is run it constructs a dataset, therefore we need to remove the previous datasets.
				This process will do it in one go
*/
CREATE Procedure [Staging].[ShareOfWallet_ClearOutOldDataTablesV1_2]
as
/*----------------------------------------------------------------------------------------------------
  -----------------------------Write entry to JobLog_Temp Table---------------------------------------
  ----------------------------------------------------------------------------------------------------*/
		Insert into staging.JobLog_Temp
		Select	StoredProcedureName = 'ShareOfWallet_ClearOutOldDataTablesV1_2',
			TableSchemaName = 'Staging',
			TableName = 'All Old SoW Datasets',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'D'
/*--------------------------------------------------------------------------------------------------
  -----------------------------Populate a list of SoW tables top be removed-------------------------
  --------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#t1') is not null drop table #t1
Select	'Drop table Staging.'+TableName as SQLCommand,
		ROW_NUMBER() OVER(ORDER BY TableName Asc) AS RowNo
into #t1
from 
(Select	s.name as SchemaName,
		t.Name as TableName,
		left(t.Name,Len(t.Name)-8) as Partners,
		ROW_NUMBER() OVER(PARTITION BY left(t.Name,Len(t.Name)-8) ORDER BY t.Name DESC) AS RowNo
from sys.tables as t
inner join sys.schemas as s
	on t.schema_id = s.schema_id
Where	t.name like 'ShareofWallet_%' and 
		s.name = 'Staging'
) as a
inner join 
(Select 'ShareofWallet_'+PartnerName_Formated as partners
from Relational.PartnerStrings
Where HTM_Current = 1
) as b
	on a.Partners = b.partners
Where RowNo > 1

--select * from #t1

/*--------------------------------------------------------------------------------------------------
  ---------------------------Delete Tables to be deleted------------------------
  --------------------------------------------------------------------------------------------------*/

declare @RowNo int, @MaxNo int,@Qry nvarchar(200)
Set @RowNo = 1
Set @MaxNo = (Select Count(RowNo) from #t1)

While @RowNo <= @MaxNo
Begin
	Set @Qry = (Select SQLCommand from #t1 Where RowNo = @RowNo)
	Exec SP_ExecuteSQL @Qry
	Set @RowNo = @RowNo+1
End
/*--------------------------------------------------------------------------------------------------
  ---------------------------Update entry in JobLog_Temp Table with End Date------------------------
  --------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = 'ShareOfWallet_ClearOutOldDataTablesV1_2' and
				TableSchemaName = 'Staging' and
				TableName = 'All Old SoW Datasets' and
				EndDate is null
/*--------------------------------------------------------------------------------------------------
  ---------------------------Update entry in JobLog_Temp Table with End Date------------------------
  --------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		TableRowCount = @MaxNo
		where	StoredProcedureName = 'ShareOfWallet_00_WeeklyRun_V1_2' and
				TableSchemaName = 'Staging' and
				TableName = 'All Old SoW Datasets'

/*--------------------------------------------------------------------------------------------------
  ---------------------------Add entry in JobLog Table with End Date-------------------------------
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