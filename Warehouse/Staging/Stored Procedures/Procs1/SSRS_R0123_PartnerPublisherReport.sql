

-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 11/05/2016
-- Description: 
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0123_PartnerPublisherReport](
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


SELECT      Case
				When @CID = 0 Then 'All'
				Else c.name
			End as ClubName
,			p.name as Retailer
,			m.MerchantID
,			SUM(m.Amount) as TransactionAmount
,			COUNT(1) as TransactionCount
,			MIN(TransactionDate) as FirstTransaction
,			MAX(TransactionDate) as LastTransaction
INTO		#t1
FROM		SLC_Report..Match m
	INNER JOIN	SLC_Report..TransactionVector tv
				ON m.VectorID = tv.ID
	INNER JOIN SLC_Report..RetailOutlet ro
				ON m.RetailOutletID = ro.ID
	INNER JOIN SLC_Report..Partner p
				ON ro.PartnerID = p.ID
	LEFT OUTER JOIN SLC_Report..Pan
				ON pan.id = m.panid
	LEFT OUTER JOIN SLC_Report..Fan f
				ON f.compositeid = pan.CompositeID
	LEFT OUTER JOIN SLC_Report..Club c
				ON f.clubid = c.id
WHERE		 p.ID = @PID
	AND		(c.ID = @CID OR @CID = 0)
GROUP BY	p.Name
,			m.MerchantID
,			Case
				When @CID = 0 Then 'All'
				Else c.name
			End 


SELECT		*
FROM		#t1
ORDER BY	ClubName