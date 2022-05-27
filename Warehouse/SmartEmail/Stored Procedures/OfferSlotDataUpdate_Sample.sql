/*

	Author:	Stuart Barnley

	Date:	26th October 2017

	Purpose:	Convert data from NominatedLionSendComponent to fit in the new 
				structure for SmartEmail (Sandbox.Stuart.[OfferSlotData])


*/
CREATE Procedure [SmartEmail].[OfferSlotDataUpdate_Sample] (@LSID int, @EmailDate date)
As

Declare @LionSendID int = @LSID, 
		@Date date = @EmailDate
		
--------------------------------------------------------------------------------------------
----------------------------Create a list of Customers (with RowNo)-------------------------
--------------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers
Select	a.CompositeID,
		c.FanID,
		c.ActivatedDate,
		ROW_NUMBER() OVER(ORDER BY a.CompositeID ASC) AS RowNo
Into #Customers
From (Select Distinct CompositeID
	 From Lion.NominatedLionSendComponent as n
	 Where LionSendID = @LionSendID
	 ) as a
inner join Relational.Customer as c
	on a.compositeid = c.compositeid

Create Clustered Index cix_Customers_CompositeID on #Customers (CompositeID)
Create NonClustered Index cix_Customers_RowNo on #Customers (RowNo)

--------------------------------------------------------------------------------------------
--------------------------Update Links (Real Customer to Sample) Table----------------------
--------------------------------------------------------------------------------------------
Truncate Table [SmartEmail].[SampleCustomerLinks] --** Delete previous Mapping

Insert into [SmartEmail].[SampleCustomerLinks] --** Insert new mapping
Select	RowNo as SampleCustomerID,
		FanID as RealCustomerFanID
