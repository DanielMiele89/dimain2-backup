/*
Author:		Suraj Chahal
Date:		29/08/2013
Purpose:	Run subsequent to IronOfferMember Populated to pull through extra information:
				a). HTM - For which headroom segment the offer is reffering to; this is NULL for universal offers
				b). ClientServicesRef - Used to group offers together
		This data will be used later to work out if offers or above or equal to base offer rates

*/

CREATE PROCEDURE [Selections].[AddOffersTo_IronOffer_Campaign_HTM]

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Qry NVARCHAR(MAX)

DECLARE	@TableID INT = (SELECT MIN(TableID) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableIDMax INT = (SELECT MAX(TableID) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableName VARCHAR(MAX)


WHILE @TableID <= @TableIDMax
	BEGIN
		
		SELECT @TableName = TableName
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE TableID = @TableID

		SET @Qry =	'IF OBJECT_ID(''tempdb..#Offers'') IS NOT NULL DROP TABLE #Offers
				SELECT	DISTINCT
					ClientServicesRef,
					PartnerID,
					NULL					as EPOCU,
					NULL					as HTMSegment,
					OfferID					as IronOfferID,
					NULL					as CashBackRate,
					NULL					as CommissionRate,
					NULL					as BaseOfferID,
					NULL					as Base_CashbackRate,
					NULL					as Base_CommissionRate,
					NULL					as AboveBase,
					0					as isConditionalOffer
				INTO #Offers
				FROM' +' '+ @Tablename 
				+' 
				ORDER BY IronOfferID
				'+
				'
				INSERT INTO [Derived].[IronOffer_Campaign_HTM]
				SELECT * 
				FROM #Offers as o
				WHERE o.IronOfferID NOT IN (SELECT DISTINCT IronOfferID FROM [Derived].[IronOffer_Campaign_HTM])'
		
		--SELECT @Qry
		exec sp_executesql @Qry
		
		SELECT @TableID = MIN(TableID)
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE @TableID < TableID

	END

	IF OBJECT_ID ('tempdb..#OfferStats') IS NOT NULL DROP TABLE #OfferStats
	SELECT 	ht.ClientServicesRef,
		pcr.PartnerID,
		ht.EPOCU, 
		ht.HTMSegment, 
		ht.IronOfferID,
		pcr.CashbackRate,
		pcr.CommissionRate,
		pcr.AboveBase
	INTO #OfferStats
	FROM [Derived].[IronOffer_Campaign_HTM] ht
	LEFT OUTER JOIN	(	SELECT	p.PartnerID
							,	i.IronOfferID
							,	i.StartDate
							,	i.EndDate
							,	io.AboveBase
							,	MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate
							,	CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
						FROM [Derived].[IronOffer_PartnerCommissionRule] p
						INNER JOIN [Derived].[IronOffer] i
							ON i.IronOfferID = p.IronOfferID
						LEFT OUTER JOIN [Derived].[IronOffer] io
							ON i.IronOfferID = io.IronOfferID
						WHERE i.IronOfferID IS NOT NULL
						GROUP BY p.PartnerID, i.IronOfferID, i.StartDate, i.EndDate, io.AboveBase
				) pcr
			ON ht.IronOfferID = PCR.IronOfferID

	--select * from #offerstats order by ironofferid

	--Update CashbackRates
	UPDATE [Derived].[IronOffer_Campaign_HTM]
	SET	CashbackRate =
		os.CashbackRate
	FROM #offerstats os
	INNER JOIN [Derived].[IronOffer_Campaign_HTM] ht
		on os.IronOfferID = ht.IronOfferID
	WHERE ht.CashbackRate IS NULL


	--Update CommissionRates
	UPDATE [Derived].[IronOffer_Campaign_HTM]
	SET	CommissionRate =
		os.CommissionRate
	FROM #offerstats os
	INNER JOIN [Derived].[IronOffer_Campaign_HTM] ht
		on os.IronOfferID = ht.IronOfferID
	WHERE ht.CommissionRate IS NULL



	--Update AboveBase
	UPDATE [Derived].[IronOffer_Campaign_HTM]
	SET	AboveBase =
		CASE	
			WHEN Base_CashbackRate IS NULL THEN 1
			WHEN CashbackRate > Base_CashbackRate THEN 1
			ELSE 0
		END
	FROM [Derived].[IronOffer_Campaign_HTM] 
	WHERE AboveBase IS NULL


	--Updating isConditionalOffer
	UPDATE [Derived].[IronOffer_Campaign_HTM]
	SET	isConditionalOffer = 1
	FROM [Derived].[IronOffer_PartnerCommissionRule] pcr
	INNER JOIN [Derived].[IronOffer_Campaign_HTM] ht
		on pcr.IronOfferID = ht.IronOfferID
	WHERE	pcr.MinimumBasketSize IS NOT NULL

END

