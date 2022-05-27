/*
	Author:			Stuart Barnley

	Date:			10th Sepetmber 2015

	Purpose:		To provide data to report R_0099, this SP gives info about:
	
						a. the brand record

*/

CREATE Procedure Staging.SSRS_R0099_Brands (@PartnerID int)
AS
Declare @PID int

Set @PID = @PartnerID

----------------------------------------------------------------------------------
---------------Assess Warehouse for the presence of a Brand Record ---------------
----------------------------------------------------------------------------------
select	'Brand Table Record' as [Type],
		p.PartnerID,
		p.PartnerName,
		b.BrandID,
		b.BrandName
from warehouse.relational.partner as p
inner join warehouse.relational.Brand as b
	on p.BrandID = b.BrandID
Where p.PartnerID = @PartnerID