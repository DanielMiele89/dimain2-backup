Create Procedure [Staging].[SSRS_R0024_PartnerOutletValidationv2] @PartnerID int
as
select	ro.ID as OutletID,
		ro.MerchantID,
		f.Address1,
		f.Address2,
		f.City,
		f.Postcode,
		Case
			When ro.SuppressFromSearch = 1 then 'No'
			When ro.SuppressFromSearch = 0 then 'Yes'
			Else 'Unknown'
		End as VisibleonWebsite,
		Case
			When ro.Channel = 1 then 'Yes'
			Else 'No'
		End as Isonline
from slc_report.dbo.retailoutlet as ro
Left Outer join slc_report.dbo.fan as f
	on ro.FanID = f.ID
	--on o.OutletID = ro.ID
Where ro.Partnerid = @PartnerID
Order by f.PostCode,VisibleonWebsite Desc