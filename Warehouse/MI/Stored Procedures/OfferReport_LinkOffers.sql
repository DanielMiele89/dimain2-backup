
/******************************************************************************
PROCESS NAME: Offer Calculation - Link Offers Across Publishers
PID: OC-003

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Generates a table that links similar IronOffers by the attributes of the offer
		  across publishers (such as Spend Stretch, Cashback Rate, Targeted Customer Group etc).
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/

CREATE PROCEDURE [MI].[OfferReport_LinkOffers] 
AS
BEGIN

    SET NOCOUNT ON

    -- Get distinct list of offer attributes that have not been seen before
    -- This table acts as a map for OfferIDs with the Primary Key being the OfferID       
    INSERT INTO Sandbox.Hayden.OfferAttributes
    SELECT DISTINCT CycleID, ShopperSegmentTypeID, OfferTypeID, PartnerID, SpendStretch, CashbackRate FROM Sandbox.Hayden.IronOffer_Refrences r
    WHERE NOT EXISTS (
	   SELECT 1 FROM Sandbox.Hayden.OfferAttributes oa
	   WHERE oa.CycleID = r.CycleID
		  AND oa.ShopperSegmentTypeID = r.ShopperSegmentTypeID
		  AND oa.OfferTypeID = r.OfferTypeID
		  AND oa.PartnerID = r.PartnerID
		  AND oa.SpendStretch = r.SpendStretch
		  AND oa.CashbackRate = r.CashbackRate
    )

    -- Uses the offer attributes to identify which offers are similar and stamps the OfferID to each IronOfferID
    INSERT INTO Sandbox.Hayden.OfferLinks
    SELECT s.ID, IronOfferID FROM Sandbox.Hayden.OfferAttributes s
    JOIN Sandbox.Hayden.IronOffer_Refrences r ON 
	   r.CycleID = s.CycleID
	   AND r.ShopperSegmentTypeID = s.ShopperSegmentTypeID
	   AND r.OfferTypeID = s.OfferTypeID
	   AND r.PartnerID = s.PartnerID
	   AND r.SpendStretch = s.SpendStretch
	   AND r.CashbackRate = s.CashbackRate
    WHERE NOT EXISTS (
	   SELECT 1 FROM Sandbox.Hayden.OfferLinks l
	   WHERE l.IronOfferID = r.IronOfferID
    )

END