From #Customers
Order by RowNo

	
	--------------------------------------------------------------------------------------------
	----------------------------------Get Customer with OfferIDs--------------------------------
	--------------------------------------------------------------------------------------------

	if object_id('tempdb..#Offers') is not null drop table #Offers
	Select	c.CompositeId,
			c.FanID,
			ActivatedDate,
			ItemID as IronOfferID,
			ItemRank as Slot
	Into	#Offers
	From #Customers as c
	inner join Lion.NominatedLionSendComponent as l
		on c.CompositeId = l.CompositeId
	Where LionSendID = @LionSendID

	Create Clustered index Offers_IronOfferID_CompositeID on #Offers (IronOfferID,CompositeID)

	--------------------------------------------------------------------------------------------
	--------------------------------------Get IOM Memberships-----------------------------------
	--------------------------------------------------------------------------------------------

	if object_id('tempdb..#OfferDates') is not null drop table #OfferDates
	--Insert into Sandbox.stuart.OfferDates
	Select	o.*,
			iom.StartDate as StartDate,
			iom.EndDate as EndDate
	Into #OfferDates
	From	#Offers as o
	inner join SLC_Report.dbo.IronOfferMember as iom
		on	o.CompositeId = iom.CompositeId and
			o.IronOfferID = iom.IronOfferID
	Where	(iom.StartDate <= @Date or iom.StartDate is null) and
			(iom.EndDate IS null or iom.EndDate > @Date)
	--Group by o.CompositeId,o.IronOfferID,o.Slot

	Create Clustered index cix_OD_CompositeID_IronOfferID on #OfferDates (CompositeID,IronOfferID)

	--------------------------------------------------------------------------------------------
	-----------------------Get OMA Memberships (for those missing)------------------------------
	--------------------------------------------------------------------------------------------

	Insert into #OfferDates
	Select	o.*,
			iom.StartDate as StartDate,
			iom.EndDate as EndDate
	From	#Offers as o
	inner join iRon.OfferMemberAddition as iom
		on	o.CompositeId = iom.CompositeId and
			o.IronOfferID = iom.IronOfferID
	Left Outer join #OfferDates as od
		on	o.CompositeId = od.CompositeId and
			o.IronOfferID = od.IronOfferID	
	Where	(iom.StartDate <= @Date or iom.StartDate is null) and
			(iom.EndDate IS null or iom.EndDate > @Date) and
			od.CompositeId is null

	Create NonClustered index #OfferDates_FanID on #OfferDates (FanID)

	--Select * From Sandbox.Stuart.[OfferSlotData]
	--------------------------------------------------------------------------------------------
	-------------------------------------Insert Data into Table---------------------------------
	--------------------------------------------------------------------------------------------

	Insert into Warehouse.SmartEmail.[OfferSlotData] -- Real Table
				
	Select	 c.[FanID]
			,@LionSendID as [LionSendID]
			,[Offer1]
			,[Offer2]
			,[Offer3]
			,[Offer4]
			,[Offer5]
			,[Offer6]
			,[Offer7]
			,Case
				When [Offer1StartDate] = '1900-01-01' then NULL
				Else [Offer1StartDate]
			 End as [Offer1StartDate]
			,Case
				When [Offer2StartDate] = '1900-01-01' then NULL
				Else [Offer2StartDate]
			 End as [Offer2StartDate]
			,Case
				When [Offer3StartDate] = '1900-01-01' then NULL
				Else [Offer3StartDate]
			 End as [Offer3StartDate]
			,Case
				When [Offer4StartDate] = '1900-01-01' then NULL
				Else [Offer4StartDate]
			 End as [Offer4StartDate]
			,Case
				When [Offer5StartDate] = '1900-01-01' then NULL
				Else [Offer5StartDate]
			 End as [Offer5StartDate]
			,Case
				When [Offer6StartDate] = '1900-01-01' then NULL
				Else [Offer6StartDate]
			 End as [Offer6StartDate]
			,Case
				When [Offer7StartDate] = '1900-01-01' then NULL
				Else [Offer7StartDate]
			 End as [Offer7StartDate]
			,Case
				When [Offer1EndDate] = '1900-01-01' then NULL
				Else [Offer1EndDate]
			 End as [Offer1EndDate]
			,Case
				When [Offer2EndDate] = '1900-01-01' then NULL
				Else [Offer2EndDate]
			 End as [Offer2EndDate]
			,Case
				When [Offer3EndDate] = '1900-01-01' then NULL
				Else [Offer3EndDate]
			 End as [Offer3EndDate]
			,Case
				When [Offer4EndDate] = '1900-01-01' then NULL
				Else [Offer4EndDate]
			 End as [Offer4EndDate]
			,Case
				When [Offer5EndDate] = '1900-01-01' then NULL
				Else [Offer5EndDate]
			 End as [Offer5EndDate]
			,Case
				When [Offer6EndDate] = '1900-01-01' then NULL
				Else [Offer6EndDate]
			 End as [Offer6EndDate]
			,Case
				When [Offer7EndDate] = '1900-01-01' then NULL
				Else [Offer7EndDate]
			 End as [Offer7endDate]
	From (
	Select	FanID,
			Max(Case
					When Slot = 1 then IronOfferID
					Else 0
				End) as Offer1,
			Max(Case
					When Slot = 2 then IronOfferID
					Else 0
				End) as Offer2,
			Max(Case
					When Slot = 3 then IronOfferID
					Else 0
				End) as Offer3,
			Max(Case
					When Slot = 4 then IronOfferID
					Else 0
				End) as Offer4,
			max(Case
					When Slot = 5 then IronOfferID
					Else 0
				End) as Offer5,
			Max(Case
					When Slot = 6 then IronOfferID
					Else 0
				End) as Offer6,
			Max(Case
					When Slot = 7 then IronOfferID
					Else 0
				End) as Offer7,
			Max(Case
					When Slot = 1 then StartDate
					Else 0
				End) as Offer1StartDate,
			Max(Case
					When Slot = 2 then StartDate
					Else 0
				End) as Offer2StartDate,
			Max(Case
					When Slot = 3 then StartDate
					Else 0
				End) as Offer3StartDate,
			Max(Case
					When Slot = 4 then StartDate
					Else 0
				End) as Offer4StartDate,
			Max(Case
					When Slot = 5 then StartDate
					Else 0
				End) as Offer5StartDate,
			Max(Case
					When Slot = 6 then StartDate
					Else 0
				End) as Offer6StartDate,
			Max(Case
					When Slot = 7 then StartDate
					Else 0
				End) as Offer7StartDate,
			Max(Case
					When Slot = 1 then EndDate
					Else 0
				End) as Offer1EndDate,
			Max(Case
					When Slot = 2 then EndDate
					Else 0
				End) as Offer2EndDate,
			Max(Case
					When Slot = 3 then EndDate
					Else 0
				End) as Offer3EndDate,
			Max(Case
					When Slot = 4 then EndDate
					Else 0
				End) as Offer4EndDate,
			Max(Case
					When Slot = 5 then EndDate
					Else 0
				End) as Offer5EndDate,
			Max(Case
					When Slot = 6 then EndDate
					Else 0
				End) as Offer6EndDate,
			Max(Case
					When Slot = 7 then EndDate
					Else 0
				End) as Offer7EndDate
	From #OfferDates
	Group by FanID
	) as a
	inner join [SmartEmail].[SampleCustomerLinks] as b
		on a.FanID = b.RealCustomerFanID
	inner join [SmartEmail].SampleCustomersList as c
		on b.SampleCustomerID = c.ID
