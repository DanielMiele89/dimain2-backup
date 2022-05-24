CREATE Procedure [Staging].[SSRS_R0075_PrelaunchCheck_MIDsAlreadyInGas] 
			@TableName varchar(250),
			@MID_Name varchar(20)
as

-----------------------------------------------------------------------------------------------
----------------------------Create a table to put MIDs list in---------------------------------
-----------------------------------------------------------------------------------------------

if object_id('Staging.MIDs_TempTable') is not null drop table Staging.MIDs_TempTable
Create Table Staging.MIDs_TempTable (
				MerchantID varchar(60),
				Original bit,
				RowNo int,
				Primary Key (MerchantID))

-----------------------------------------------------------------------------------------------
-----------------------Populate with list of MIDs supplied by Merchant-------------------------
-----------------------------------------------------------------------------------------------
Declare	@Qry nvarchar(max)

--Set @TableName = 'Sandbox.[Stuart].[LauraAshleyMIDs_20150527]'
--Set @Mid_Name = 'MIDs'
Set @Qry = '
Insert into Staging.MIDs_TempTable
Select Cast(Cast('+@MID_Name+' as bigint) as varchar(50)) as MerchantID,
		1 as Original,
		ROW_NUMBER() OVER(ORDER BY '+@MID_Name+' DESC) AS RowNo
from '+@TableName+'
Where Len('+@MID_Name+') > 3'

Exec sp_executeSQL @Qry

--Select [MerchantID] from [Staging].[MIDs_TempTable] 
Update [Staging].[MIDs_TempTable] 
Set MerchantID = Replace(MerchantID,' ','')
-----------------------------------------------------------------------------------------------
---------Populate with list of preceding/non preceding zero MIDs supplied by Merchant----------
-----------------------------------------------------------------------------------------------

Insert into Staging.MIDs_TempTable
Select Case
			When Left(a.MerchantID,1) = '0' then Right(a.MerchantID,(Len(a.MerchantID)-1))
			Else '0'+a.MerchantID
	   End as MID,
	   0 as Original,
	   RowNo
from Staging.MIDs_TempTable as a

-----------------------------------------------------------------------------------------------
---------------------------Check if any of these MIDs are in GAS already-----------------------
-----------------------------------------------------------------------------------------------

Select	'Address Already in Gas' as [Assessment Type],
		ro.ID as OutletID,
		ro.MerchantID,
		f.Address1,
		f.Address2,
		f.City,
		f.Postcode,
		p.ID as PartnerID,
		p.Name as PartnerName
from Staging.MIDs_TempTable as a
inner join slc_report.dbo.RetailOutlet as ro
	on a.MerchantID = ro.MerchantID
inner join slc_report..Fan as f
	on ro.fanid = f.id
inner join SLC_Report..[Partner] as p
	on ro.Partnerid = p.id

-------------------------------------------------------------------------------------------------
-----------------------------Check if any of these MIDs are in GAS already-----------------------
-------------------------------------------------------------------------------------------------
--if object_id('tempdb..#CCIDs') is not null drop table #CCIDs
--Select	o.MerchantID,
--		cc.Narrative,
--		cc.ConsumerCombinationID,
--		b.BrandID,
--		b.BrandName
--into #CCIDs
--from Staging.MIDs_TempTable as o
--inner join Relational.ConsumerCombination as cc
--	on o.MerchantID = cc.MID
--inner join Relational.Brand as b
--	on cc.BrandID = b.BrandID
--Where Replace(LocationCountry,' ','') = 'GB'

--Create Clustered Index #CCIDs_CCID on #CCIDs (ConsumerCombinationID)

--if object_id('tempdb..#Trans') is not null drop table #Trans
--Select cc.ConsumerCombinationID,Min(TranDate) as ,Max(TranDate),Count(*)
--Into #Trans
--From Relational.ConsumerTransaction as ct
--inner join #CCIDs as cc
--	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
----Where ct.TranDate >= dateadd(month,3,Cast(getdate() as date))
--group By cc.ConsumerCombinationID