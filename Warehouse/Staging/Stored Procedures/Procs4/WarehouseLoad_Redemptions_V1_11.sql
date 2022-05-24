/*
Author:		Suraj Chahal
Date:		11th March 2013
Purpose:	To Build a Redemption table in the staging schema
		then Relational schema of the Warehouse database
		
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.		
			
			28/01/2014 SB - Amended to allow trade up values to be added for trades up where value is not 
						    obvious using new table 'Warehouse.Relational.RedemptionItem_TradeUpValue'
			05/02/2014 SB - Extra code added to deal with Caffe Nero redemption labelled as 'Caffé Nero'
			06/02/2014 SB - Amend to allow for Redemptions Fulfilled that were not ordered (speicifc 
							issue that needed to be resolved).
			20-02-2014 SB - Amended to remove Warehouse referencing
			10-09-2014 SC - Added Index Rebuild
			19-03-2015 SB - Extra code to deal with Zinio offers
			16-12-2015 SB - Coded to link to RI Staging table to pull through Partner Info
			09-08-2017 SB - Speed Up process to find extra time in ETL load
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_Redemptions_V1_11]
AS
BEGIN


/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11',
		TableSchemaName = 'Staging',
		TableName = 'Redemptions',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

---------------------------------------------------------------------------------------------------------
------------------------------------- Pull out a list of Cancelled redemptions --------------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#Cancelled') is not null drop table #Cancelled
select ItemID as TransID,1 as Cancelled
Into #Cancelled
from SLC_Report.dbo.trans t2 where t2.typeid=4

Create Clustered index cix_Cancelled_ItemID on #Cancelled (TransID)
---------------------------------------------------------------------------------------------------------
--------------------Pull out a list of redemptions including those later cancelled-----------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Redemptions') is not null drop table #Redemptions
select	t.FanID,
		c.CompositeID,
		t.id as TranID,
        Min(t.Date) as RedeemDate,
        ri.RedeemType,
        r.Description as PrivateDescription,
        t.Price,
		tuv.TradeUp_Value,
		tuv.PartnerID,
        Coalesce(Cancelled.Cancelled,0) Cancelled
into	#Redemptions        
from  Relational.Customer c
inner join SLC_Report.dbo.Trans t on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r on r.id = t.ItemID
LEFT Outer JOIN #Cancelled as Cancelled ON Cancelled.TransID=T.ID
inner join SLC_Report.dbo.RedeemAction ra on t.ID = ra.transid and ra.Status in (1,6)
left outer join relational.RedemptionItem as ri on t.ItemID = ri.RedeemID
left outer join relational.RedemptionItem_TradeUpValue as tuv
	on ri.RedeemID = tuv.RedeemID    
Where t.TypeID=3
		AND T.Points > 0
Group by t.FanID,c.CompositeID,t.id,ri.RedeemType,r.[Description],t.Price,tuv.TradeUp_Value, Coalesce(Cancelled.Cancelled,0),tuv.PartnerID
order by TranID

---------------------------------------------------------------------------------------------------------
--------------------Create the redemption description from the Private Description-----------------------
---------------------------------------------------------------------------------------------------------
/*The description provided need some changing to make them more accurately represent that which they are supposed to, such as:

		* Remove the amount off the donation option chosen as this doesn't always match the amount given
		* fix fix how '£' and '&' symbols are displayed
		* Remove formatting reference for the name CashbackPlus
*/
Truncate Table Staging.Redemptions

Insert Into Staging.Redemptions
Select	FanID,
	CompositeID,
	TranID,
	RedeemDate,
	RedeemType,
	replace(replace(replace(replace(
	Case
		When left(Ltrim(rtrim(PrivateDescription)),3) = '£5 ' and RedeemType = 'Charity' 
					then 'D'+ right(ltrim(rtrim(PrivateDescription)),len(ltrim(rtrim(PrivateDescription)))-4)
		When left(Ltrim(PrivateDescription),3) Like '£_0' and RedeemType = 'Charity' 
					then 'D'+right(ltrim(PrivateDescription),len(ltrim(PrivateDescription))-5)
		Else Ltrim(PrivateDescription)
	End, '&pound;','£'),'{em}',''),'{/em}',''),'B&amp;Q','B&Q')
	RedemptionDescription,
	a.PartnerID,
	Coalesce(p.PartnerName,'N/A') as PartnerName,
	Price as CashbackUsed,
	Case
		when TradeUp_Value > 0 then 1
		Else 0
	End as TradeUp_WithValue,
	TradeUp_Value,
	Cancelled
from #Redemptions as a
left Outer join relational.partner as p
	on a.partnerid = p.partnerid
order by redeemtype


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11' and
		TableSchemaName = 'Staging' and
		TableName = 'Redemptions' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.Redemptions)
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11' and
		TableSchemaName = 'Staging' and
		TableName = 'Redemptions' and
		TableRowCount is null
		
		
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11',
		TableSchemaName = 'Relational',
		TableName = 'Redemptions',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'		
		
---------------------------------------------------------------------------------------------------------
----------------------Create Relational.Redemptions from Staging.Redemptions-----------------------------
---------------------------------------------------------------------------------------------------------
ALTER INDEX IDX_FanID ON Relational.Redemptions DISABLE

Truncate Table Relational.Redemptions

Insert Into Relational.Redemptions
Select *
From Staging.Redemptions


ALTER INDEX IDX_FanID ON Relational.Redemptions REBUILD
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11' and
		TableSchemaName = 'Relational' and
		TableName = 'Redemptions' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Redemptions)
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_11' and
		TableSchemaName = 'Relational' and
		TableName = 'Redemptions' and
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

END