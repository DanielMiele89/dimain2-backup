/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

	Update:			Updated on 2018-10-11 by RF to include Burn offers and remove reference to CustomerJourney table
					
*/
Create Procedure [Staging].[SSRS_R0016_OfferSlots_v2] (@LionSendID Int)
As
Begin

Declare @LSID Int = @LionSendID

	Select OfferType + ' - ' + Convert(VarChar(5), OfferSlot) as OfferTypeSlots
		 , Count(Distinct CompositeID) as Customers
	From (	Select CompositeID
				 , Max(ItemRank) as OfferSlot
				 , 'Earn offers' as OfferType
			From Lion.NominatedLionSendComponent
			Where LionSendID = @LSID
			Group by CompositeID
			Union all
			Select CompositeID
				 , Max(ItemRank) as OfferSlot
				 , 'Burn offers' as OfferType
			From Lion.NominatedLionSendComponent_RedemptionOffers
			Where LionSendID = @LSID
			Group by CompositeID) nlsc
	Group by OfferType + ' - ' + Convert(VarChar(5), OfferSlot)

End