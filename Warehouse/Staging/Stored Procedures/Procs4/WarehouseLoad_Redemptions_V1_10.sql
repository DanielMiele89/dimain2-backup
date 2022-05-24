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
*/

Create PROCEDURE [Staging].[WarehouseLoad_Redemptions_V1_10]
AS
BEGIN


/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10',
		TableSchemaName = 'Staging',
		TableName = 'Redemptions',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'


---------------------------------------------------------------------------------------------------------
--------------------Pull out a list of redemptions including those later cancelled-----------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Redemptions') is not null drop table #Redemptions
select	t.FanID,
		c.CompositeID,--c.LaunchGroup,
		t.id as TranID,
        Min(t.Date) as RedeemDate,
        ri.RedeemType,
        r.Description as PrivateDescription,
        t.Price,
		tuv.TradeUp_Value,
        case when Cancelled.TransID is null then 0 else 1 end Cancelled
into	#Redemptions        
from  Relational.Customer c
inner join SLC_Report.dbo.Trans t on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r on r.id = t.ItemID
LEFT Outer JOIN (select ItemID as TransID from SLC_Report.dbo.trans t2 where t2.typeid=4) as Cancelled ON Cancelled.TransID=T.ID
inner join SLC_Report.dbo.RedeemAction ra on t.ID = ra.transid and ra.Status in (1,6)
left outer join relational.RedemptionItem as ri on t.ItemID = ri.RedeemID
left outer join relational.RedemptionItem_TradeUpValue as tuv
	on ri.RedeemID = tuv.RedeemID    
where --f.ClubID = 132 and 
	t.TypeID=3
	AND T.Points > 0
Group by t.FanID,c.CompositeID,t.id,ri.RedeemType,r.[Description],t.Price,tuv.TradeUp_Value,case when Cancelled.TransID is null then 0 else 1 end
order by TranID

---------------------------------------------------------------------------------------------------------
--------------------Create the redemption description from the Private Description-----------------------
---------------------------------------------------------------------------------------------------------
/*The description provided need some changing to make them more accurately represent that which they are supposed to, such as:

		* Remove the amount off the donation option chosen as this doesn't always match the amount given
		* fix fix how '£' and '&' symbols are displayed
		* Remove formatting reference for the name CashbackPlus
*/
if object_id('tempdb..#Redemptions_renamed') is not null drop table #Redemptions_renamed
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
	Price as CashbackUsed,
	TradeUp_Value,
	Cancelled,
	PrivateDescription
Into #Redemptions_renamed
from #Redemptions
order by redeemtype
---------------------------------------------------------------------------------------------------------
--------Link Trade Ups to Partners and add Trade Value if known - Create Staging.Redemptions-------------
---------------------------------------------------------------------------------------------------------
/*Trade-Ups relate to benefits at a particular partner therefore we are linking them through an assessment 
  of freetext, the same can be said for the value they are trading up for.
*/
Truncate Table Staging.Redemptions
Insert Into Staging.Redemptions
Select	r.FanID,
		r.CompositeID,
		TranID,
		RedeemDate,
		RedeemType,
		RedemptionDescription,
		Case
			When RedeemType = 'Trade Up' and RedemptionDescription like '%digital magazines for %Rewards%' then 1000000
			When RedeemType = 'Trade Up' and 
				 replace(replace(RedemptionDescription,' ',''),'&','') like '%CurrysPCWorld%' then 4001
			When RedemptionDescription like '%Caff_ Nero%' then 4319
			When RedeemType = 'Trade Up' Then P.PartnerID
			Else NULL
		End as PartnerID,
		Case
			When RedeemType = 'Trade Up' and RedemptionDescription like '%digital magazines for %Rewards%' then 'Zinio'
			When RedeemType = 'Trade Up' and 
				 replace(replace(RedemptionDescription,' ',''),'&','') like '%CurrysPCWorld%' then 'Currys & PC World'
			When RedemptionDescription like '%Caff_ Nero%' then 'Caffe Nero'
			When RedeemType = 'Trade Up' Then PartnerName
			Else 'N/A'
		End as PartnerName,
		CashbackUsed,
		Case
			When RedeemType ='Trade Up' and 
				 RedemptionDescription like '£[0-9]%gift card for £%' then 1
			When RedeemType ='Trade Up' and 
				 TradeUp_Value > 0 then 1
			Else 0
		End as TradeUp_WithValue,
		Case
			When TradeUp_Value > 0 then TradeUp_Value
			When RedeemType ='Trade Up' and Left(RedemptionDescription,5) like '£[0-9][0-9][0-9][0-9]' 
							  then cast (RIGHT(Left(RedemptionDescription,5),4) as smallmoney)
			When RedeemType ='Trade Up' and Left(RedemptionDescription,4) like '£[0-9][0-9][0-9]' 
							  then cast (RIGHT(Left(RedemptionDescription,4),3) as smallmoney)
			When RedeemType ='Trade Up' and Left(RedemptionDescription,3) like '£[0-9][0-9]' 
							  then cast (RIGHT(Left(RedemptionDescription,3),2) as smallmoney)
			When RedeemType ='Trade Up' and Left(RedemptionDescription,2) like '£[0-9]' 
							  then cast (RIGHT(Left(RedemptionDescription,2),1) as smallmoney)
			Else null
		End as TradeUp_Value,
		Cancelled
from #Redemptions_renamed as r
left Outer join relational.Partner as p
	on	r.redemptiondescription like '%'+p.partnername+'%' and
		r.RedemptionDescription not like '%Currys%' and
		r.RedemptionDescription not like '%PC World%'


	Update Staging.Redemptions
	Set PartnerID = ri.PartnerID, PartnerName = ri.PartnerName
	from Staging.Redemptions as r
	inner join slc_report.dbo.trans as t with (nolock)
		on r.TranID = t.id
	inner join Staging.RedemptionItem as ri
		on t.itemid = ri.RedeemID
	Where r.RedeemType = 'Trade Up' and r.PartnerID is null
			
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10' and
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
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10' and
		TableSchemaName = 'Staging' and
		TableName = 'Redemptions' and
		TableRowCount is null
		
		
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10',
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
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10' and
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
where	StoredProcedureName = 'WarehouseLoad_Redemptions_V1_10' and
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