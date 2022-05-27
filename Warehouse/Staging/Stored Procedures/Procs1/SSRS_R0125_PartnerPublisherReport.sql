

-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 11/05/2016
-- Description: 
-- *****************************************************************************************************
Create PROCEDURE [Staging].[SSRS_R0125_PartnerPublisherReport](
			@PartnerID SMALLINT,
			@ClubID SMALLINT
			)
									
AS

	SET NOCOUNT ON;


----------------------------------------------------------------------------------------
---------------- ***************************************************** -----------------
----------------------------------------------------------------------------------------
DECLARE	@PID SMALLINT,
		@CID SMALLINT

SET		@PID = @PartnerID
SET		@CID = @ClubID


SELECT      c.name as ClubName
,			p.name as Retailer
,			ro.MerchantID
,			SUM(m.Amount) as TransactionAmount
,			COUNT(1) as TransactionCount
,			MIN(TransactionDate) as FirstTransaction
,			MAX(TransactionDate) as LastTransaction
INTO		#t1
FROM		SLC_Report..Partner p
	INNER JOIN SLC_Report..RetailOutlet ro
				on p.ID = ro.PartnerID
	Left Outer join SLC_Report..Match m
				ON ro.ID = m.RetailOutletID
	LEFT OUTER JOIN SLC_Report..Pan
				ON pan.id = m.panid
	LEFT OUTER JOIN SLC_Report..Fan f
				ON f.compositeid = pan.CompositeID
	LEFT OUTER JOIN SLC_Report..Club c
				ON f.clubid = c.id  and (c.ID = @CID OR @CID = 0)
WHERE		 p.ID = @PID
GROUP BY	c.Name
,			p.Name
,			ro.MerchantID


SELECT		*
FROM		#t1
ORDER BY	ClubName