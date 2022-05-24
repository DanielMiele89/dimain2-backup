CREATE Procedure [Staging].[OPE_06_Assign_Slots_NonWow_V1_1_TEST]
as
/*--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------*/
Declare	@RowNo int, 
		@MaxRow int,
		@IronOfferID int,
		@HTMID int,
		@PartnerID int,
		@FanID int,
		@ChunkSize int
		
Set @RowNo = 1
Set @ChunkSize = 2500
-----------------------------------------------------------------------------------------
--------------------------------Create Customer Table------------------------------------*******-Limited for Testing
-----------------------------------------------------------------------------------------
if object_id('tempdb..#Customer') is not null drop table #Customer
Select c.FanID,
				c.CompositeID,
				coalesce(MAX(m.FinalSlot),0) as UsedSlots,
				ROW_NUMBER() OVER(ORDER BY c.FanID Asc) AS RowNumber
Into #Customer
From Relational.Customer as c
Left Outer join Staging.OPE_Members as m
	on c.FanID = m.FanID and m.Status = 1
Where MarketableByEmail = 1
Group by c.FanID,c.CompositeID
Order by FanID
-----------------------------------------------------------------------------------------
--------------------------------Create list of above base offers ------------------------
-----------------------------------------------------------------------------------------
Declare @CL Int

Set @CL = 
(Select Weighting
from Staging.OPE_Concept as c
inner join Staging.OPE_Weighting as w
	on c.ConceptID = w.ConceptID
Where w.ConceptID = 9 and w.ConceptLevelID = 2
)
Select @CL
-----------------------------------------------------------------------------------------
--------------------------------Create list of above base offers ------------------------
-----------------------------------------------------------------------------------------
if object_id('tempdb..#Offers_AB') is not null drop table #Offers_AB
Select	a.*,
		ROW_NUMBER() OVER(ORDER BY TotalScore DESC) AS BaseRowNo
Into #Offers_AB
from 
(Select	Distinct 
		w.*,
		Case
			When sow.PartnerID is not null then 1
			Else 0
		End SOW
From Staging.OPE_Offers_Weighted as w
left outer join Relational.IronOffer_Campaign_HTM as a
	on w.IronOfferID = a.IronOfferID
left outer join Staging.IronOffer_Campaign_Type as ct
	on a.ClientServicesRef = ct.ClientServicesRef
Left Outer join Staging.OPE_SOWRunDate as sow
	on w.PartnerID = SOW.PartnerID
Where BaseOffer = 1
) as a		

--Select * from #Offers_AB
	
----------------------------------------------------------------------------------------
--------------------------------Import Members of all offers-----------------------------
-----------------------------------------------------------------------------------------
Set @MaxRow = (Select MAX(RowNumber) from #Customer)

if object_id('tempdb..#Members') is not null drop table #Members
Create Table #Members			(	ID int identity (1,1), 
									FanID int, 
									IronOfferID int, 
									HTMID int, 
									TotalScore int,
									IOM bit,
									Slot int)

if object_id('tempdb..#MemberPartners') is not null drop table #MemberPartners
Create Table #MemberPartners	(	FanID int, 
									PartnerID int)



While @RowNo <= @MaxRow
Begin
	Insert into #MemberPartners
	Select	c.FanID,
			i.PartnerID
	From #Customer as c
	inner join Staging.ope_Members as m
		on c.FanID = m.FanID
	inner join Relational.IronOffer as i
		on m.IronOfferID = i.IronOfferID
	Where c.RowNumber >= @RowNo and  
				c.RowNumber < @RowNo+@ChunkSize
	
	Insert into Staging.OPE_Members
	Select	FanID,
			IronOfferID,
			HTMID,
			Slot as InitalSlot,
			Slot as CurrentSlot,
			Slot as FinalSlot,
			IOM,
			1 as [Status]--,
			--TotalScore,
			--Exposure,
			--Overall
	from
	   (Select	Distinct
				c.FanID,
				iom.IronOfferID,
				coalesce(SOW.HTMID,0) as HTMID,
				w.TotalScore,
				coalesce(cp.Score,100)*@CL as Exposure,
				w.TotalScore+(coalesce(cp.Score,100)*@CL) as Overall,
				1 as IOM,
				ROW_NUMBER() OVER(PARTITION BY c.FanID ORDER BY w.TotalScore+(coalesce(cp.Score,100)*@CL) DESC)+c.UsedSlots AS Slot
		From [Relational].[OPE_IronOfferMember_TEST] as IOM
		inner join #Customer as c
			on iom.CompositeID = c.CompositeID
		inner join #Offers_AB as W
			on iom.IronOfferID = W.IronOfferID
		Left Outer join Relational.ShareOfWallet_Members as sow
			on	c.FanID = sow.FanID and
				sow.PartnerID = w.PartnerID and
				sow.HTMID = w.HTMID and
				sow.EndDate is NULL
		left Outer join #MemberPartners as mp
			on  c.FanID = mp.FanID and
				mp.PartnerID = w.PartnerID
		Left Outer Join Staging.OPE_Customer_Customer_Partner_Exposure as cp
			on	c.FanID = cp.FanID and
				w.PartnerID = cp.PartnerID-- and
				--@CL = 1
		Where	--c.FanID = 1986602 and
				c.RowNumber >= @RowNo and  -->= 1 and
				c.RowNumber < @RowNo+@ChunkSize and --< 100 and
				((sow.HTMID is not null and w.SOW = 1)  or 
					(w.SOW = 0 and w.HTMID = 0)
				) and
				mp.PartnerID is null
	   ) as a	
	Where Slot <= 7
	Order by FanID,FinalSlot
		Set @RowNo = @RowNo +@ChunkSize
End

--Select * from #Members Order by FanID,Slot

--select * from Staging.OPE_Members
--Where FanID = 1986602
--Order by FinalSlot

--Select slots,COUNT(*) from 
--(Select FanID,COUNT(*) as slots from Staging.OPE_Members
--Where Status = 1
--Group by FanID
--	having COUNT(*) < 7
--) as a
--Group by Slots

--select * from #Customer
--Where FanID = 1986602

--select * from #Customer as c
--Left Outer join #members as m
--	on	c.FanID = m.FanID and
--		c.UsedSlots = m.Slot-1
--Where	c.UsedSlots < 7 and
--		m.FanID is null