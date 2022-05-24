/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

Update:			N/A
					
*/
CREATE  Procedure [Staging].[SSRS_R0016_OfferSlots]
				 @LionSendID int
As
IF OBJECT_ID ('tempdb..#OfferSlots') IS NOT NULL DROP TABLE #OfferSlots

SELECT	DISTINCT OfferSlot,
	COUNT(CompositeID) as Customers
FROM	(
	SELECT	CompositeID,
		MAX(ItemRank) as OfferSlot
	FROM Warehouse.lion.NominatedLionSendComponent
	WHERE LionSendID = @LionSendID
	GROUP BY CompositeID
	)a
GROUP BY OfferSlot