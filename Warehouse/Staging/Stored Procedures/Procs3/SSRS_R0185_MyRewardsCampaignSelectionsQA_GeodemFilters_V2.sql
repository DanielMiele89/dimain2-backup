

CREATE PROCEDURE [Staging].[SSRS_R0185_MyRewardsCampaignSelectionsQA_GeodemFilters_V2](
			@Date Date
			)

AS
BEGIN

	--Declare @Date Date = '2019-10-10'
	
			If OBJECT_ID('tempdb..#ROCShopperSegment_PreSelection_ALS_Temp') IS NOT NULL Drop Table #ROCShopperSegment_PreSelection_ALS_Temp
			Select Distinct als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.StartDate
				 , als.EndDate
				 , Case when MarketableByEmail = 0 then 'False' else 'True' end as MarketableByEmail
				 , als.PaymentMethodsAvailable
				 , als.OfferID
				 , als.Throttling
				 , Case
						When iof.Name like '%Debit%Credit%' or iof.Name like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
						When iof.Name like '%Debit%' or iof.Name like '%Debit%' then ClientServicesRef + '_Debit'
						When iof.Name like '%Credit%' or iof.Name like '%Credit%' then ClientServicesRef + '_Credit'
						Else ClientServicesRef
				   End as ClientServicesRef
				 , als.OutputTableName
				 , als.CampaignName
				 , NULL AS SelectionDate
				 , als.DeDupeAgainstCampaigns
				 , als.Gender
				 , als.AgeRange
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.DriveTimeMins
				 , als.LiveNearAnyStore
				 , NULL AS OutletSector
				 , als.SocialClass
				 , als.SelectedInAnotherCampaign
				 , NULL AS CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.RandomThrottle
				 , als.PriorityFlag
				 , als.NewCampaign
				 , Case
						When als.PredictedCardholderVolumes is null then '0,0,0,0,0,0'
						Else als.PredictedCardholderVolumes
				   End as PredictedCardholderVolumes
				 , als.BriefLocation
				 , DENSE_RANK() Over (Order by Case
													When iof.Name like '%Debit%Credit%' or iof.Name like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
													When iof.Name like '%Debit%' or iof.Name like '%Debit%' then ClientServicesRef + '_Debit'
													When iof.Name like '%Credit%' or iof.Name like '%Credit%' then ClientServicesRef + '_Credit'
													Else ClientServicesRef
											   End) as ClientServiceRefRank
			Into #ROCShopperSegment_PreSelection_ALS_Temp
			From Warehouse.Selections.CampaignSetup_POS als
			Left join SLC_REPL..IronOffer iof
				on als.OfferID like '%' + Convert(varchar(6),iof.ID)  + '%'
				and als.PartnerID = iof.PartnerID
				and als.StartDate >= iof.StartDate
				and als.EndDate <= iof.EndDate
			Where EmailDate = @Date
			UNION ALL
			
			Select Distinct als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.StartDate
				 , als.EndDate
				 , Case when MarketableByEmail = 0 then 'False' else 'True' end as MarketableByEmail
				 , als.PaymentMethodsAvailable
				 , als.OfferID
				 , als.Throttling
				 , Case
						When iof.Name like '%Debit%Credit%' or iof.Name like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
						When iof.Name like '%Debit%' or iof.Name like '%Debit%' then ClientServicesRef + '_Debit'
						When iof.Name like '%Credit%' or iof.Name like '%Credit%' then ClientServicesRef + '_Credit'
						Else ClientServicesRef
				   End as ClientServicesRef
				 , als.OutputTableName
				 , als.CampaignName
				 , NULL AS SelectionDate
				 , als.DeDupeAgainstCampaigns
				 , als.Gender
				 , als.AgeRange
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.DriveTimeMins
				 , als.LiveNearAnyStore
				 , NULL AS OutletSector
				 , als.SocialClass
				 , als.SelectedInAnotherCampaign
				 , NULL AS CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.RandomThrottle
				 , als.PriorityFlag
				 , als.NewCampaign
				 , Case
						When als.PredictedCardholderVolumes is null then '0,0,0,0,0,0'
						Else als.PredictedCardholderVolumes
				   End as PredictedCardholderVolumes
				 , als.BriefLocation
				 , DENSE_RANK() Over (Order by Case
													When iof.Name like '%Debit%Credit%' or iof.Name like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
													When iof.Name like '%Debit%' or iof.Name like '%Debit%' then ClientServicesRef + '_Debit'
													When iof.Name like '%Credit%' or iof.Name like '%Credit%' then ClientServicesRef + '_Credit'
													Else ClientServicesRef
											   End) as ClientServiceRefRank
			From WH_Virgin.Selections.CampaignSetup_POS als
			Left join SLC_REPL..IronOffer iof
				on als.OfferID like '%' + Convert(varchar(6),iof.ID)  + '%'
				and als.PartnerID = iof.PartnerID
				and als.StartDate >= iof.StartDate
				and als.EndDate <= iof.EndDate
			Where EmailDate = @Date

			If OBJECT_ID('tempdb..#ROCShopperSegment_PreSelection_ALS') IS NOT NULL Drop Table #ROCShopperSegment_PreSelection_ALS
			SELECT als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.StartDate
				 , als.EndDate
				 , als.MarketableByEmail
				 , als.PaymentMethodsAvailable
				 , CASE 
						WHEN iof.Item > 0 THEN iof.Item
						ELSE ''
				   END AS OfferID
				 , CASE
						WHEN iof.ItemNumber = 1 THEN 'Acquire'
						WHEN iof.ItemNumber = 2 THEN 'Lapsed'
						WHEN iof.ItemNumber = 3 THEN 'Shopper'
						WHEN iof.ItemNumber = 4 THEN 'Welcome'
						WHEN iof.ItemNumber = 5 THEN 'Birthday'
						WHEN iof.ItemNumber = 6 THEN 'Homemover'
				   END AS OfferSegment
				 , thr.Item AS Throttling
				 , als.ClientServicesRef
				 , als.OutputTableName
				 , als.CampaignName
				 , als.SelectionDate
				 , als.DeDupeAgainstCampaigns
				 , als.Gender
				 , als.AgeRange
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.DriveTimeMins
				 , als.LiveNearAnyStore
				 , als.OutletSector
				 , als.SocialClass
				 , als.SelectedInAnotherCampaign
				 , als.CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.RandomThrottle
				 , als.PriorityFlag
				 , als.NewCampaign
				 , pcn.Item AS PredictedCardholderVolumes
				 , als.BriefLocation
				 , als.ClientServiceRefRank
			INTO #ROCShopperSegment_PreSelection_ALS
			FROM #ROCShopperSegment_PreSelection_ALS_Temp als
			CROSS APPLY dbo.il_SplitDelimitedStringArray (OfferID, ',') iof
			CROSS APPLY dbo.il_SplitDelimitedStringArray (Throttling, ',') thr
			CROSS APPLY dbo.il_SplitDelimitedStringArray (PredictedCardholderVolumes, ',') pcn
			WHERE iof.ItemNumber = thr.ItemNumber
			AND thr.ItemNumber = pcn.ItemNumber

			IF OBJECT_ID ('tempdb..#OfferSegments') IS NOT NULL DROP TABLE #OfferSegments
			Create Table #OfferSegments (OfferSegment varchar(10)
									   , OfferID varchar(150)
									   , Throttling varchar(150)
									   , PredictedCardholderVolumes varchar(150))

			Insert Into #OfferSegments (OfferSegment
									  , OfferID
									  , Throttling
									  , PredictedCardholderVolumes)
			Values
			('Launch','00000','0','0'),
			('Universal','00000','0','0'),
			('Bespoke','00000','0','0')

			INSERT INTO #ROCShopperSegment_PreSelection_ALS
			SELECT DISTINCT
				   als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.StartDate
				 , als.EndDate
				 , als.MarketableByEmail
				 , als.PaymentMethodsAvailable
				 , os.OfferID
				 , os.OfferSegment
				 , os.Throttling
				 , als.ClientServicesRef
				 , als.OutputTableName
				 , als.CampaignName
				 , als.SelectionDate
				 , als.DeDupeAgainstCampaigns
				 , als.Gender
				 , als.AgeRange
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.DriveTimeMins
				 , als.LiveNearAnyStore
				 , als.OutletSector
				 , als.SocialClass
				 , als.SelectedInAnotherCampaign
				 , als.CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.RandomThrottle
				 , als.PriorityFlag
				 , als.NewCampaign
				 , os.PredictedCardholderVolumes
				 , als.BriefLocation
				 , als.ClientServiceRefRank
			FROM #OfferSegments os
			CROSS JOIN #ROCShopperSegment_PreSelection_ALS als
			

			IF OBJECT_ID ('tempdb..#RowsToRemove') IS NOT NULL DROP TABLE #RowsToRemove
			SELECT ROW_NUMBER() OVER (PARTITION BY ClientServiceRefRank, OfferSegment ORDER BY OfferID DESC) ToSelectRow
				 , *
			INTO #RowsToRemove
			FROM #ROCShopperSegment_PreSelection_ALS

			DELETE als
			FROM #ROCShopperSegment_PreSelection_ALS als
			INNER JOIN #RowsToRemove rtr
				ON als.ID = rtr.ID
				AND als.OfferSegment = rtr.OfferSegment
			WHERE rtr.ToSelectRow > 1

