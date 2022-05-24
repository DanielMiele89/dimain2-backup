/********************************************************************************************
	Name: Staging.SSRS_R0181_FullSample_OfferSlotData
	Desc: Gets all Offer information for SmartEmail sample customers in order to cross check 
			Offer uploads
	Auth: Zoe Taylor

	Change History
	Initials	Date		Change Info
	RF			2018-10-11	Updated to include burn offers and to highlight the first instance of each offer per brand as well as overall

*********************************************************************************************/

CREATE PROCEDURE [Staging].[SSRS_R0181_FullSample_OfferSlotData_v2] (@LionSendID INT)

As
Begin 

	DECLARE @LSID INT = @LionSendID

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN(LionSendID)
			FROM [Lion].[NewsletterReporting] nr
			WHERE ReportSent = 0
			AND ReportName = 'SSRS_R0181_FullSample_OfferSlotData'
		END
		
/*******************************************************************************************************************************************
	1. Fetch all sample customer information 
*******************************************************************************************************************************************/

		If Object_ID('tempdb..#SmartEmailDailyData') Is Not Null Drop Table #SmartEmailDailyData
		Select LastName + ' - ' + Email AS Email
			 , sedd.FanID
			 , sedd.ClubID
			 , sedd.IsLoyalty
			 , SmartEmailSendID
			 , Offer1
			 , Offer2
			 , Offer3
			 , Offer4
			 , Offer5
			 , Offer6
			 , Offer7
			 , Offer1StartDate
			 , Offer2StartDate
			 , Offer3StartDate
			 , Offer4StartDate
			 , Offer5StartDate
			 , Offer6StartDate
			 , Offer7StartDate
			 , Offer1EndDate
			 , Offer2EndDate
			 , Offer3EndDate
			 , Offer4EndDate
			 , Offer5EndDate
			 , Offer6EndDate
			 , Offer7EndDate
			 , RedeemOffer1
			 , RedeemOffer2
			 , RedeemOffer3
			 , RedeemOffer4
			 , RedeemOffer5
			 , RedeemOffer1EndDate
			 , RedeemOffer2EndDate
			 , RedeemOffer3EndDate
			 , RedeemOffer4EndDate
			 , RedeemOffer5EndDate
		Into #SmartEmailDailyData 
		From SmartEmail.vw_SmartEmailDailyData_v2 sedd
		LEFT join SmartEmail.SampleCustomersList scli
			on sedd.FanID = scli.FanID
		LEFT join SmartEmail.SampleCustomerLinks scln
			on scli.ID = scln.SampleCustomerID
		Inner join Relational.Customer_RBSGSegments rbsg
			on COALESCE(scln.RealCustomerFanID, sedd.FanID) = rbsg.FanID
			and rbsg.EndDate Is Null
		Where sedd.SmartEmailSendID = @LSID


/*******************************************************************************************************************************************
	2. Transpose oofer data to long format
*******************************************************************************************************************************************/

		--	Offer7 assigned slot 0 as this is the hero slot for Earn offers

		If Object_ID('tempdb..#Offers') Is Not Null Drop Table #Offers
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer1 as ItemID
			 , Offer1StartDate as OfferStartDate
			 , Offer1EndDate as OfferEndDate
			 , 1 as Slot
		Into #Offers
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer2
			 , Offer2StartDate
			 , Offer2EndDate
			 , 2 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer3
			 , Offer3StartDate
			 , Offer3EndDate
			 , 3 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer4
			 , Offer4StartDate
			 , Offer4EndDate
			 , 4 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer5
			 , Offer5StartDate
			 , Offer5EndDate
			 , 5 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer6
			 , Offer6StartDate
			 , Offer6EndDate
			 , 6 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Earn' as OfferType
			 , Offer7
			 , Offer7StartDate
			 , Offer7EndDate
			 , 0 as Slot
		From #SmartEmailDailyData
		Union all
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Burn' as OfferType
			 , RedeemOffer1
			 , Null as RedeemOffer1StartDate
			 , RedeemOffer1EndDate
			 , 1 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Burn' as OfferType
			 , RedeemOffer2
			 , Null as RedeemOffer2StartDate
			 , RedeemOffer2EndDate
			 , 2 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Burn' as OfferType
			 , RedeemOffer3
			 , Null as RedeemOffer3StartDate
			 , RedeemOffer3EndDate
			 , 3 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Burn' as OfferType
			 , RedeemOffer4
			 , Null as RedeemOffer4StartDate
			 , RedeemOffer4EndDate
			 , 4 as Slot
		From #SmartEmailDailyData
		Union All
		Select FanID
			 , Email	
			 , ClubID
			 , IsLoyalty
			 , 'Burn' as OfferType
			 , RedeemOffer5
			 , Null as RedeemOffer5StartDate
			 , RedeemOffer5EndDate
			 , 0 as Slot
		From #SmartEmailDailyData


