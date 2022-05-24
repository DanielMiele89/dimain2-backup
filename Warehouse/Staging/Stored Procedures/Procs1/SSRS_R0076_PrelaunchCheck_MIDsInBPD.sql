CREATE Procedure [Staging].[SSRS_R0076_PrelaunchCheck_MIDsInBPD] 
			@TableName varchar(250),
			@MID_Name varchar(20)
as

-----------------------------------------------------------------------------------------------
----------------------------Create a table to put MIDs list in---------------------------------
-----------------------------------------------------------------------------------------------

if object_id('Staging.MIDs_TempTable') is not null drop table Staging.MIDs_TempTable
Create Table Staging.MIDs_TempTable (
				MerchantID varchar(50),
				Original bit,
				RowNo int,
				--Primary Key (MerchantID)
				)

-----------------------------------------------------------------------------------------------
-----------------------Populate with list of MIDs supplied by Merchant-------------------------
-----------------------------------------------------------------------------------------------
Declare	@Qry nvarchar(max)

--Set @TableName = 'Sandbox.[Stuart].[LauraAshleyMIDs_20150527]'
--Set @Mid_Name = 'MIDs'
Set @Qry = '
Insert into Staging.MIDs_TempTable
Select Cast(Cast('+@MID_Name +' as bigint) as varchar(50)) as MerchantID,
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

-------------------------------------------------------------------------------------------------
-----------------------------Check if any of these MIDs are in GAS already-----------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#CCIDs') is not null drop table #CCIDs
Select	o2.MerchantID as OriginalMID,
		o.MerchantID,
		cc.Narrative,
		cc.ConsumerCombinationID,
		b.BrandID,
		b.BrandName,
		Replace(LocationCountry,' ','') as LocationCountry
into #CCIDs
from Staging.MIDs_TempTable as o
inner join Relational.ConsumerCombination as cc (NOLOCK)
	on o.MerchantID = cc.MID
inner join Relational.Brand as b
	on cc.BrandID = b.BrandID
inner join Staging.MIDs_TempTable as o2
	on	o.RowNo = o2.RowNo and
		o2.Original = 1
Where Replace(LocationCountry,' ','') = 'GB'
--Select * from #CCIDs
Create Clustered Index #CCIDs_CCID on #CCIDs (ConsumerCombinationID)
-------------------------------------------------------------------------------------------------
-----------------------------Find any Trans in ConsumerTransaction-------------------------------
-------------------------------------------------------------------------------------------------

if object_id('tempdb..#Trans') is not null drop table #Trans

Select *
Into #Trans
From 
(
Select	cc.ConsumerCombinationID,
		Min(TranDate) as FirstTran,
		Max(TranDate) LastTran,
		Sum(Case
				When TranDate is null then 0
				Else 1
			End) as Trans,
		Max(Case
				When ct.CardholderPresentData = 5 then 1
				Else 0
			End) as [Online],
		Max(Case
				When ct.CardholderPresentData <> 5 then 1
				Else 0
			End) as [Offline]
From #CCIDs as cc
left Outer join Relational.ConsumerTransaction as ct (NOLOCK)
	on	ct.ConsumerCombinationID = cc.ConsumerCombinationID --and
	--	ct.TranDate >= dateadd(month,-12,Cast(getdate() as date))
group By cc.ConsumerCombinationID
Union All
Select	cc.ConsumerCombinationID,
		Min(TranDate) as FirstTran,
		Max(TranDate) LastTran,
		Sum(Case
				When TranDate is null then 0
				Else 1
			End) as Trans,
		Max(Case
				When ct.CardholderPresentData = 5 then 1
				Else 0
			End) as [Online],
		Max(Case
				When ct.CardholderPresentData <> 5 then 1
				Else 0
			End) as [Offline]
From #CCIDs as cc
left Outer join Relational.ConsumerTransactionHolding as ct (NOLOCK)
	on	ct.ConsumerCombinationID = cc.ConsumerCombinationID --and
		--ct.TranDate >= dateadd(month,-12,Cast(getdate() as date))

group By cc.ConsumerCombinationID
) as a

--Select * from #Trans
select	c.OriginalMID,
		MerchantID,
		Narrative,--c.ConsumerCombinationID,
		BrandName,
		LocationCountry,
		Min(t.FirstTran) as FirstTran,
		Max(t.LastTran) as LastTran,
		Sum(Trans) as Trans,
		Max(Case
				When [Online] = 1 then 1
				Else 0
			End) as [Online],
		Max(Case
				When [Offline] = 1 then 1
				Else 0
			End) as [Offline]
from #CCIDs as c
left outer join #Trans as t
	on c.ConsumerCombinationID = t.ConsumerCombinationID
Group By c.OriginalMID,MerchantID,
		Narrative,--c.ConsumerCombinationID,
		BrandName,
		LocationCountry
Order by c.OriginalMID,MerchantID,Max(t.LastTran) Desc