/*

	Author:		Stuart Barnley


	Date:		12th May 2017


	Purpose:	To pull through the Amazon Credit Card incentives

	
*/
CREATE Procedure [Staging].[WarehouseLoad_AdditionalCashbackAwards_CC_Amazon]
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_CC_Amazon',
		TableSchemaName = 'Relational',
		TableName = 'AdditionalCashbackAward',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
/*--------------------------------------------------------------------------------------------------
-----------------------------Pull off a list of Transactions for Amazon Offer-----------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Trans') is not null drop table #Trans
Select	ID as TranID,
		t.ItemID,
		a.ACATypeID
Into #Trans
From SLC_Report.dbo.Trans as t
inner join Warehouse.Staging.AdditionalCashbackAwards_MonthlyCCOffers as a
	on t.ItemID = a.ItemID
Where	TypeID = 1

/*--------------------------------------------------------------------------------------------------
-----------------------------Find out number of last entry------------------------------------------
----------------------------------------------------------------------------------------------------*/

Declare @MaxRow int

Set @MaxRow = (	Select Max(RowNum) 
				From Staging.RBSGFundedCreditCardMonthlyOffers
			  )

Set @MaxRow = coalesce(@MaxRow,0)

/*--------------------------------------------------------------------------------------------------
-------------------------------Insert missing Transactions into listing table-----------------------
----------------------------------------------------------------------------------------------------*/

Insert into Staging.RBSGFundedCreditCardMonthlyOffers 
Select	t.TranID,
		-1 as FileID,
		ROW_NUMBER() OVER(ORDER BY t.TranID ASC)+@MaxRow AS RowNum,
		t.ACATypeID	as AdditionalCashbackAwardTypeID
From #Trans as t
Left Outer Join Staging.RBSGFundedCreditCardMonthlyOffers as b
	on t.TranID = b.TranID
Where b.TranID is null

--- INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  DISABLE
--ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  DISABLE

Delete From Relational.AdditionalCashbackAward 
Where AdditionalCashbackAwardTypeID in 
		(Select ACATypeID From Warehouse.Staging.AdditionalCashbackAwards_MonthlyCCOffers as a)

/*--------------------------------------------------------------------------------------------------
------------------------------------Create Typesd Table Table---------------------------------------
----------------------------------------------------------------------------------------------------*/
if object_id('tempdb..#Types') is not null drop table #Types
Select aca.*,tt.Multiplier
Into #Types
From Relational.[AdditionalCashbackAwardType] as aca
inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
	on	aca.TransactionTypeID = tt.ID

------------------------------------------------------------------------------
--------------Get Additional Cashback Awards with a PanID---------------------
------------------------------------------------------------------------------
Declare @RowCount int

Insert Into Relational.AdditionalCashbackAward
	
	select t.Matchid as MatchID,
           a.FileID as FileID,
           a.RowNum as RowNum,
           t.FanID,
           t.[Date] as TranDate,
           t.ProcessDate as AddedDate,
           t.Price as Amount,
           t.ClubCash*tt.Multiplier as CashbackEarned,
           t.ActivationDays,
           tt.AdditionalCashbackAwardTypeID,
           1 as PaymentMethodID,
           t.DirectDebitOriginatorID
	from Warehouse.relational.Customer as c with (nolock)
	inner join SLC_Report.DBO.Trans as t with (nolock)
		on t.FanID = c.fanid
	inner join #Types as tt
        on tt.ItemID = t.ItemID and
           tt.TransactionTypeID = t.TypeID          
	inner join Staging.RBSGFundedCreditCardMonthlyOffers as a
		on t.ID = a.TranID
	--Set @Rowcount = @@RowCount

--ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  REBUILD
--ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  REBUILD

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_CC_Amazon' and
		TableSchemaName = 'Relational' and
		TableName = 'AdditionalCashbackAward' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
--Update  staging.JobLog_Temp
--Set		TableRowCount = @Rowcount
--where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_CC_Amazon' and
--		TableSchemaName = 'Relational' and
--		TableName = 'AdditionalCashbackAward' and
--		TableRowCount is null
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