/*******************************************************************************************************************************************
	3. Offer data ranked to show first instance of offers in report
*******************************************************************************************************************************************/

		--	Offer with slot 1 assigned slot 0 as this is the hero slot for Burn offers

		If Object_ID('tempdb..#SSRS_R0181_FullSample_OfferSlotData_v2') Is Not Null Drop Table #SSRS_R0181_FullSample_OfferSlotData_v2
		Select FanID
			 , Email
			 , ClubID
			 , IsLoyalty
			 , ClubSegment
			 , OfferType
			 , ItemID
			 , OfferName
			 , OfferStartDate
			 , OfferEndDate
			 , Slot
			 , CONVERT(VARCHAR(30), OfferAge) AS OfferAge
			 , Dense_Rank() Over (Partition by OfferType, ItemID Order by ClubSegment, NewOfferCount Desc, FanID, Slot Asc) as OfferRank
			 , Dense_Rank() Over (Partition by ClubSegment, OfferType, ItemID Order by ClubSegment, NewOfferCount Desc, FanID, Slot Asc) as OfferRankPerSegment
		Into #SSRS_R0181_FullSample_OfferSlotData_v2
		From (	Select o.FanID
					 , o.Email	
					 , o.ClubID
					 , o.IsLoyalty
					 , Case
							When ClubID = 132 Then 
												Case
													When IsLoyalty = 0 Then 'NWC'
													Else 'NWP'
												End 
							When ClubID = 138 Then
												Case
													When IsLoyalty = 0 Then 'RBSC'
													Else 'RBSP'
												End
							Else 'None' 
					   End as ClubSegment
					 , o.OfferType
					 , o.ItemID
					 , Coalesce(iof.IronOfferName, ri.PrivateDescription) as OfferName
					 , OfferStartDate
					 , OfferEndDate
					 , Case
							When OfferType = 'Earn' Then Slot
							When OfferType = 'Burn' Then Slot
					   End as Slot
					 , Case
							When iof.StartDate > DATEADD(DAY, -1, GetDate()) Then 'New'
							Else 'Existing'
					   End as OfferAge
					 , Count(Case
								When iof.StartDate > DATEADD(DAY, -1, GetDate()) Then 1
							 End) Over (Partition by FanID) as NewOfferCount
				From #Offers o
				Left join Relational.IronOffer iof
					on o.ItemID = iof.IronOfferID
					and o.OfferType = 'Earn'
				Left join Relational.RedemptionItem ri
					on o.ItemID = ri.RedeemID
					and o.OfferType = 'Burn') [all]
					


