-- =============================================
-- Author:		JEA
-- Create date: 14/08/2013
-- Description:	Verifies whether transactions in 
-- SchemeUpliftTrans would pass the live matching rules
--REWORKED - new version is MI.SchemeUpliftTrans_CheckExclusion
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_Stage_CheckExclusion] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxID INT, @StartID INT, @EndID INT, @Increment INT = 500000

	SELECT @MaxID = COUNT(1) FROM MI.SchemeUpliftTrans_Stage

	SET @StartID = 1
	SET @EndID = @Increment

	WHILE @StartID < @MaxID
	BEGIN

		UPDATE s set ExcludeNonTime = 0
		FROM MI.SchemeUpliftTrans_Stage s
		INNER JOIN
		(
			select
				n.FileID, 
				n.RowNum--, 
				--iom.ID as IronOfferMemberID
			from mi.SchemeUpliftTrans_stage n
			inner join slc_report.dbo.RetailOutlet ro on n.OutletID = ro.ID
			inner join slc_report.dbo.[Partner] p on ro.PartnerID = p.ID
			--inner join slc_report.dbo.PartnerCommissionRule pcr on ro.PartnerID = pcr.PartnerID
			--inner join slc_report.dbo.IronOfferMember iom on pcr.RequiredIronOfferID = iom.IronOfferID and iom.CompositeID = n.CompositeID
			inner join slc_report.dbo.IronOffer io --on iom.IronOfferID = io.ID and io.PartnerID = pcr.PartnerID
										on io.PartnerID = p.id
			where 
				n.ID BETWEEN @StartID AND @EndID AND
				n.FanID is not null and
				--n.MatchID = 0 and --eligible transactions only
				--UNCOMMENT BELOW WHEN WE GO LIVE: done
				io.IsSignedOff = 1 --and 
				--pcr.Status = 1 and
				--pcr.TypeID = 2 and --2 FOR REGULAR COMMISSION
				----(pcr.RequiredMinimumHourOfDay is null or pcr.RequiredMinimumHourOfDay<=datepart(hour,n.TranDate)) and
				----(pcr.RequiredMaximumHourOfDay is null or pcr.RequiredMaximumHourOfDay>=datepart(hour,n.TranDate)) and
				--(pcr.RequiredMinimumBasketSize is null or pcr.RequiredMinimumBasketSize <= abs(n.Amount)) and
				--(pcr.RequiredMaximumBasketSize is null or pcr.RequiredMaximumBasketSize >= abs(n.Amount)) and
				--(pcr.RequiredChannel is null or pcr.RequiredChannel=ro.Channel) and
				--(pcr.RequiredClubID is null or pcr.RequiredClubID = n.ClubID) and
				--(pcr.RequiredAffiliateID is null or pcr.RequiredAffiliateID = 1) and
				----(pcr.RequiredMerchantID is null or pcr.RequiredMerchantID = n.MerchantID) and
				--(pcr.RequiredRetailOutletID is null or pcr.RequiredRetailOutletID = n.OutletID)
		) u on s.fileid = u.fileid and s.rownum = u.rownum

		--UPDATE s set ExcludeTime = 0
		--FROM MI.SchemeUpliftTrans_Stage s
		--INNER JOIN
		--(
		--	select
		--		n.FileID, 
		--		n.RowNum, 
		--		iom.ID as IronOfferMemberID
		--	from mi.SchemeUpliftTrans_stage n
		--	inner join slc_report.dbo.RetailOutlet ro on n.OutletID = ro.ID
		--	inner join slc_report.dbo.PartnerCommissionRule pcr on ro.PartnerID = pcr.PartnerID
		--	inner join slc_report.dbo.IronOfferMember iom on pcr.RequiredIronOfferID = iom.IronOfferID and iom.CompositeID = n.CompositeID
		--	inner join slc_report.dbo.IronOffer io on iom.IronOfferID = io.ID and io.PartnerID = pcr.PartnerID
		--	where 
		--		n.ID BETWEEN @StartID AND @EndID AND
		--		n.FanID is not null and
		--		--n.MatchID = 0 and --eligible transactions only
		--		--UNCOMMENT BELOW WHEN WE GO LIVE: done
		--		io.IsSignedOff = 1 and 
		--		pcr.Status = 1 and
		--		pcr.TypeID = 2 and --2 FOR REGULAR COMMISSION
		--		(pcr.StartDate is null or pcr.StartDate <= n.TranDate) and
		--		(pcr.EndDate is null or pcr.EndDate >= n.TranDate) and
		
		--		(iom.StartDate is null or iom.StartDate <= n.TranDate) and
		--		(iom.EndDate is null or iom.EndDate >= n.TranDate) and
		
		--		(io.StartDate is null or io.StartDate <= n.TranDate) and
		--		(io.EndDate is null or io.EndDate >= n.TranDate) and
		
		--		--(pcr.RequiredMinimumHourOfDay is null or pcr.RequiredMinimumHourOfDay<=datepart(hour,n.TranDate)) and
		--		--(pcr.RequiredMaximumHourOfDay is null or pcr.RequiredMaximumHourOfDay>=datepart(hour,n.TranDate)) and
		--		(pcr.RequiredMinimumBasketSize is null or pcr.RequiredMinimumBasketSize <= abs(n.Amount)) and
		--		(pcr.RequiredMaximumBasketSize is null or pcr.RequiredMaximumBasketSize >= abs(n.Amount)) and
		--		(pcr.RequiredChannel is null or pcr.RequiredChannel=ro.Channel) and
		--		(pcr.RequiredClubID is null or pcr.RequiredClubID = n.ClubID) and
		--		(pcr.RequiredAffiliateID is null or pcr.RequiredAffiliateID = 1) and
		--		--(pcr.RequiredMerchantID is null or pcr.RequiredMerchantID = n.MerchantID) and
		--		(pcr.RequiredRetailOutletID is null or pcr.RequiredRetailOutletID = n.OutletID)
		--) u on s.fileid = u.fileid and s.rownum = u.rownum

		SET @StartID = @StartID + @Increment
		SET @EndID = @EndID + @Increment

	END

END
