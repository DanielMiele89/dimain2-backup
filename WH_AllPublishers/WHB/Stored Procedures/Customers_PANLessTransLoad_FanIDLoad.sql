/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [WHB].[Customers_PANLessTransLoad_FanIDLoad]
AS
	BEGIN

		INSERT INTO [Derived].[CustomerIDs]
		SELECT	PublisherID = vp.PublisherID
			,	PublisherID_RewardBI = p.PublisherID_RewardBI
			,	CustomerId = COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2))
			,	CustomerIDTypeID = 1
			,	ImportDate = MIN(pt.AddedDate)
		FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
		INNER JOIN [SLC_REPL].[dbo].[CRT_File] crt
			ON pt.FileID = crt.ID
		INNER JOIN [Report].[VectorIDToPublisherID] vp
			ON crt.VectorID = vp.VectorID
		INNER JOIN [Derived].[Publisher] p
			ON vp.PublisherID = p.PublisherID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[CustomerIDs] cu
							WHERE COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2)) = REPLACE(cu.CustomerID, '-', '')
							AND vp.PublisherID = cu.PublisherID)
		AND vp.PublisherID != 166	--	Virgin Money VGLC
		AND vp.PublisherID != 180	--	Visa Barclaycard
		AND vp.PublisherID != 182	--	Visa Barclaycard
		GROUP BY	vp.PublisherID
				,	p.PublisherID_RewardBI
				,	COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2))
			,	pt.CustomerId
		ORDER BY	vp.PublisherID
				,	p.PublisherID_RewardBI
				,	COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2))


	END