

CREATE PROCEDURE [Staging].[SSRS_R0138_OfferCountsForEmail_v2] (@LionSendID Int)

AS
BEGIN

	--DECLARE @LionSendID INT = 746

	DECLARE @LSID INT = @LionSendID

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN(LionSendID)
			FROM [Lion].[NewsletterReporting] nr
			WHERE ReportSent = 0
			AND ReportName = 'SSRS_R0138_OfferCountsForEmail'
		END

	Select ItemID
		 , PartnerName
		 , OfferType
		 , OfferName
		 , StartDate
		 , EndDate
		 , Coalesce([1],0) as [Hero Slot]
		 , Coalesce([2],0) as [Slot 1]
		 , Coalesce([3],0) as [Slot 2]	
		 , Coalesce([4],0) as [Slot 3]
		 , Coalesce([5],0) as [Slot 4]
		 , Coalesce([6],0) as [Slot 5]
		 , Coalesce([7],0) as [Slot 6]
	From (	Select Case
						When nlsc.ItemRank = 7 Then 1
						Else nlsc.ItemRank + 1
				   End as ItemRank
				 , nlsc.ItemID
				 , pa.PartnerName
				 , 'Earn' as OfferType
				 , iof.IronOfferName as OfferName
				 , iof.StartDate
				 , iof.EndDate
				 , Count(CompositeID) as Customers	
			From Lion.NominatedLionSendComponent nlsc
			Left join Relational.IronOffer iof
				on nlsc.ItemID = iof.IronOfferID
			Left join Relational.Partner pa 
				on iof.PartnerID = pa.PartnerID
			Where nlsc.LionSendID = @LSID 
			Group by nlsc.ItemRank
				   , nlsc.ItemID
				   , pa.PartnerName
				   , iof.IronOfferName
				   , iof.StartDate
				   , iof.EndDate
			Union all
			Select nlscr.ItemRank
				 , nlscr.ItemID
				 , pa.PartnerName
				 , 'Burn' as OfferType
				 , ri.PrivateDescription as OfferName
				 , Null as StartDate
				 , Null as EndDate
				 , Count(CompositeID) as Customers	
			From Lion.NominatedLionSendComponent_RedemptionOffers nlscr
			Left join Relational.RedemptionItem ri
				on nlscr.ItemID = ri.RedeemID
			Left join Relational.RedemptionItem_TradeUpValue tuv
				on ri.RedeemID = tuv.RedeemID
			Left join Relational.Partner pa
				on tuv.PartnerID = pa.PartnerID
			Where nlscr.LionSendID = @LSID 
			Group by nlscr.ItemRank
				   , nlscr.ItemID
				   , pa.PartnerName
				   , ri.PrivateDescription) [all]
	PIVOT (Sum(Customers) For ItemRank In ([1], [2], [3], [4], [5], [6], [7])) as pvt
	Order by OfferType
		   , PartnerName
		   , OfferName

	UPDATE [Lion].[NewsletterReporting]
	SET ReportSent = 1
	WHERE ReportSent = 0
	AND ReportName = 'SSRS_R0138_OfferCountsForEmail'
	AND LionSendID = @LSID

End





