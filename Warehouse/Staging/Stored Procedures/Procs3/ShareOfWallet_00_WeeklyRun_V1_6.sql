CREATE Procedure [Staging].[ShareOfWallet_00_WeeklyRun_V1_6]
as

Truncate table staging.JobLog_Temp
/*----------------------------------------------------------------------------------------------------
  -----------------------------Write entry to JobLog_Temp Table--------------------------------------------
  ----------------------------------------------------------------------------------------------------*/
		Insert into staging.JobLog_Temp
		Select	StoredProcedureName = 'ShareOfWallet_00_WeeklyRun_V1_6',
			TableSchemaName = 'Relational',
			TableName = 'SoW - Setup',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

-------------------------------------------------------------------------------------------------------
---------------------------Get list of Partners/Partner Groups to be Sow'ed----------------------------
-------------------------------------------------------------------------------------------------------
if object_id('Staging.HTMs') is not null drop table Staging.HTMs
Select	ROW_NUMBER() OVER(ORDER BY PartnerString Asc) AS RowNo, 
		PartnerString
Into Staging.HTMs		
From Relational.PartnerStrings
Where HTM_Current = 1
----------------------------------------------------------------------------------------------------
-------------------------------------------Increment EndDate for SoW--------------------------------
----------------------------------------------------------------------------------------------------
Declare @CTHDate date,@CTDate date
Set @CTHDate = (Select Max(TranDate) from Warehouse.Relational.ConsumerTransactionHolding as cth)
Set @CTDate =  (Select Max(TranDate) from Warehouse.Relational.ConsumerTransaction as ct)

Update Staging.ShareofWallet_EndDate
Set EndDate = Coalesce(@CTHDate,@CTDate)
/*--------------------------------------------------------------------------------------------------
  ---------------------------Update entry in JobLog_Temp Table with End Date-------------------------------
  ----------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = 'ShareOfWallet_00_WeeklyRun_V1_6' and
				TableSchemaName = 'Relational' and
				TableName = 'SoW - Setup' and
				EndDate is null

-------------------------------------------------------------------------------------------------------
-----------------------------Loop to run all Share of Wallets------------------------------------------
-------------------------------------------------------------------------------------------------------
Declare @RowNo Int, @MaxRowNo int, @PartnerString varchar(100)
Set @RowNo = 1
Set @MaxRowNo = (Select Max(RowNo) from Staging.HTMs)
Select @RowNo, @MaxRowNo
--Loop for each Partner or Partner group
While @RowNo <= @MaxRowNo
Begin
		Set @PartnerString = (Select PartnerString from Staging.HTMs where RowNo = @RowNo)

	/*----------------------------------------------------------------------------------------------------
	  -----------------------------Write entry to JobLog_Temp Table--------------------------------------------
	  ----------------------------------------------------------------------------------------------------*/
		Insert into staging.JobLog_Temp
		Select	StoredProcedureName = 'ShareOfWallet_00_WeeklyRun_V1_6',
			TableSchemaName = 'Relational',
			TableName = 'SoW'+@PartnerString,
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	/*----------------------------------------------------------------------------------------------------
	  -------------------------------------------Run Individual SoW---------------------------------------
	  ----------------------------------------------------------------------------------------------------*/
	  	Exec [Staging].[ShareOfWallet_SegmentAssignment_00_V1_5] @PartnerString, 0
		Set @RowNo = @RowNo + 1
	/*--------------------------------------------------------------------------------------------------
	  ---------------------------Update entry in JobLog_Temp Table with End Date-------------------------------
	  ----------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = 'ShareOfWallet_00_WeeklyRun_V1_6' and
				TableSchemaName = 'Relational' and
				TableName = 'SoW'+@PartnerString and
				EndDate is null

End
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