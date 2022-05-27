/******************************************************************************
PROCESS NAME: Offer Reporting - Duplicate PartnerAlternate

Author	  Jason Shipp
Created	  06/11/2017
Purpose	  Fetch distinct AlternatePartnerIDs from the APW.PartnerAlternate tables in both Warhouse and nFI
	  
Copyright © 2017, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History
******************************************************************************/

CREATE PROCEDURE [Staging].[OfferReport_Fetch_PartnerAlternate]
AS
BEGIN
     SET NOCOUNT ON;

	SELECT	DISTINCT
			PartnerID
		,	AlternatePartnerID
	FROM (	SELECT	PartnerID
				,	AlternatePartnerID
			FROM [Warehouse].[APW].[PartnerAlternate]
			UNION
			SELECT	PartnerID
				,	AlternatePartnerID
			FROM [nFI].[APW].[PartnerAlternate]) pa;

END