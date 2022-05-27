Create Procedure R_0171_CustomerSegmentSettings
with execute as Owner
as
Select	ps.PartnerID,
		p.PartnerName,
		Existing as LapsedMths,
		Lapsed as AcquireMths
From nFI.Segmentation.PartnerSettings as ps
inner join nfi.relational.partner as p
	on ps.PartnerID = p.PartnerID
Where ps.EndDate is null or EndDate > getdate() and
		ps.StartDate < getdate()