/*
	Author:			Stuart Barnley

	Date:			10th Sepetmber 2015

	Purpose:		To provide data to report R_0099, this SP gives info about:
	
						a. ParterTriggers
						a. ParterTriggers_UC

*/

Create Procedure Staging.SSRS_R0099_PartnerTrigger (@PartnerID int)
AS
Declare @PID int

Set @PID = @PartnerID

----------------------------------------------------------------------------------
-------------Assess Warehouse for the presence of a IronOffer Records-------------
----------------------------------------------------------------------------------

Select	'PartnerTrigger_Campaigns' as [Type],
		c.PartnerID,
		c.CampaignID,
		c.CampaignName,
		c.DaysWorthTransactions,
		bra.BrandID,
		bra.BrandName
from warehouse.[Relational].[PartnerTrigger_Campaigns] as c
left outer join warehouse.[Relational].[PartnerTrigger_Brands] as b
	on c.[CampaignID] = b.[CampaignID]
left Outer join Warehouse.relational.Brand as bra
	on b.brandId = Bra.BrandID
Where c.PartnerID  = @PartnerID
Union All
Select	'PartnerTrigger_Campaigns_UC' as [Type],
		c.PartnerID,
		c.CampaignID,
		c.CampaignName,
		c.DaysWorthTransactions,
		bra.BrandID,
		bra.BrandName
from warehouse.[Relational].[PartnerTrigger_UC_Campaigns] as c
left outer join warehouse.[Relational].[PartnerTrigger_UC_Brands] as b
	on c.[CampaignID] = b.[CampaignID]
left Outer join Warehouse.relational.Brand as bra
	on b.brandId = Bra.BrandID
Where c.PartnerID  = @PartnerID
