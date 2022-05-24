/*
			Author:			Stuart Barnley

			Date:			22-06-2015

			Purpose:		This stored proicedure enables you to import codes for
							Caffé Nero Birthday Muffins.

							Before Running the tables must be imported and checked to
							make sure a fields called [Voucher Code] is present.

							When calling the Stored Procedure the table names should 
							be listed out in full. Currently this allows for up to 
							5 tables.

*/
CREATE Procedure  Staging.CaffeNero_BirthdayCodes_Import (
					@TableName1 nvarchar(200),
					@TableName2 nvarchar(200),
					@TableName3 nvarchar(200),
					@TableName4 nvarchar(200),
					@TableName5 nvarchar(200)
					)
As

Declare @BatchID int, -- This field is used to hold the latest batch number
		@Qry nvarchar(max) -- This field is used to hold code that will be eventually executed
		
----------------------------------------------------------------------------------
---------------------------------Create New BatchID-------------------------------
----------------------------------------------------------------------------------
--Create a new entry in the table dated today to be linked to this latest supply of codes
Insert into [Relational].[RedemptionCodeBatch]
	Select	Cast(getdate() as date) as BatchDate,
			CodeTypeID = 1
----------------------------------------------------------------------------------
-------------------------------Find Last Batch Number-----------------------------
----------------------------------------------------------------------------------
--Find out the number of the latest batch entry that was created
Set @BatchID = (Select MAX(BatchID) From [Relational].[RedemptionCodeBatch])
----------------------------------------------------------------------------------
-------------------------------Insert Voucher Codes to new Table------------------
----------------------------------------------------------------------------------
/*This creates a piece of code pulling voucher codes from 1 or more of five tables and
  imports them into the Table Warehouse.Relational.RedemptionCode*/

Set @Qry = '
Insert into Warehouse.Relational.RedemptionCode
Select	[Voucher Code] as Code,
		Cast(NULL as Int) as FanID,
		'+Cast(@BatchID as Varchar(3))+ ' as BatchID,
		CAST(NULL as Int) as MembersAssignedBatch
From
(Select * from '+@TableName1+'
'+Case When Len(@TableName2) > 10 then 'Union All Select * from '+@TableName2 Else '' End+'
'+Case When Len(@TableName3) > 10 then 'Union All Select * from '+@TableName3 Else '' End+'
'+Case When Len(@TableName4) > 10 then 'Union All Select * from '+@TableName4 Else ''End+'
'+Case When Len(@TableName5) > 10 then 'Union All Select * from '+@TableName5 Else ''End+'
) as a'
--Run the code created to actuallly import the codes
Exec SP_ExecuteSQL @Qry
----------------------------------------------------------------------------------
----------------------------------Counts per Batch--------------------------------
----------------------------------------------------------------------------------
/*This produces some stats to help to demonstrate if the data was imported as 
  expected*/

Select	RCB.BatchID,
		RCT.Description,
		RCT.PartnerID,
		RCB.BatchDate,
		Count(*) as Codes
from [Relational].[RedemptionCodeBatch] as RCB
left outer join Warehouse.Relational.RedemptionCode as RC
	on RCB.BatchID = RC.BatchID
inner join [Relational].[RedemptionCodeType] as rct
	on RCB.CodeTypeID = rct.CodeTypeID
Group By RCB.BatchID,RCT.Description,RCT.PartnerID,RCB.BatchDate
Order by RCB.BatchDate,RCB.BatchID