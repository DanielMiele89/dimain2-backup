
CREATE PROCEDURE [Staging].[SSRS_R0185_MyRewardsCampaignSelectionsQA_SelectionsLogic](
			@Date Date
			)

AS
BEGIN

--	Declare @Date Date = '20180607'

			Select Distinct 
				   als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.CampaignName
				 , als.StartDate
				 , als.EndDate
				 , Case
						When iof.IronOfferName like '%Debit%Credit%' or iof.IronOfferName like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
						When iof.IronOfferName like '%Debit%' or iof.IronOfferName like '%Debit%' then ClientServicesRef + '_Debit'
						When iof.IronOfferName like '%Credit%' or iof.IronOfferName like '%Credit%' then ClientServicesRef + '_Credit'
						Else ClientServicesRef
				   End as ClientServicesRef
				 , Replace(als.OutputTableName,'Warehouse.Selections.','') as OutputTableName
				 , als.DeDupeAgainstCampaigns
				 , Replace(als.NotIn_TableName1,'Warehouse.Selections.','') as NotIn_TableName1
				 , Replace(als.NotIn_TableName2,'Warehouse.Selections.','') as NotIn_TableName2
				 , Replace(als.NotIn_TableName3,'Warehouse.Selections.','') as NotIn_TableName3
				 , Replace(als.NotIn_TableName4,'Warehouse.Selections.','') as NotIn_TableName4
				 , Replace(als.MustBeIn_TableName1,'Warehouse.Selections.','') as MustBeIn_TableName1
				 , Replace(als.MustBeIn_TableName2,'Warehouse.Selections.','') as MustBeIn_TableName2
				 , Replace(als.MustBeIn_TableName3,'Warehouse.Selections.','') as MustBeIn_TableName3
				 , Replace(als.MustBeIn_TableName4,'Warehouse.Selections.','') as MustBeIn_TableName4
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.SelectedInAnotherCampaign
				 , als.CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.PriorityFlag
				 , als.NewCampaign
				 , als.BriefLocation
				 , Replace(als.sProcPreSelection,'Warehouse.Selections.','') as sProcPreSelection
				 , DENSE_RANK() Over (Order by Case
													When iof.IronOfferName like '%Debit%Credit%' or iof.IronOfferName like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
													When iof.IronOfferName like '%Debit%' or iof.IronOfferName like '%Debit%' then ClientServicesRef + '_Debit'
													When iof.IronOfferName like '%Credit%' or iof.IronOfferName like '%Credit%' then ClientServicesRef + '_Credit'
													Else ClientServicesRef
											   End) as ClientServiceRefRank
			From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
			Left join Warehouse.Relational.IronOffer iof
				on als.OfferID like '%' + Convert(varchar(6),iof.IronOfferID)  + '%'
				and als.PartnerID = iof.PartnerID
				and als.StartDate >= iof.StartDate
				and als.EndDate <= iof.EndDate
			Where EmailDate Between Dateadd(day,-14,@Date) And @Date
			And als.EndDate > @Date
			Order by PartnerID
					,PriorityFlag
				
End