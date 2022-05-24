CREATE Procedure Staging.PartnerOffersBase_Additions (@OfferID int,@AddReview char)
With Execute as Owner
As

Declare	@CashBackRate real,
		@Qry nvarchar(max)

--Set @OfferID = 11211
Set @Qry = ''

Set @CashbackRate = 
	(	Select Max(pcr.CommissionRate) as CashbackRate
		From SLC_Report.dbo.PartnerCommissionRule as pcr
		Where	RequiredIronOfferID = @OfferID
				and TypeID = 1
				and Status = 1
	)

Select * 
from warehouse.relational.IronOffer as i
Where IronOfferID = @OfferID

If @AddReview = 'A'
Begin
	Set @Qry = 'Insert into Relational.PartnerOffers_Base'
End
Set @Qry = @Qry+ '
Select	p.PartnerID,
		p.PartnerName,
		i.IronOfferName as OfferName,
		i.IronOfferID as OfferID,
		'''+CasT(@CashbackRate as varchar)+'%'' as CashBackRateText,
		'+Cast(@CashbackRate/100 as varchar)+' as CashbackRateNumeric,
		Case
			When ClubID = 132 then ''NatWest''
			Else ''RBS''
		End as Bank,
		ClubID,
		i.StartDate,
		i.EndDate,
		1 as AllSegments,
		null as HTMID,
		0 as CardType
From warehouse.relational.ironoffer as i
inner join slc_report.dbo.ironofferclub as ioc
	on i.IronOfferID = ioc.IronOfferID
inner join warehouse.relational.partner as p
	on i.partnerid = p.partnerid
Where i.IronOfferID = '+Cast(@OfferID as varchar)

Exec sp_ExecuteSQL @Qry