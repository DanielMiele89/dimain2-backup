

CREATE PROCEDURE [Staging].[SSRS_R0138_OfferCountsForEmail] 

@LionSendID int

AS
BEGIN

declare @LSID int
set @LSID = @LionSendID

Select	IronOfferID,
	PartnerName,
	OfferName,
	StartDate,
	EndDate,
	coalesce([7],0) as [Hero Slot],
	Coalesce([1],0) as [Slot 1],
	Coalesce([2],0) as [Slot 2],	
	Coalesce([3],0) as [Slot 3],
	Coalesce([4],0) as [Slot 4],
	Coalesce([5],0) as [Slot 5],
	Coalesce([6],0) as [Slot 6]
FROM	(
	SELECT	nlsc.ItemRank as AdSpaceNumber, 
		nlsc.ItemID	  as IronOfferID, 
		p.PartnerName, 
		io.Name as OfferName,
		io.StartDate, 
		io.EndDate, 
		COUNT(CompositeId) as OfferPromotionCount	
	FROM Warehouse.lion.NominatedLionSendComponent nlsc
	LEFT OUTER JOIN SLC_Report.dbo.IronOffer io 
		ON nlsc.ItemID = io.ID
	--LEFT OUTER JOIN Warehouse.Relational.PartnerOffers_Base po 
	--	ON io.ID = po.OfferID
	Left JOIN warehouse.relational.Partner p 
		ON io.PartnerID = p.PartnerID
	WHERE	nlsc.LionSendID = @LSID 
	GROUP BY nlsc.ItemRank,nlsc.ItemID, p.PartnerName, io.Name,io.StartDate, io.EndDate
	) as a
PIVOT
(
SUM (OfferPromotionCount)
FOR AdSpaceNumber IN
( [7],[1],[2],[3],[4],[5],[6] )
) AS pvt
ORDER BY IronOfferID

END
