/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

Update:			N/A
					
*/
Create Procedure [Staging].[SSRS_R0016_OfferStats_v2] (@LionSendID Int
													, @EmailSEndDate Date)
AS
Begin

	Declare @LSID Int = 544--@LionSendID
		  , @Date Date = '2018-10-11'--@EmailSEndDate

	If Object_ID('tempdb..#PartnerCommissionRule') Is Not Null Drop Table #PartnerCommissionRule
	Select RequiredIronOfferID
		 , Max(Case When Status = 1 And TypeID = 1 Then CommissionRate End) as CashbackRate
		 , Convert(Numeric(32,2), Max(Case When Status = 1 And TypeID = 2 Then CommissionRate End)) as CommissionRate
	Into #PartnerCommissionRule
	From SLC_Report..PartnerCommissionRule pcr
	Where RequiredIronOfferID Is Not Null
	Group by RequiredIronOfferID

	Create Clustered Index CIX_PartnerCommissionRule_IoronOfferID On #PartnerCommissionRule (RequiredIronOfferID)

	If Object_ID('tempdb..#NominatedLionSendComponent') Is Not Null Drop Table #NominatedLionSendComponent
	Select Distinct ItemID
	Into #NominatedLionSendComponent
	From Lion.NominatedLionSendComponent
	Where LionSendID = @LSID

	Create Clustered Index CIX_NominatedLionSendComponent_IoronOfferID On #NominatedLionSendComponent (ItemID)


	Select Count(ItemID) as OffersPromoted
		 , Count(Case When Convert(Date, iof.StartDate) < @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as Offers_CurrentlyLive
		 , Count(Case When Convert(Date, iof.StartDate) = @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as Offers_AboutToGoLive
		 , Count(Case When iof.EndDate <= @Date Then ItemID Else NULL End) as Offers_ExpiredByEmailSEndDate
		 , Count(Case When Convert(Date, iof.StartDate) > @Date Then ItemID Else NULL End) as Offers_NotLiveOnEmailSEndDate
		 , Count(Case When pcr.CashbackRate Is Not Null Then ItemID Else NULL End) as Offers_WithCashBackRates
		 , Count(Case When pcr.CommissionRate Is Not Null Then ItemID Else NULL End) as Offers_WithCommissionRates
	From #NominatedLionSendComponent nlsc
	Inner join Warehouse.Relational.IronOffer iof
		on nlsc.ItemID = iof.IronOfferID
		and iof.IsTriggerOffer = 0
	Left join #PartnerCommissionRule pcr
		on nlsc.ItemID = pcr.RequiredIronOfferID
	Union All
	Select Count(ItemID) as OffersPromoted
		 , Count(Case When Convert(Date, iof.StartDate) < @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as Offers_CurrentlyLive
		 , Count(Case When Convert(Date, iof.StartDate) = @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as Offers_AboutToGoLive
		 , Count(Case When iof.EndDate <= @Date Then ItemID Else NULL End) as Offers_ExpiredByEmailSEndDate
		 , Count(Case When Convert(Date, iof.StartDate) > @Date Then ItemID Else NULL End) as Offers_NotLiveOnEmailSEndDate
		 , Count(Case When pcr.CashbackRate Is Not Null Then ItemID Else NULL End) as Offers_WithCashBackRates
		 , Count(Case When pcr.CommissionRate Is Not Null Then ItemID Else NULL End) as Offers_WithCommissionRates
	From #NominatedLionSendComponent nlsc
	Inner join Warehouse.Relational.IronOffer iof
		on nlsc.ItemID = iof.IronOfferID
		and iof.IsTriggerOffer = 1
	Inner join #PartnerCommissionRule pcr
		on nlsc.ItemID = pcr.RequiredIronOfferID

End