/*

	Author:			Stuart Barnley

	Date:			25th July 2017

	Purpose:		To display the current rules used to make sure some retailers are sent to 
					the most appropriate clients. This is used when a retailer has a clear market 
					and thus would not be overly attractive to others.

*/

CREATE Procedure [Staging].[SSRS_R0167_OPE_Desirable_Customers]
--With Execute as Owner
As


Select	d.*,
		p.Name as PartnerName,
		a.CurrentlyActive
From slc_report.dbo.partner as p
inner join Selections.OPEPartnerdesirable as d
	on p.ID = d.PartnerID
Left Outer join Relational.Partner as a
	on p.id = a.PartnerID
	
