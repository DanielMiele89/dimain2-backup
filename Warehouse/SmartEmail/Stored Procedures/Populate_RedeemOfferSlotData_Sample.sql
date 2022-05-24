/*

	Author:	Stuart Barnley

	Date:	26th October 2017

	Purpose:	Convert data from NominatedLionSendComponent to fit in the new 
				structure for SmartEmail (Sand box.Stuart.[OfferSlotData])


*/
CREATE Procedure [SmartEmail].[Populate_RedeemOfferSlotData_Sample] (@LSID Int
																  , @EmailDate Date)
As

Declare @LionSendID Int = @LSID
	  , @Date Date = @EmailDate
				
--------------------------------------------------------------------------------------------
----------------------------Create a list of Customers (with RowNo)-------------------------
--------------------------------------------------------------------------------------------

If Object_ID('tempdb..#Customers') Is Not Null Drop Table #Customers
Select cu.CompositeID
	 , cu.FanID
Into #Customers
FROM Relational.Customer cu
WHERE EXISTS (SELECT 1
			  FROM Lion.NominatedLionSendComponent_RedemptionOffers ls
			  WHERE cu.CompositeID = ls.CompositeID
			  AND ls.LionSendID = @LionSendID)

Create Clustered Index cix_Customers_CompositeID on #Customers (CompositeID)
	
	--------------------------------------------------------------------------------------------
	----------------------------------Get Customer with OfferIDs--------------------------------
	--------------------------------------------------------------------------------------------

	If Object_ID('tempdb..#Offers') Is Not Null Drop Table #Offers
	Select cu.FanID
		 , ItemID as RedeemID
		 , ItemRank as Slot
		 , Convert(DateTime, Null) as EndDate
	Into #Offers
	From #Customers cu
	Inner join Lion.NominatedLionSendComponent_RedemptionOffers nlscr
		on cu.CompositeId = nlscr.CompositeId
	Where LionSendID = @LionSendID

	Create Clustered index Offers_IronOfferID_CompositeID on #Offers (FanID)

	--------------------------------------------------------------------------------------------
	-------------------------------------Insert Data into Table---------------------------------
	--------------------------------------------------------------------------------------------

	Insert into [SmartEmail].[RedeemOfferSlotData]
	Select scls.[FanID]
		 , @LionSendID as [LionSendID]
		 , [RedeemOffer1]
		 , [RedeemOffer2]
		 , [RedeemOffer3]
		 , [RedeemOffer4]
		 , [RedeemOffer5]
		 , Case
				When [RedeemOffer1EndDate] = '1900-01-01' then NULL
				Else [RedeemOffer1EndDate]
			 End as [RedeemOffer1EndDate]
		 , Case
				When [RedeemOffer2EndDate] = '1900-01-01' then NULL
				Else [RedeemOffer2EndDate]
			 End as [RedeemOffer2EndDate]
		 , Case
				When [RedeemOffer3EndDate] = '1900-01-01' then NULL
				Else [RedeemOffer3EndDate]
			 End as [RedeemOffer3EndDate]
		 , Case
				When [RedeemOffer4EndDate] = '1900-01-01' then NULL
				Else [RedeemOffer4EndDate]
			 End as [RedeemOffer4EndDate]
		 , Case
				When [RedeemOffer5EndDate] = '1900-01-01' then NULL
				Else [RedeemOffer5EndDate]
			 End as [RedeemOffer5EndDate]
	From (Select FanID
			   , Max(Case
					 	When Slot = 1 then RedeemID
					 	Else 0
					 End) as RedeemOffer1
			   , Max(Case
						When Slot = 2 then RedeemID
						Else 0
					 End) as RedeemOffer2
			   , Max(Case
						When Slot = 3 then RedeemID
						Else 0
					 End) as RedeemOffer3
			   , Max(Case
						When Slot = 4 then RedeemID
						Else 0
					 End) as RedeemOffer4
			   , max(Case
						When Slot = 5 then RedeemID
						Else 0
					 End) as RedeemOffer5
			   , Max(Case
						When Slot = 1 then EndDate
						Else 0
					 End) as RedeemOffer1EndDate
			   , Max(Case
						When Slot = 2 then EndDate
						Else 0
					 End) as RedeemOffer2EndDate
			   , Max(Case
						When Slot = 3 then EndDate
						Else 0
					 End) as RedeemOffer3EndDate
			   , Max(Case
						When Slot = 4 then EndDate
						Else 0
					 End) as RedeemOffer4EndDate
			   , Max(Case
						When Slot = 5 then EndDate
						Else 0
					 End) as RedeemOffer5EndDate
		  From #Offers
		  Group by FanID) od
	Inner join SmartEmail.SampleCustomerLinks scln
		on od.FanID = scln.RealCustomerFanID
	Inner join SmartEmail.SampleCustomersList scls
		on scln.SampleCustomerID = scls.ID