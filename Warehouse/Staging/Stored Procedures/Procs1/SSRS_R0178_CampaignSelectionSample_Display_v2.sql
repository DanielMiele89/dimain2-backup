
CREATE PROCEDURE [Staging].[SSRS_R0178_CampaignSelectionSample_Display_v2] (@LionSendIDSample Int)
AS

BEGIN

/********************************************************************************************************************
Title: Campaign Selection - Sample Selection Display
Author: Stuart Barnley
Creation Date: 17 November 2017
Purpose: To display the sample data for the campaign, to be run from SSRS report

Updated RF 9th October 2018
Updating original fetch to also include sample data for remption offers and to
pull distinct offers for every segment
*********************************************************************************************************************/


If Object_ID('tempdb..#NominatedLionSendComponent_All') Is Not Null Drop Table #NominatedLionSendComponent_All
Select LionSendID
	 , CompositeID
	 , TypeID
	 , ItemRank
	 , ClientServicesRef
	 , ItemID
	 , IronOfferName as OfferName
	 , StartDate
Into #NominatedLionSendComponent_All
From Warehouse.Lion.NominatedLionSendComponent nlsc
Inner join Warehouse.Relational.IronOffer iof
	on nlsc.ItemID = iof.IronOfferID
	and nlsc.TypeID = 1
Left join Warehouse.Relational.IronOffer_Campaign_HTM htm
	on iof.IronOfferID = htm.IronOfferID
Where LionSendID = @LionSendIDSample
Union
Select LionSendID
	 , CompositeID
	 , TypeID
	 , ItemRank
	 , Null as ClientServicesRef
	 , ItemID
	 , PrivateDescription as OfferName
	 , Null as StartDate
From Warehouse.Lion.NominatedLionSendComponent_RedemptionOffers nlscr
Inner join Warehouse.Relational.RedemptionItem ri
	on nlscr.ItemID = ri.RedeemID
Where LionSendID = @LionSendIDSample 


If Object_ID('tempdb..#R_0132_LionSendComponent_Sample') Is Not Null Drop Table #R_0132_LionSendComponent_Sample
Select scli.FanID
	 , scli.EmailAddress
	 , Case
			When TypeID = 1 Then nlsc.ItemRank
			When TypeID = 3 Then nlsc.ItemRank + 7
	   End as ItemRank
	 , Case
			When TypeID = 1 Then 'Earn'
			When TypeID = 3 Then 'Burn'
	   End as ItemType
	 , nlsc.ClientServicesRef
	 , nlsc.ItemID
	 , nlsc.OfferName
	 , Convert(Date, nlsc.StartDate) As StartDate
	 , Case
	  		When nlsc.StartDate > GetDate() then 'New'
	  		Else 'Existing'
	   End as [Offer Age]
	 , Case 
	  		When cu.ClubID = 132 And rbsg.CustomerSegment Not Like '%V%' Then 'Natwest - Core'
	  		When cu.ClubID = 132 And rbsg.CustomerSegment Like '%V%' Then 'Natwest - Private'
	  		When cu.ClubID = 138 And rbsg.CustomerSegment Not Like '%V%' Then 'RBS - Core'
	  		When cu.ClubID = 138 And rbsg.CustomerSegment Like '%V%' Then 'RBS - Private'
	   End as ClubSegment
Into #SSRS_R0178_CampaignSelectionSample
From #NominatedLionSendComponent_All nlsc
Inner join Relational.Customer cu
	on nlsc.CompositeID = cu.CompositeID
Inner join Relational.Customer_RBSGSegments rbsg
	on cu.FanID = rbsg.FanID
	and EndDate Is Null
Inner join SmartEmail.SampleCustomerLinks scln
	on cu.FanID = scln.RealCustomerFanID
Inner join SmartEmail.SampleCustomersList scli
	on scln.SampleCustomerID = scli.ID


Select FanID
	 , EmailAddress
	 , ItemRank
	 , ClientServicesRef
	 , ItemID
	 , ItemType
	 , OfferName
	 , StartDate
	 , [Offer Age]
	 , ClubSegment
	 , Rank() Over (Partition by ClubSegment Order by FanID, ItemRank) as RankPerSegment
From (Select FanID
		   , EmailAddress
		   , ItemRank
		   , ClientServicesRef
		   , ItemID
		   , ItemType
		   , OfferName
		   , StartDate
		   , [Offer Age]
		   , ClubSegment
		   , Rank() Over (Partition by ClubSegment, ItemType, ItemID Order by FanID, ItemRank) as ItemRankPerSegment
	   From #SSRS_R0178_CampaignSelectionSample) [all]
Where ItemRankPerSegment = 1
Order by ClubSegment
	   , FanID
	   , ItemRank



END

