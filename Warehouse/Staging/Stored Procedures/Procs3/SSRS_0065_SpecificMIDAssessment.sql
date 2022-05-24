/*
		Author:			Stuart Barnley
		Date:			18-03-2015

		Purpose:		To assess one MID and return occurances on ConsumerTransactions

*/

CREATE Procedure Staging.SSRS_0065_SpecificMIDAssessment
					@MID varchar(25)
As
--Declare @MID varchar(25)

Declare @Qry nvarchar, @MIDWithout varchar(25)
-----------------------------------------------------------------------------------------------
-------------------------Convert MID to remove preceeding Zeroes-------------------------------
-----------------------------------------------------------------------------------------------
--Set @MID = '00000001080115'
Set @MIDWithout =	Case
						When Left(@MID,2) = '00' then Cast(Cast(@MID as Int) as varchar(25))
						When Left(@MID,1) = '0' then Right(@MID,Len(@MID)-1)
						Else @MID
					End
--Select Len(@MID),@MIDWithout
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
Where Right(replace(mid,' ',''),len(@MIDWithout)) = @MIDWithout

Create Clustered Index IDX_CCs_CCID on #CCs (ConsumerCombinationID)
--------------------------------------------------------------------------------
-------------------------Return Transactional Data------------------------------
--------------------------------------------------------------------------------

Select	cc.ConsumerCombinationID,
		cc.MID,
		cc.Narrative,
		cc.LocationCountry,
		cc.MCC,
		cc.MCCDesc,
		cc.BrandID,
		cc.BrandName,
		Min(Trandate) as FirstTrans,
		Max(Trandate) as LastTrans,
		Count(*) as TranCount
Into #TranInfo
from #CCs as cc
Left join warehouse.relational.ConsumerTransaction as ct
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
Group By cc.ConsumerCombinationID,cc.MID,cc.Narrative,cc.LocationCountry,cc.MCC,cc.MCCDesc,cc.BrandID,cc.BrandName
--------------------------------------------------------------------------------
-----------------------------------Output---------------------------------------
--------------------------------------------------------------------------------
Select *
From #TranInfo