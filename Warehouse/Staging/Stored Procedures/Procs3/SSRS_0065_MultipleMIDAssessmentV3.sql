/*
		Author:			Stuart Barnley
		Date:			18-03-2015

		Purpose:		To assess one MID and return occurances on ConsumerTransactions

*/

CREATE Procedure [Staging].[SSRS_0065_MultipleMIDAssessmentV3]
					@MID varchar(150)
As
--------------------------------------------------------------------------------
---------------------------------Create table of MIDs---------------------------
--------------------------------------------------------------------------------
Declare @MIDList varchar(150)

Set @MIDList = @MID


Create Table #MID (MID varchar(20))

--Select CHARINDEX(',',@String)
While @MIDList like '%,%'
Begin
	Insert into #MID
	Select  SUBSTRING(@MIDList,1,CHARINDEX(',',@MIDList)-1)
	Set @MIDList = (Select  SUBSTRING(@MIDList,CHARINDEX(',',@MIDList)+1,Len(@MIDList)))
End
	Insert into #MID
	Select @MIDList
--------------------------------------------------------------------------------
-------------------Find a list of Consumer Combination IDs----------------------
--------------------------------------------------------------------------------
select	cc.ConsumerCombinationID,
		cc.MID,
		cc.Narrative,
		cc.LocationCountry,
		mcc.MCC,
		mcc.MCCDesc,
		b.BrandID,
		b.BrandName
Into #CCs
from warehouse.relational.ConsumerCombination as cc
inner join warehouse.relational.MCCList as mcc
	on cc.MCCID = mcc.MCCID
inner join Warehouse.relational.Brand as b
	on cc.BrandID = b.BrandID
inner join #MID as m
	on Right(replace(cc.mid,' ',''),Len(m.MID)) = m.MID
--Where Right(replace(mid,' ',''),8) in (Select MID from #MID)



Create Clustered Index IDX_CCs_CCID on #CCs (ConsumerCombinationID)
--------------------------------------------------------------------------------
-------------------------Return Transactional Data------------------------------
--------------------------------------------------------------------------------
Select	MID,
		Narrative,
		LocationCountry,
		MCC,
		MCCDesc,
		BrandID,
		BrandName,
		Min(FirstTrans) as FirstTrans,
		Max(LastTrans) as LastTrans,
		Sum(TranCount_Total) as TranCount_Total,
		Sum([TranCount_Online]) as [TranCount_Online],
		Sum([TranCount_Offline]) as [TranCount_Offline],
		SUM(TranAmount_Total) as TranAmount_Total,
		SUM(TranAmount_Online) as TranAmount_Online,
		SUM(TranAmount_Offline) as TranAmount_Offline
Into #TranInfo
From (
Select	--cc.ConsumerCombinationID,
		cc.MID,
		cc.Narrative,
		cc.LocationCountry,
		cc.MCC,
		cc.MCCDesc,
		cc.BrandID,
		cc.BrandName,
		Min(Trandate) as FirstTrans,
		Max(Trandate) as LastTrans,
		Sum(Case
				When ct.ConsumerCombinationID is null then 0
				Else 1
			End) as TranCount_Total,
		Sum(Case
				When ct.CardholderPresentData = 5 then 1
				Else 0
			End ) as [TranCount_Online],
		Sum(Case
				When ct.CardholderPresentData <> 5 and ct.CardholderPresentData is not null then 1
				Else 0
			End ) as [TranCount_Offline]
		, Sum(Amount) as TranAmount_Total,
		Sum(Case
				When ct.CardholderPresentData = 5 then Amount
				Else 0
			End ) as [TranAmount_Online],
		Sum(Case
				When ct.CardholderPresentData <> 5 and ct.CardholderPresentData is not null then Amount
				Else 0
			End ) as [TranAmount_Offline]
from #CCs as cc
Left join warehouse.relational.ConsumerTransaction as ct
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
Group By --cc.ConsumerCombinationID,
			cc.MID,cc.Narrative,cc.LocationCountry,cc.MCC,cc.MCCDesc,cc.BrandID,cc.BrandName
Union All
Select	--cc.ConsumerCombinationID,
		cc.MID,
		cc.Narrative,
		cc.LocationCountry,
		cc.MCC,
		cc.MCCDesc,
		cc.BrandID,
		cc.BrandName,
		Min(Trandate) as FirstTrans,
		Max(Trandate) as LastTrans,
		Sum(Case
				When ct.ConsumerCombinationID is null then 0
				Else 1
			End) as TranCount_Total,
		Sum(Case
				When ct.CardholderPresentData = 5 then 1
				Else 0
			End ) as [TranCount_Online],
		Sum(Case
				When ct.CardholderPresentData <> 5 and ct.CardholderPresentData is not null then 1
				Else 0
			End ) as [TranCount_Offline]
		, Sum(Amount) as TranAmount_Total,
		Sum(Case
				When ct.CardholderPresentData = 5 then Amount
				Else 0
			End ) as [TranAmount_Online],
		Sum(Case
				When ct.CardholderPresentData <> 5 and ct.CardholderPresentData is not null then Amount
				Else 0
			End ) as [TranAmount_Offline]
from #CCs as cc
Left join warehouse.relational.ConsumerTransactionHolding as ct
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
Group By --cc.ConsumerCombinationID,
			cc.MID,cc.Narrative,cc.LocationCountry,cc.MCC,cc.MCCDesc,cc.BrandID,cc.BrandName
) as a
Group by MID,Narrative,	LocationCountry,MCC,MCCDesc,BrandID,BrandName

--------------------------------------------------------------------------------
-----------------------------------Output---------------------------------------
--------------------------------------------------------------------------------
Select *
From #TranInfo
Order by MID