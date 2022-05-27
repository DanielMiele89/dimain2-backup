/*
	Author:			Stuart Barnley

	Date:			10th Sepetmber 2015

	Purpose:		To provide data to report R_0099, this SP gives info about:
	
						a. the partner record
						b. have outlets been added
						c. has a commission rate been added

*/

Create Procedure Staging.SSRS_R0099_Partners (@PartnerID int)
AS
Declare @PID int

Set @PID = @PartnerID

----------------------------------------------------------------------------------
---------------Assess Warehouse for the presence of a Partner Record -------------------
----------------------------------------------------------------------------------
select	'Partner Table Record' as [Type],
		p.PartnerID,
		p.PartnerName,
		p.BrandID,
		p.BrandName,
		Count(Distinct OutletID) as Outlets,
		cast(a.CommissionRate/a.CurrentRate as real) as CommissionRate
from warehouse.relational.partner as p
left outer join warehouse.relational.outlet as o
	on p.PartnerID = o.PartnerID
Left outer join Warehouse.relational.PartnerCommissionRates_PostLaunch as a
	on p.partnerid = a.PartnerID
Where p.PartnerID = @PartnerID
Group by p.PartnerID,
		p.PartnerName,
		p.BrandID,
		p.BrandName,
		cast(a.CommissionRate/a.CurrentRate as real) 