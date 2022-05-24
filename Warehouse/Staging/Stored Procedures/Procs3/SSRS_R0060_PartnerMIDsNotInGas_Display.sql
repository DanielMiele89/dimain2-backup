Create Procedure Staging.SSRS_R0060_PartnerMIDsNotInGas_Display
As

select	a.*,
		p.PartnerName 
from Warehouse.Staging.R_0060_Outlet_NotinMIDS as a
inner join warehouse.relational.Partner as p
	on a.PartnerID = p.PartnerID
Left Outer join [Staging].[R_0060_MIDs_tobeExcluded] as r
	on	a.PartnerID = r.PartnerID and
		a.MerchantID = r.MerchantID
Where	Replace(LocationCountry,' ','') = 'GB' and
		r.MerchantID is null