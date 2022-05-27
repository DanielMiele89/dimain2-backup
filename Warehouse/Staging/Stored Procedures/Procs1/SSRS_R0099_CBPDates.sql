/*
	Author:			Stuart Barnley

	Date:			10th Sepetmber 2015

	Purpose:		To provide data to report R_0099, this SP gives info about:
	
						a. the Partner_CBPDates record

*/

CREATE Procedure Staging.SSRS_R0099_CBPDates (@PartnerID int)
AS
Declare @PID int

Set @PID = @PartnerID

----------------------------------------------------------------------------------
-------Assess Warehouse for the presence of a Partner_CBPDates Record ------------
----------------------------------------------------------------------------------
select	p.PartnerID,
		p.PartnerName,
		b.Scheme_StartDate,
		b.Scheme_EndDate
from warehouse.relational.partner as p
inner join warehouse.relational.Partner_CBPDates as b
	on p.PartnerID = b.PartnerID
Where p.PartnerID = @PartnerID