IF OBJECT_ID ('tempdb..#AllCampaignData') IS NOT NULL DROP TABLE #AllCampaignData
Select Distinct als.ClientServiceRefRank
			  , als.EmailDate
			  , als.PartnerID
			  , als.StartDate
			  , als.EndDate
			  , als.MarketableByEmail
			  , als.PaymentMethodsAvailable
			  , als.OfferSegment
			  , Replace(als.OfferID,'00000','') as OfferID
			  , als.Throttling
			  , ClientServicesRef
			  , als.OutputTableName
			  , als.CampaignName
			  , als.SelectionDate
			  , als.DeDupeAgainstCampaigns
			  , als.Gender
			  , als.AgeRange
			  , als.CampaignID_Include
			  , als.CampaignID_Exclude
			  , als.DriveTimeMins
			  , als.LiveNearAnyStore
			  , als.SocialClass
			  , als.SelectedInAnotherCampaign
			  , als.CampaignTypeID
			  , als.CustomerBaseOfferDate
			  , als.RandomThrottle
			  , als.PriorityFlag
			  , als.NewCampaign
			  , als.PredictedCardholderVolumes
			  , als.BriefLocation
			  , Case
					When als.OfferSegment = 'Acquire' then 1
					When als.OfferSegment = 'Lapsed' then 2
					When als.OfferSegment = 'Shopper' then 3
					When als.OfferSegment = 'Bespoke' then 4
					When als.OfferSegment = 'Welcome' then 5
					When als.OfferSegment = 'Launch' then 6
					When als.OfferSegment = 'Universal' then 7
					When als.OfferSegment = 'Birthday' then 8
					When als.OfferSegment = 'Homemover' then 9
			   End as SegmentOrder