/*******************************************************************************************************************************************
	4. Find offers that have not been checked previously
*******************************************************************************************************************************************/

	--IF OBJECT_ID('tempdb..#OffersRan') IS NOT NULL DROP TABLE #OffersRan
	--SELECT DISTINCT
	--	   ItemID
	--	 , TypeID
	--INTO #OffersRan
	--FROM [Lion].[LionSend_Offers] ls
	--WHERE ls.EmailSendDate < DATEADD(DAY, -1, GetDate())

	IF OBJECT_ID('tempdb..#OffersRan') IS NOT NULL DROP TABLE #OffersRan
	SELECT DISTINCT
		   ItemID
		 , TypeID
	INTO #OffersRan
	FROM [Lion].[LionSend_OffersRanPreviously] ls

	

	IF OBJECT_ID('tempdb..#OffersNotCheckedPreviously') IS NOT NULL DROP TABLE #OffersNotCheckedPreviously
	SELECT DISTINCT ItemID, OfferType, StartDate
	INTO #OffersNotCheckedPreviously
	FROM #SSRS_R0181_FullSample_OfferSlotData_v2 osd
	INNER JOIN [Relational].[IronOffer] iof
		ON osd.ItemID = iof.IronOfferID
	WHERE NOT EXISTS (	SELECT 1
						FROM #OffersRan ls
						WHERE osd.ItemID = ls.ItemID
						AND osd.OfferType = CASE WHEN ls.TypeID = 1 THEN 'Earn' ELSE 'Burn' END)


	UPDATE osd
	SET OfferAge = 'Existing - Not Checked'
	FROM #SSRS_R0181_FullSample_OfferSlotData_v2 osd
	INNER JOIN #OffersNotCheckedPreviously onc
		ON osd.ItemID = onc.ItemID
		AND osd.OfferType =onc.OfferType
	WHERE OfferAge = 'Existing'

/*******************************************************************************************************************************************
	5. Output for report
*******************************************************************************************************************************************/

		Select Email
			 , ClubSegment
			 , OfferType
			 , ItemID
			 , OfferName
			 , Slot
			 , OfferSlot
			 , OfferAge
			 , OfferRank
			 , OfferRankPerSegment
			 , OfferColour
			 , Row_Number() Over (Order by ClubSegment, OfferRank_Sum Desc, OfferRankPerSegment_Sum Desc, FanID, OfferType Desc, Slot) as ReportOrder
		From (
			Select FanID
				 , Email
				 , ClubSegment
				 , OfferType
				 , ItemID
				 , OfferName
				 , Slot
				 , Case
						When Slot = 0 Then 'Hero'
						Else Convert(VarChar(1), Slot)
				   End as OfferSlot
				 , CASE WHEN OfferAge = 'Existing' THEN 'Existing' ELSE 'New' END AS OfferAge
				 , OfferRank
				 , OfferRankPerSegment
				 , Case
						When OfferAge = 'New' And OfferRank = 1 Then '#fffe00'
						When OfferAge = 'New' And OfferRankPerSegment = 1 Then '#ffa500'
						When OfferAge = 'Existing - Not Checked' And OfferRank = 1 Then '#00ff00'
						When OfferAge = 'Existing - Not Checked' And OfferRankPerSegment = 1 Then '#00ffc0'
				   End as OfferColour
				 , Row_Number() Over (Order by ClubSegment, FanID, OfferType Desc, Slot) as ReportOrder
				 , Sum(Case
							When OfferAge = 'New' And OfferRank = 1 Then 1
					   End) Over (Partition by Email) as OfferRank_Sum
				 , Sum(Case
							When OfferAge = 'New' And OfferRankPerSegment = 1 Then 1
					   End) Over (Partition by Email) as OfferRankPerSegment_Sum
			From #SSRS_R0181_FullSample_OfferSlotData_v2) a
		Order by ClubSegment
			   , Row_Number() Over (Order by ClubSegment, OfferRank_Sum Desc, OfferRankPerSegment_Sum Desc, FanID, OfferType Desc, Slot)
			   , OfferType Desc
			   , Slot

	UPDATE [Lion].[NewsletterReporting]
	SET ReportSent = 1
	WHERE ReportSent = 0
	AND ReportName = 'SSRS_R0181_FullSample_OfferSlotData'
	AND LionSendID = @LSID
			   
End