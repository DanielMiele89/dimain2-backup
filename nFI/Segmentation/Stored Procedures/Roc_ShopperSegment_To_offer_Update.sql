--Use nFI
/*

	Author:		Stuart Barnley

	Date:		26th Janaury 2017

	Purpose:	To automate the population of the nFI.[Segmentation].[ROC_Shopper_Segment_To_Offers]
				table (Where Possible)

*/

CREATE Procedure Segmentation.Roc_ShopperSegment_To_offer_Update (@Date date,@Type tinyint)
As
------------------------------------------------------------------------------------------------------------------------
-------------------------Look for new offers on various nFIs for new potential new Entries -----------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
Select	i.*,
		Case
			When a.ID is not null then a.ID
			When IronOfferName like '%Welcome%' then 0
			When IronOfferName like '%Joiner%' then 0
			Else NULL 
		End as SegmentID,
		1 as LiveOffer,
		Case
			When IronOfferName like '%Welcome%' then 1
			When IronOfferName like '%Joiner%' then 1
			Else 0
		End as WelcomeOffer
Into #Offers
From Relational.IronOffer as i
Left Outer join [Segmentation].[ROC_Shopper_Segment_Types] as a
	on Replace(a.SegmentName,' ','') = Right(Replace(IronOfferName,' ',''),Len(Replace(a.SegmentName,' ','')))
Left Outer join Warehouse.[iron].[PrimaryRetailerIdentification] as b
	on	i.PartnerID = b.PartnerID and
		b.[PrimaryPartnerID] is not null
where	clubid <> 12 and
		replace(IronOfferName,' ','') not like '%LowInterest%' and
		StartDate >= @Date and
		b.PartnerID is null
		

------------------------------------------------------------------------------------------------------------------------
-------------------------------------Create table of Possible Additions ------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

SELECT o.ironoffername, 
       startdate, 
       enddate, 
       o.partnerid, 
       o.clubid, 
       o.id      AS IronOfferID, 
       segmentid AS ShopperSegmentTypeID, 
       liveoffer, 
       welcomeoffer 
Into   #PossibleAdditions
FROM   #offers AS o 
       LEFT OUTER JOIN (SELECT partnerid, 
                               clubid 
                        FROM   #offers AS o 
                        WHERE  segmentid IS NULL) AS a 
                    ON o.partnerid = a.partnerid 
                       AND o.clubid = a.clubid 
WHERE  a.partnerid IS NULL 
------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Review Additions to table -------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
Select	pa.*
From #PossibleAdditions as pa
left outer join [Segmentation].[ROC_Shopper_Segment_To_Offers] as a
	on pa.IronOfferID = a.IronOfferID
Where a.IronOfferID is null
ORDER  BY pa.clubid, 
          pa.partnerid, 
          pa.IronOfferID  
------------------------------------------------------------------------------------------------------------------------
------------------------------------Populate table of Possible Additions -----------------------------------------------
------------------------------------------------------------------------------------------------------------------------
If @Type = 1
Begin
	Declare @RowNo int
	
	Insert into [Segmentation].[ROC_Shopper_Segment_To_Offers]
	Select	pa.IronOfferID,
			pa.ShopperSegmentTypeID,
			pa.LiveOffer,
			pa.WelcomeOffer
	From #PossibleAdditions as pa
		left outer join [Segmentation].[ROC_Shopper_Segment_To_Offers] as a
		on pa.IronOfferID = a.IronOfferID
	Where a.IronOfferID is null
	
	Set @RowNo = @@RowCount

	Select 'Rows Added' as [Description], @RowNo as RowsAdded
End
------------------------------------------------------------------------------------------------------------------------
------------------------------------Select * from  -----------------------------------------------
------------------------------------------------------------------------------------------------------------------------
Select a.*,i.StartDate,i.EndDate
From [Segmentation].[ROC_Shopper_Segment_To_Offers] as a
inner join [Relational].IronOffer as i
	on a.IronOfferID = i.ID
Where i.EndDate < @Date and
		LiveOffer = 1

if @Type = 1
Begin
	Update a
	Set LiveOffer = 0
	From [Segmentation].[ROC_Shopper_Segment_To_Offers] as a
	inner join [Relational].IronOffer as i
		on a.IronOfferID = i.ID
	Where i.EndDate < @Date and
		LiveOffer = 1

	Set @RowNo = @@RowCount

	Select 'LiveOffers Unticked' as [Description], @RowNo as RowsAdded
End


If @Type = 1
Begin
	Select * 
	From #Offers as o
	left outer join [Segmentation].[ROC_Shopper_Segment_To_Offers] as b
		on o.ID = b.IronOfferID
End