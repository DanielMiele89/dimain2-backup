/*
	
	Author:		Stuart Barnley

	Date:		23rd September 2016

	Purpose:	Generate Sample Data for upload into SFD for a specific ClubID and LionSendID
	

*/

CREATE Procedure [Staging].[SSRS_R0132_LionSendComponent_Samples_V2] (@LionSendID int,@ClubID int)
As
------------------------------------------------------------------------------------
---------------------Create a distinct List of Offers in the email------------------
------------------------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers

Select	ItemID,
		0 as [Sample],
		ROW_NUMBER() OVER(ORDER BY ItemID DESC) AS RowNo
Into #Offers
From
	(	select Distinct ItemID
		From warehouse.[Lion].[NominatedLionSendComponent]
	) as a

------------------------------------------------------------------------------------
----------------------Find audience who opened the last email-----------------------
------------------------------------------------------------------------------------
																									--Set @LastEmailDate = (	Select Max([EmailSendDate])
																									--						from Warehouse.[Relational].[Customers_ReducedFrequency_Weeks]
																									--						Where [EmailSendDate] < GetDate()
																									--					 )

Declare @LastEmailDate date

Set @LastEmailDate = (	Select Max(SendDate)
						from Warehouse.Relational.EmailCampaign
						Where CampaignName like '%newsletter%'
					 )

------------------------------------------------------------------------------------
----------------------Find audience who opened the last email-----------------------
------------------------------------------------------------------------------------
if object_id('tempdb..#Opens') is not null drop table #Opens
Select Distinct FanID
Into #Opens
From Relational.EmailEvent as ee
Inner join Warehouse.Relational.EmailCampaign ec
	on ee.CampaignKey=ec.CampaignKey
Where ee.emaileventcodeID = 1301
and	  ee.eventdate >= @LastEmailDate
and	  ec.CampaignName like '%newsletter%'
and	  ec.SendDate=@LastEmailDate




------------------------------------------------------------------------------------
----------------------Find those who are active-----------------------
------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers
Select t.FanID
	 , c.CLubID
	 , c.CompositeID
into #Customers
From #Opens as t
inner join warehouse.relational.customer as c
	on t.fanid = c.fanid
Where	c.MarketableByEmail = 1
and		c.clubid = @ClubID

------------------------------------------------------------------------
--------------------Pull sample customers offer data--------------------
------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#OfferVsSlots') IS NOT NULL DROP TABLE #OfferVsSlots
Select top 250000
		 nlsc.ID
		,nlsc.LionSendID
		,nlsc.CompositeId
		,nlsc.TypeID
		,nlsc.ItemRank
		,nlsc.ItemID
		,nlsc.Date
into #OfferVsSlots
From warehouse.Lion.NominatedLionSendComponent as nlsc
inner join #Customers as c
	on nlsc.CompositeId = c.CompositeId
Where	c.ClubID		= @ClubID
and		nlsc.lionsendid = @LionSendID
Order by CompositeID

------------------------------------------------------------------------
---------------------Create tables for populating-----------------------
------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Cust') IS NOT NULL DROP TABLE #Cust
Create Table #Cust ( CompositeID bigint
					,slots int
					,Primary Key(CompositeID)
					)

IF OBJECT_ID('tempdb..#t1') IS NOT NULL DROP TABLE #t1
Create Table #t1 (	 CompositeID bigint
					,OfferID int
					,Primary Key(OfferID)
					)

Declare @More bit
Set @More = 1

While ( Select IsNull(Count(*),0)
		From #Offers
		Where [Sample] = 0
		) > 0
and		@More > 0

	Begin
			Truncate Table #Cust
			------------------------------------------------------------------------
			-------------------Find customers with the most offers------------------
			------------------------------------------------------------------------
			Insert Into #Cust
			Select Top 1 os.CompositeID
						,Count(*) as slots
			From #Offers as o
			inner join #OfferVsSlots as os
				on o.ItemID = os.ItemID
			Where [Sample] = 0
			Group by os.CompositeID
			Order by 2 Desc
			------------------------------------------------------------------------
			---------------Check if no more can be fulfilled by 100k----------------
			------------------------------------------------------------------------
	
			Set @More = (Select IsNULL(Count(*),0)
						 From #Cust)
	
			------------------------------------------------------------------------
			-----------------------------Insert Sample rows info--------------------
			------------------------------------------------------------------------
			--truncate table #t1
			Insert into #t1
			Select c.CompositeID
				 , o.ItemID as OfferID
			From #OfferVsSlots as os
			inner join #Cust as c
				on os.CompositeId = c.CompositeId
			inner join #Offers as o
				on os.ItemID = o.ItemID
			Where o.[Sample] = 0
			------------------------------------------------------------------------
			-----------------------------Update Offers table------------------------
			------------------------------------------------------------------------
			Update #Offers
			Set [Sample] = 1
			From #Offers as o
			inner join #t1 as t
				on o.ItemID = t.OfferID
			Where [Sample] = 0
	End
------------------------------------------------------------------------
---------------------Fill any missing offers----------------------------
------------------------------------------------------------------------
Insert into #t1
Select CompositeID
	 , ItemID 
From (
		Select n.CompositeID
			 , o.ItemID
			 , ROW_NUMBER() OVER(PARTITION BY o.ItemID ORDER BY n.CompositeID ASC) AS RowNo
		From #Offers as o
		inner join Lion.NominatedLionSendComponent as n
			on o.ItemID = n.ItemID
		inner join warehouse.relational.customer as c
			on n.CompositeId = c.CompositeID
		Where	LionSendID = @LionSendID
		and		[Sample] = 0
	) as a
Where RowNo <= 1

------------------------------------------------------------------------
---------------------Count samples per customer-------------------------
------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Order') IS NOT NULL DROP TABLE #Order
Select CompositeID
	 , [Rows]
	 , ROW_NUMBER() OVER(ORDER BY [Rows] DESC) AS RowNo
into #Order 
From (
Select CompositeID
	 , Count(*) as [rows]
From #t1
Group by CompositeID
) as a

------------------------------------------------------------------------
------------------------------Output Data ------------------------------
------------------------------------------------------------------------
Insert into Staging.R_0132_LionSendComponent_Sample
Select	Distinct
		  ClientServicesRef
		, i.IronOfferID
		, i.IronOfferName
		, i.TopCashBackRate
		, i.StartDate
		--, o.EndDate
		, t.CompositeID
		, c.Email
		, c.ClubID
		, o.RowNo
--into Staging.R_0132_LionSendComponent_Sample
from #t1 as t
inner join #Offers as o
	on t.OfferID = o.ItemID
inner join #Order as ord
	on t.CompositeID = ord.CompositeID
inner join warehouse.relational.Customer as c
	on t.CompositeID = c.CompositeID
inner join warehouse.relational.IronOffer as i
	on o.itemid = i.IronOfferID
Left Outer join warehouse.relational.IronOffer_Campaign_HTM as a
	on o.ItemID = a.IronOfferID
--Order by ord.[Rows] Desc,CompositeID Desc

--Select * from Staging.R_0126_SampleCustomers


--Select * from #Offers as o
--Left Outer join #t1 as t
--	on o.ItemID = t.OfferID
--Where Sample = 0 and t.CompositeID is null
