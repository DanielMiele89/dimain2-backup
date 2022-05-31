/*
	
	Author:		Stuart Barnley

	Date:		7th December 2016

	Purpose:	Mark as LiveOffer = 0 any offer that has expired

	Updates:	N/A
*/

Create Procedure Segmentation.Update_Roc_Shopper_Segment_to_Offers (@EndDate date)
With Execute as owner
As


Update a
Set LiveOffer = 0
From nfi.[Segmentation].[ROC_Shopper_Segment_To_Offers] as a
inner join nfi.relational.ironoffer as i
	on a.ironofferid = i.id
Where EndDate <= @EndDate and
		LiveOffer = 1
