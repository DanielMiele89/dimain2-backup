CREATE Procedure Staging.SSRS_0171_CustomerSegmentsRun
With Execute as Owner
as
Select	p.PartnerID,
		p.PartnerName,
		ShopperSegmentTypeID,
		Max(StartDate) as LastStartDate
Into #SD
From	nfi.Segmentation.ROC_Shopper_Segment_Members as m
inner join nfi.relational.partner as p
	on m.PartnerID = p.PartnerID
Where EndDate is null
Group by p.PartnerID,ShopperSegmentTypeID,p.PartnerName

Select * 
From #SD