Into #AllCampaignData
From #ROCShopperSegment_PreSelection_ALS als
Order by ClientServicesRef
		,SegmentOrder

IF OBJECT_ID ('tempdb..#ComissionRule') IS NOT NULL DROP TABLE #ComissionRule
select Distinct
		a.ClientServicesRef
		, a.PartnerID
		, p.RequiredIronOfferID
		, p.TypeID
		, p.CommissionRate
		, p.RequiredMinimumBasketSize
		, p.RequiredChannel
Into #ComissionRule
from #AllCampaignData a
Inner join SLC_REPL..PartnerCommissionRule p
	on a.OfferID = p.RequiredIronOfferID
Where p.DeletionDate is null
And p.Status = 1

IF OBJECT_ID ('tempdb..#RequiredChannel') IS NOT NULL DROP TABLE #RequiredChannel
Select Distinct 
		ClientServicesRef
		, PartnerID
		, RequiredIronOfferID as IronOfferID
		, Case when RequiredChannel is null then '' else RequiredChannel end as RequiredChannel
Into #RequiredChannel
From #ComissionRule

IF OBJECT_ID ('tempdb..#SpendStretch') IS NOT NULL DROP TABLE #SpendStretch
Select Distinct ao.ClientServicesRef
		, ao.PartnerID
		, ao.IronOfferID
		, Coalesce(o.OfferRate,0) as OfferRate
		, Coalesce(s.SpendStretchAmount,0) as SpendStretchAmount
		, Coalesce(s.SpendStretchRate,0) as SpendStretchRate
		, Coalesce(ob.BillingRate,0) as BillingRate
		, Coalesce(sb.SpendStretchBillingRate,0) as SpendStretchBillingRate

