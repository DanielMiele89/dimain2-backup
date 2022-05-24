
/*
		Author:		Stuart Barnley
		Date:		07th July 2014

		Purpose:	Additional Cashback Awards - This pull off all the additional
					Cashback Awards. This will start with contactless, then Credit Card.

		Notes:		Point 1 - this loops back to match table, we may have to revisit this for speed later.

					30-09-2014 SB - This update makes ure it is only include customers from the customer table.
					12-06-2015 SB -This is updated to include DirectDebitOriginatorID
					30-09-2015 SB - Optimised on advice of DBA
					09-02-2016 SB - change made to deal with indexes
*/
CREATE Procedure [Staging].[WarehouseLoad_AdditionalCashbackAwardsV1_10]
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwardsV1_10',
		TableSchemaName = 'Relational',
		TableName = 'AdditionalCashbackAward',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
------------------------------------populate customer Table-----------------------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Customer') is not null drop table #Customer
Select FanID,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
Into #Customer
From Relational.Customer

Create Clustered Index ix_Customer_FanID on #Customer (FanID)

/*--------------------------------------------------------------------------------------------------
------------------------------------Create Typesd Table Table---------------------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Types') is not null drop table #Types
Select aca.*,tt.Multiplier
Into #Types
From Relational.[AdditionalCashbackAwardType] as aca
inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
	on	aca.TransactionTypeID = tt.ID
----------------------------------------------------------------------------------------
-----------------------------------Set Parameters---------------------------------------
----------------------------------------------------------------------------------------
Declare --@DayDate date, 
		@MaxDay date,@RowNo int, @MaxRowNo int, @ChunkSize int
--Set @DayDate = Cast('July 01, 2014' as date)
Set @ChunkSize = 50000

--------------------------------------------------------------------------------------
--------------------Pull data and add MatchIDs where appropriate----------------------
--------------------------------------------------------------------------------------

--This process uses the #AddedDays table to pull the data in chunks

Set @RowNo = 1
Set @MaxRowNo = (Select Max(RowNo) from #Customer)

ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  DISABLE
ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  DISABLE


Truncate table Relational.AdditionalCashbackAward

While @RowNo <= @MaxRowNo
Begin
	------------------------------------------------------------------------------
	--------------Get Additional Cashback Awards with a PanID---------------------
	------------------------------------------------------------------------------
	
	Insert Into Relational.AdditionalCashbackAward

	select t.Matchid as MatchID,
           t.VectorMajorID as FileID,
           t.VectorMinorID as RowNum,
           t.FanID,
           t.[Date] as TranDate,
           t.ProcessDate as AddedDate,
           t.Price as Amount,
           t.ClubCash*tt.Multiplier as CashbackEarned,
           t.ActivationDays,
           tt.AdditionalCashbackAwardTypeID,
           Case
				When CardTypeID = 1 then 1 -- Credit Card
                When CardTypeID = 2 then 0 -- Debit Card
                When t.DirectDebitOriginatorID IS not null then 2 -- Direct Debit
                Else 0
           End as PaymentMethodID,
           t.DirectDebitOriginatorID
	from #Customer as c
	inner loop join SLC_Report.DBO.Trans as t with (nolock)
		on t.FanID = c.fanid
	inner join #Types as tt
        on tt.ItemID = t.ItemID and
           tt.TransactionTypeID = t.TypeID          
    Left Outer join SLC_Report..Pan as p
        on t.PanID = p.ID
    Left Outer join SLC_Report..PaymentCard as pc
        on p.PaymentCardID = pc.ID
    Where t.VectorMajorID is not null and
          t.VectorMinorID is not null and
          c.RowNo Between @RowNo and @RowNo+ (@ChunkSize-1)

	Set @RowNo = @RowNo+@ChunkSize
End
/*--------------------------------------------------------------------------------------------------
------------------------Remove those records with a MatchID and no TRANS record---------------------
----------------------------------------------------------------------------------------------------*/
Update Relational.AdditionalCashbackAward
Set MatchID = m.ID
from Relational.AdditionalCashbackAward as aca
inner join SLC_Report..match as m with (nolock)
	on	aca.FileID = m.VectorMajorID and
		aca.RowNum = m.VectorMinorID
inner join Relational.PartnerTrans as pt
	on	m.ID = pt.MatchID


ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  REBUILD
ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  REBUILD

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwardsV1_10' and
		TableSchemaName = 'Relational' and
		TableName = 'AdditionalCashbackAward' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.AdditionalCashbackAward)
where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwardsV1_10' and
		TableSchemaName = 'Relational' and
		TableName = 'AdditionalCashbackAward' and
		TableRowCount is null
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
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

--select * from warehouse.relational.paymentmethod