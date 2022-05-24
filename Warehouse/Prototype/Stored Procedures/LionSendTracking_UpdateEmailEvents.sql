Create Procedure [Prototype].[LionSendTracking_UpdateEmailEvents]
as
Begin

	DROP INDEX [CSX_LionSendCustomers_All] ON [Prototype].[LionSend_Customers]

	-- update campaign key info

		If Object_ID('tempdb..#EmailCampaign') Is Not Null Drop Table #EmailCampaign
		Select ec.CampaignKey
			 , CampaignName
			 , SendDate
			 , Case
				When CampaignName Like '%NWC%' Or CampaignName Like '%NatWest%' Then 132
				When CampaignName Like '%NWP%' Or CampaignName Like '%NatWest%' Then 132
				When CampaignName Like '%RBSC%' Or CampaignName Like '%RBS%' Then 138
				When CampaignName Like '%RBSP%' Or CampaignName Like '%RBS%' Then 138
			   End as ClubID
			 , Case
				When CampaignName Like '%NWC%' Or CampaignName Like '%Core%' Then 0
				When CampaignName Like '%NWP%' Or CampaignName Like '%Private%' Then 1
				When CampaignName Like '%RBSC%' Or CampaignName Like '%Core%' Then 0
				When CampaignName Like '%RBSP%' Or CampaignName Like '%Private%' Then 1
			   End as IsLoyalty
			 , Case When PatIndex('%LSID%', CampaignName) > 0 Then Substring(CampaignName, PatIndex('%LSID%', CampaignName) + 4, 3) Else Null End as LionSendID
		Into #EmailCampaign
		From Warehouse.Relational.EmailCampaign ec
		Where CampaignName Like '%newsletter%'

		Update ls
		Set ls.CampaignKey = ec.CampaignKey
		From [Prototype].[LionSend_Customers] ls
		Inner join #EmailCampaign ec
			on ls.LionSendID = ec.LionSendID
			and ls.IsLoyalty = ec.IsLoyalty
			and ls.ClubID = ec.ClubID
		Where ls.CampaignKey Is Null
	

	-- update sent & opened
	
		If Object_ID('tempdb..#EmailNotSent') Is Not Null Drop Table #EmailNotSent
		Select lsc.CampaignKey
			 , lsc.FanID
		Into #EmailNotSent
		From [Prototype].[LionSend_Customers] lsc
		Where lsc.EmailSent = 0

		Create Clustered Index CIX_EmailNotSent_FanID On #EmailNotSent (CampaignKey, FanID)
	

		If Object_ID('tempdb..#EmailSent') Is Not Null Drop Table #EmailSent
		Select Distinct
			   ee.CampaignKey
			 , ee.FanID
		Into #EmailSent
		From #EmailNotSent ens
		Inner join Warehouse.Relational.EmailEvent ee
			on ens.FanID = ee.FanID
			and ens.CampaignKey = ee.CampaignKey

		Update lsc
		Set EmailSent = 1
		From Warehouse.Prototype.LionSend_Customers lsc
		Inner join #EmailSent es
			on lsc.CampaignKey = es.CampaignKey
			and lsc.FanID = es.FanID
		Where EmailSent = 0
	
		If Object_ID('tempdb..#EmailNotOpened') Is Not Null Drop Table #EmailNotOpened
		Select lsc.CampaignKey
			 , lsc.FanID
		Into #EmailNotOpened
		From [Prototype].[LionSend_Customers] lsc
		Where lsc.EmailOpened = 0

		Create Clustered Index CIX_EmailNotOpened_CampaignKeyFanID On #EmailNotOpened (CampaignKey, FanID)


		If Object_ID('tempdb..#EmailOpens') Is Not Null Drop Table #EmailOpens
		Select ee.CampaignKey
			 , ee.FanID
			 , Min(EventDate) as EventDate
		Into #EmailOpens
		From #EmailNotOpened eno
		Inner join Warehouse.Relational.EmailEvent ee
			on eno.CampaignKey = ee.CampaignKey
			and eno.FanID = ee.FanID
		Where ee.EmailEventCodeID = 1301
		Group by ee.CampaignKey
			   , ee.FanID

		Update lsc
		Set EmailOpened = 1
		  , EmailOpenedDate = EventDate
		From Warehouse.Prototype.LionSend_Customers lsc
		Inner join #EmailOpens eo
			on lsc.CampaignKey = eo.CampaignKey
			and lsc.FanID = eo.FanID
		Where EmailOpened = 0
		

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Prototype].[LionSend_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [IsLoyalty], [EmailSent], [EmailOpened], [EmailOpenedDate])

End