Into #SpendStretch
From (
	Select cr.ClientServicesRef
		 , cr.PartnerID
		 , cr.RequiredIronOfferID as IronOfferID
	From #ComissionRule cr) ao
Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, MIN(cr.CommissionRate) as OfferRate
	From #ComissionRule cr
	Where TypeID = 1
	And RequiredMinimumBasketSize is null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) o
	on ao.IronOfferID = o.RequiredIronOfferID

Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, MIN(cr.CommissionRate) as BillingRate
	From #ComissionRule cr
	Where TypeID = 2
	And RequiredMinimumBasketSize is null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) ob
	on ao.IronOfferID = ob.RequiredIronOfferID

Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, Max(cr.CommissionRate) as SpendStretchRate
			, MIN(cr.RequiredMinimumBasketSize) as SpendStretchAmount
	From #ComissionRule cr
	Where TypeID = 1
	And RequiredMinimumBasketSize is not null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) s
	on ao.IronOfferID = s.RequiredIronOfferID

Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, Max(cr.CommissionRate) as SpendStretchBillingRate
	From #ComissionRule cr
	Where TypeID = 2
	And RequiredMinimumBasketSize is not null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) sb
	on ao.IronOfferID = sb.RequiredIronOfferID

	IF OBJECT_ID ('tempdb..#SSRS_R0185_MyRewardsCampaignSelectionsQA') IS NOT NULL DROP TABLE #SSRS_R0185_MyRewardsCampaignSelectionsQA
	Select Distinct
			  OfferSegment as [Shopper Segment Label]
			, Case when OfferID = '' then '' else Case When Throttling > 0 And RandomThrottle = 0 Then 'Yes' When Throttling is null then null Else 'No' End End as [Selection (Top x%)]
			, Case when OfferID = '' then '' else Gender end as [Gender (M/F/Unspecified)]
			, Case when OfferID = '' then '' else Case when AgeRange = '' then '' when AgeRange is null then null else Left(AgeRange,PATINDEX('%-%',AgeRange)-1) end end as [Age Group Min]
			, Case when OfferID = '' then '' else Case when AgeRange = '' then '' when AgeRange is null then null else Right(AgeRange,Len(AgeRange) - PATINDEX('%-%',AgeRange)) end end as [Age Group Max]
			, Case when OfferID = '' then '' else 
				  Case
						When DriveTimeMins > 0 And LiveNearAnyStore = 1 Then '<= 25 mins'
						When DriveTimeMins > 0 And LiveNearAnyStore = 0 Then '> 25 mins'
						When DriveTimeMins = '' then ''
						When DriveTimeMins = 0 then ''
						Else NULL
				  End 
			  End as [Drive Time (<=25mins or >25mins)]
			, Case when OfferID = '' then '' else Case when SocialClass = '' then '' when SocialClass is null then null else Right(SocialClass,PATINDEX('%-%',SocialClass)-1) end end as [Social Class Lowest]
			, Case when OfferID = '' then '' else Case when SocialClass = '' then '' when SocialClass is null then null else Left (SocialClass,PATINDEX('%-%',SocialClass)-1) end end as [Social Class Highest]
			, Case when OfferID = '' then '' else MarketableByEmail End as [Marketable By Email?]
			, ss.OfferRate / 100 as [Offer Rate]
			, ss.SpendStretchAmount as [Spend Stretch Amount]
			, ss.SpendStretchRate / 100 as [Above Spend Stretch Rate]
			, OfferId as [Ironoffer ID]
			, Case when OfferID = '' then '' else Case When Throttling > 0 And RandomThrottle = 1 Then 'Yes' When Throttling is null then null Else 'No' End End as [Throttling]
			, BillingRate / 100 as [Offer Billing Rate]
			, SpendStretchBillingRate / 100 as [Above Spend Stretch Billing Rate]
			, Case when OfferID = '' then '' else PredictedCardholderVolumes end as [Predicted Cardholder Volumes]
			, Case when OfferID = '' then '' else 
				Case
					When rc.RequiredChannel = 0 Then 'Both'
					When rc.RequiredChannel = 1 Then 'Online'
					When rc.RequiredChannel = 2 Then 'Offline'
				End
			  End as RequiredChannel
			, ac.PartnerID
			, ac.ClientServicesRef as ClientServicesRef
			, ac.EmailDate as EmailDate
			, ac.PriorityFlag
			, AVG(ac.PriorityFlag*100) Over (Partition by ac.ClientServicesRef) as CampaignPriorityFlag
			, SegmentOrder as OfferOrder
			, CampaignID_Include
			, CampaignID_Exclude
			, DeDupeAgainstCampaigns
			, SelectedInAnotherCampaign
			, CustomerBaseOfferDate
			, PaymentMethodsAvailable
			, CampaignTypeID
			, ac.StartDate
			, ac.EndDate
			, nc.NewCampaign
			, BriefLocation
			, CampaignName
			, Case
	 				When OfferID = '' then ''
					When REVERSE(SUBSTRING(REVERSE(iof.Name),0,CHARINDEX('/',REVERSE(iof.Name)))) like '%' + ac.OfferSegment + '%' then 'Black'
	 				Else 'Red'
			  End as OfferSegmentErrorColour
			, Case When ac.PartnerID <> iof.PartnerID then 'Red' Else 'Black' End as OfferPartnerIDColour
			, DENSE_RANK() Over (Partition by ac.PartnerID, ac.ClientServicesRef, ac.OutputTableName Order by SegmentOrder) as DistinctSeleciton
	Into #SSRS_R0185_MyRewardsCampaignSelectionsQA
	From #AllCampaignData ac
	Left join SLC_REPL..IronOffer iof
		on ac.OfferID = iof.ID
	Left join #SpendStretch ss
		on ac.OfferID = ss.IronOfferID
	Left join #RequiredChannel rc
		on ac.ClientServicesRef = rc.ClientServicesRef
	Left join (Select ClientServicesRef, NewCampaign, EmailDate From #AllCampaignData Where NewCampaign is not null) nc
		on	ac.ClientServicesRef = nc.ClientServicesRef
		and	ac.EmailDate = nc.EmailDate
	Left join Warehouse.Relational.Partner pa
		on ac.PartnerID = pa.PartnerID
Order by ClientServicesRef
		,SegmentOrder	

Select roc.[Shopper Segment Label]	
 , roc.[Selection (Top x%)]
 , roc.[Gender (M/F/Unspecified)]
 , roc.[Age Group Min]
 , roc.[Age Group Max]
 , roc.[Drive Time (<=25mins or >25mins)]
 , roc.[Social Class Lowest]
 , roc.[Social Class Highest]
 , roc.[Marketable By Email?]
 , roc.[Offer Rate]
 , roc.[Spend Stretch Amount]
 , roc.[Above Spend Stretch Rate]
 , roc.[Ironoffer ID]
 , roc.Throttling
 , Convert(Float,roc.[Offer Billing Rate]) as [Offer Billing Rate]
 , roc.[Above Spend Stretch Billing Rate]
 , roc.[Predicted Cardholder Volumes]
 , roc.RequiredChannel
 , roc.ClientServicesRef
 , roc.EmailDate
 , roc.PriorityFlag
 , roc.CampaignPriorityFlag
 , roc.OfferOrder
 , roc.CampaignID_Include
 , roc.CampaignID_Exclude
 , roc.DeDupeAgainstCampaigns
 , roc.SelectedInAnotherCampaign
 , roc.CustomerBaseOfferDate
 , roc.PaymentMethodsAvailable
 , roc.CampaignTypeID
 , CampaignName
 , roc.StartDate
 , roc.EndDate
 , roc.NewCampaign
 , roc.BriefLocation
 , roc.OfferSegmentErrorColour
 , roc.OfferPartnerIDColour
 , roc.PartnerID
 , roc.DistinctSeleciton
 , bi.ClientServiceReference as ClientServiceReference_Brief
 , bi.ShopperSegment as ShopperSegment_Brief
 , bi.SelectionTopXPercent as SelectionTopXPercent_Brief
 , bi.Gender as Gender_Brief
 , bi.AgeGroupMin as AgeGroupMin_Brief
 , bi.AgeGroupMax as AgeGroupMax_Brief
 , bi.DriveTime as DriveTime_Brief
 , bi.SocialClassLowest as SocialClassLowest_Brief
 , bi.SocialClassHighest as SocialClassHighest_Brief
 , bi.MarketableByEmail as MarketableByEmail_Brief
 , Convert(Float,Replace(Replace(bi.OfferRate,'%',''), '£', '')) / 100 as OfferRate_Brief
 , Replace(bi.SpendStretchAmount,'£','') as SpendStretchAmount_Brief
 , Convert(Float,Replace(Replace(bi.AboveSpendStretchRate,'%',''), '£', '')) / 100 as AboveSpendStretchRate_Brief
 , bi.IronOfferID as IronOfferID_Brief
 , bi.RandomThrottle as RandomThrottle_Brief
 , Convert(Float,Replace(Replace(bi.OfferBillingRate,'%',''), '£', '')) / 100 as OfferBillingRate_Brief
 , Convert(Float,Replace(Replace(bi.AboveSpendStretchBillingRate,'%',''), '£', '')) / 100 as AboveSpendStretchBillingRate_Brief
 , Replace(bi.PredictedCardholderVolumes,',','') as PredictedCardholderVolumes_Brief
 , bi.ActualCardholderVolumes as ActualCardholderVolumes_Brief
From #SSRS_R0185_MyRewardsCampaignSelectionsQA roc
Full outer join Warehouse.Selections.ROCShopperSegment_CampaignQA_BriefInput bi
	on roc.ClientServicesRef = bi.ClientServiceReference
	and roc.[Shopper Segment Label] = bi.ShopperSegment
Where NewCampaign = 1
Order by roc.ClientServicesRef
		,roc.OfferOrder	
		
				
End