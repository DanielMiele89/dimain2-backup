Create Procedure [Staging].[SSRS_R0024_PartnerRecord_All] @PartnerID int
as
Select	p.ID as PartnerID,
		p.Name as PartnerName
From	SLC_Report..Partner as p
Where	p.ID = @PartnerID