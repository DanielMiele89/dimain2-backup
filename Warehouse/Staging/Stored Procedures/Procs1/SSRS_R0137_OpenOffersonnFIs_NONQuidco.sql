/*

	Author:		Stuart Barnley

	Date:		9th November 2016

	Purpose:	To list all offer eligible for nFis (non Quidco), that are NOT All Members Applied


*/

Create Procedure [Staging].[SSRS_R0137_OpenOffersonnFIs_NONQuidco] (@Date Date)
With Execute as Owner
As


----------------------------------------------------------------------------------
-------------------------------Find list of offers--------------------------------
----------------------------------------------------------------------------------

select --p.PartnerID,
	p.PartnerName, c.ClubName,i.*
From nFI.Relational.IronOffer as i
inner join nfi.Relational.Partner as p
	on i.PartnerID = p.PartnerID
inner join nfi.relational.club as c
	on i.ClubID = c.ClubID
where	startdate <= @Date and
		(EndDate is null or EndDate > @Date) and
		IsAppliedToAllMembers = 0 and
		c.clubid <> 12
Order by ClubName,PartnerName,p.PartnerID