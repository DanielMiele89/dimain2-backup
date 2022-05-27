/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[PANLessTransLoad_FanIDLoad]
AS
	BEGIN

		INSERT INTO [Derived].[CustomerIDs]
		SELECT	vp.PublisherID
			,	p.PublisherID_RewardBI
			,	pt.CustomerId
			,	1 AS CustomerIDTypeID
			,	MIN(pt.AddedDate) AS ImportDate
		FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
		INNER JOIN [SLC_REPL].[dbo].[CRT_File] crt
			ON pt.FileID = crt.ID
		INNER JOIN [SLC_REPL].[dbo].[TransactionVector] tv
			ON crt.VectorID = tv.ID
		INNER JOIN [Report].[VectorIDToPublisherID] vp
			ON crt.VectorID = vp.VectorID
		LEFT JOIN [Report].[Publishers] p
			ON vp.PublisherID = p.PublisherID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[CustomerIDs] cu
							WHERE pt.CustomerId = cu.CustomerID
							AND vp.PublisherID = cu.PublisherID
							AND cu.CustomerIDTypeID = 1)
		AND EXISTS (		SELECT 1
							FROM [Report].[NegativeFanIDs_VectorIDs] nf
							WHERE crt.VectorID = nf.VectorID)
		AND pt.CustomerId NOT LIKE '%+%'
		GROUP BY vp.PublisherID
			,	p.PublisherID_RewardBI
			,	pt.CustomerId

	END