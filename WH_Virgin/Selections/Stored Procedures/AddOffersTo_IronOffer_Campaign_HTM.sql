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

DECLARE	@TableID INT = (SELECT MIN([Selections].[CampaignExecution_TableNames].[TableID]) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableIDMax INT = (SELECT MAX([Selections].[CampaignExecution_TableNames].[TableID]) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableName VARCHAR(MAX)


WHILE @TableID <= @TableIDMax
	BEGIN
		
		SELECT @TableName = [Selections].[CampaignExecution_TableNames].[TableName]
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE [Selections].[CampaignExecution_TableNames].[TableID] = @TableID

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
				INSERT INTO [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
				SELECT * 
				FROM #Offers as o
				WHERE o.IronOfferID NOT IN (SELECT DISTINCT IronOfferID FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM])'
		
		--SELECT @Qry
		exec sp_executesql @Qry
		
		SELECT @TableID = MIN([Selections].[CampaignExecution_TableNames].[TableID])
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE @TableID < [Selections].[CampaignExecution_TableNames].[TableID]

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
	FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] ht
	LEFT OUTER JOIN		(
				SELECT	p.PartnerID,
					RequiredIronOfferID,
					i.StartDate,
					i.EndDate,
					io.AboveBase,
					MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
					CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
				FROM [DIMAIN_TR].[SLC_REPL].dbo.PartnerCommissionRule p
				INNER JOIN [DIMAIN_TR].[SLC_REPL].dbo.IronOffer i
					ON i.ID = p.RequiredIronOfferID
				LEFT OUTER JOIN [WH_Virgin].[Derived].IronOffer io
					ON i.ID = io.IronOfferID
				WHERE RequiredIronOfferID IS NOT NULL
				GROUP BY p.PartnerID, RequiredIronOfferID, i.StartDate, i.EndDate, io.AboveBase
				) pcr
			ON ht.IronOfferID = PCR.RequiredIronOfferID

	--select * from #offerstats order by ironofferid

	--Update CashbackRates
	UPDATE [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
	SET	[WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[CashbackRate] =
		os.CashbackRate
	FROM #offerstats os
	INNER JOIN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] ht
		on os.IronOfferID = #offerstats.[ht].IronOfferID
	WHERE #offerstats.[ht].CashbackRate IS NULL


	--Update CommissionRates
	UPDATE [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
	SET	[WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[CommissionRate] =
		os.CommissionRate
	FROM #offerstats os
	INNER JOIN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] ht
		on os.IronOfferID = #offerstats.[ht].IronOfferID
	WHERE #offerstats.[ht].CommissionRate IS NULL



	--Update AboveBase
	UPDATE [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
	SET	[WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[AboveBase] =
		CASE	
			WHEN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[Base_CashbackRate] IS NULL THEN 1
			WHEN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[CashbackRate] > [WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[Base_CashbackRate] THEN 1
			ELSE 0
		END
	FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] 
	WHERE [WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[AboveBase] IS NULL


	--Updating isConditionalOffer
	UPDATE [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
	SET	[WH_Virgin].[Derived].[IronOffer_Campaign_HTM].[isConditionalOffer] = 1
	FROM [DIMAIN_TR].[SLC_REPL].dbo.PartnerCommissionRule pcr
	INNER JOIN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] ht
		on pcr.RequiredIronOfferID = ht.IronOfferID
	WHERE	pcr.RequiredMerchantID IS NOT NULL OR pcr.RequiredMinimumBasketSize IS NOT NULL

END

