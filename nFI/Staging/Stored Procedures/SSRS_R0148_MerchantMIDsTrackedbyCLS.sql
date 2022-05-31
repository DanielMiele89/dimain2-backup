Create Procedure Staging.SSRS_R0148_MerchantMIDsTrackedbyCLS (@PartnerID int)
As

Select	p.Name as PartnerName,
		p.ID as PartnerID,
		ro.ID as OutletID,
		ro.MerchantID,
		f.Address1,
		f.Address2,
		f.City,
		f.Postcode,
		Case
			When ro.Channel = 1 then 'Yes'
			Else 'No'
		End as IsOnline,
		cls.StartDate,
		s.StatusDescription
into #MerchantIDs
From slc_report..Partner as p
inner join slc_report..Retailoutlet as ro
	on p.ID = ro.PartnerID
Left outer join slc_report..Fan as f
	on ro.FanID = f.ID
inner join nFi.Relational.Outlets_TrackedbyCLS as cls
	on ro.id = cls.OutletID
inner join nFi.Relational.Outlets_TrackedbyCLSStatuses as s
	on cls.StatusID = s.ID
Where (ro.PartnerID = @PartnerID or @PartnerID is null)

Select * from #MerchantIDs