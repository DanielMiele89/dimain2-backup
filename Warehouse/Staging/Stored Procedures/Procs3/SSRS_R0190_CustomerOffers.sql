 

 CREATE PROCEDURE Staging.SSRS_R0190_CustomerOffers (@SourceUID Varchar(50), @TransDate date, @PartnerName varchar(20))
 AS
 BEGIN
 
	--Declare 
	--	@SourceUID varchar(50) = '1711867566'
	--	, @TransDate date = '2018-10-26'
	--	, @PartnerName varchar(20) = ''
	
	Select Distinct 
		f.ID FanID
		, f.SourceUID SourceUID
		, F.FirstName
		, f.LastName
		, C.Name ClubName
		, p.Name PartnerName
		, io.ID IronOfferID
		, io.Name IronOfferName
		, iom.StartDate IronOfferMember_StartDate
		, Case 
				when iom.enddate is not null then iom.enddate 
				when iom.enddate is null and io.enddate <= @TransDate then io.enddate
				else NULL 
			End as IronOfferMember_EndDate	
	, pcr.CommissionRate CommissionRate_BelowSS
	, pcr_ss.RequiredMinimumBasketSize SpendStretchAmount
	, pcr_ss.CommissionRate CommissionRate_AboveSS	
	From SLC_Report..Fan f 
	Inner join SLC_Report..Club c 
		on c.ID = f.ClubID
	Inner Join SLC_Report..IronOfferMember iom
		on iom.CompositeID = f.CompositeID
	Inner join SLC_Report..IronOffer io 
		on io.ID = iom.IronOfferID
	Left join SLC_Report..PartnerCommissionRule pcr
		on pcr.RequiredIronOfferID = io.ID
		and pcr.DeletionDate is null
		and pcr.RequiredMinimumBasketSize is NULL
		and pcr.TypeID = 1
	Left join SLC_Report..PartnerCommissionRule pcr_ss
		on pcr_ss.RequiredIronOfferID = io.ID
		and pcr_ss.DeletionDate is null
		and pcr_ss.RequiredMinimumBasketSize IS NOT NULL
		and pcr_ss.TypeID = 1
	Inner join SLC_Report..Partner p 
		on p.ID = io.PartnerID
	Where f.SourceUID = @SourceUID
	and p.Name like '%' + @PartnerName + '%'
	and iom.StartDate < @TransDate
	and (@TransDate < isnull(iom.EndDate, io.EndDate) or ISNULL(iom.EndDate, io.EndDate) is NULL) 
	Order by iom.StartDate


end