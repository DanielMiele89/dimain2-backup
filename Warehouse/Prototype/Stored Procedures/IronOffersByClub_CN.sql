
CREATE procedure Prototype.IronOffersByClub_CN
	as
	begin


DECLARE @ClubID int
Set @ClubID = 145

select *
from nFI.Relational.IronOffer io
inner join nFI.Relational.Club c
on io.ClubID = c.ClubID
inner join nFI.Relational.Partner p
on io.PartnerID = p.PartnerID
inner join nFI.Relational.IronOffer_PartnerCommissionRule iop
--on iop.PartnerID = p.PartnerID
ON IOP.IronOfferID = IO.ID
where LiveStatus = 1
and TypeID = 1
and StartDate <= GETDATE()
AND EndDate >= GETDATE()
AND C.CLUBID = @ClubID

end