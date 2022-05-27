/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Selections].[BriefRequestTool_UpdateRetailerDetails]
--WITH EXECUTE AS 'Rory'
AS
	BEGIN

		;WITH
		Partner AS (	SELECT	pa.ID AS PartnerID
							,	LTRIM(RTRIM(pa.Name)) AS PartnerName
						FROM /*[DIMAIN_TR].*/.[SLC_REPL].[dbo].[Partner] pa
						WHERE FanID Is NOT NULL
						AND Name != ''
						AND Name NOT LIKE '%(amex)%'
						AND Name NOT LIKE '%archive%'
						AND (		EXISTS (SELECT 1
											FROM [SLC_REPL].[dbo].[IronOffer] iof
											WHERE pa.ID = iof.PartnerID)
								OR	EXISTS (SELECT 1
											FROM /*[DIMAIN_TR].*/[SLC_REPL].[hydra].[PartnerPublisherLink] ppl
											WHERE pa.ID = ppl.PartnerID))
						AND Status = 3
					--	ORDER BY LTRIM(RTRIM(pa.Name))
						),

		PartnerDetails AS (	SELECT	pa.PartnerID
								,	pa.PartnerName
								,	CONVERT(VARCHAR(10), COALESCE(ps.Acquire, ps2.Acquire, psd.Acquire, nps.Lapsed, 12)) AS Acquire
								,	CONVERT(VARCHAR(10), COALESCE(ps.Lapsed, ps2.Lapsed, psd.Lapsed, nps.Existing, 6)) AS Lapsed
								,	CONVERT(VARCHAR(10), COALESCE(ps.Shopper, psd.Shopper, 0)) AS Shopper
							FROM Partner pa
							LEFT JOIN [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings] ps
								ON pa.PartnerID = ps.PartnerID
								AND ps.EndDate IS NULL
							LEFT JOIN [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] ps2
								ON pa.PartnerID = ps2.PartnerID
								AND ps2.EndDate IS NULL
							LEFT JOIN [Warehouse].[Segmentation].[PartnerSettings_DD] psd
								ON pa.PartnerID = psd.PartnerID
								AND psd.EndDate IS NULL
							LEFT JOIN [nFI].[Segmentation].[PartnerSettings] nps
								ON pa.PartnerID = nps.PartnerID
								AND nps.EndDate IS NULL),

		Override AS (	SELECT	rct.PartnerID
							,	MAX(Override) AS Override
						FROM [Derived].[RetailerCommercialTerms] rct
						WHERE rct.EndDate IS NULL
						GROUP BY rct.PartnerID),

		RetailerDetails AS (SELECT	pd.PartnerID
								,	CASE
										WHEN pd.PartnerName = 'Barrhead Travel (Lloyds Cardnet)' THEN 'Barrhead Travel'
										WHEN pd.PartnerName = 'Butlins (Lloyds Cardnet)' THEN 'Butlins'
										WHEN pd.PartnerName = 'Caffe Nero (e)' THEN 'Caffè Nero'
										WHEN pd.PartnerName = 'Carluccios - Archive' THEN 'Carluccio''s'
										WHEN pd.PartnerName = 'Chef & Brewer -WorldPay' THEN 'Chef & Brewer'
										WHEN pd.PartnerName = 'Space.NK.apothecary' THEN 'Space NK'
										WHEN pd.PartnerName = 'Office Outlet - Online Only' THEN 'Office Outlet'
										WHEN pd.PartnerName = 'Office Outlet - Offline Only' THEN 'Office Outlet'
										WHEN pd.PartnerName = 'Laithwaite''s Wine  -archive' THEN 'Laithwaites Wine'
										WHEN pd.PartnerName = 'Kate Spade New York' THEN 'Kate Spade'
										WHEN pd.PartnerName = 'Farmhouse Inns-Lloyds Cardnet (RBS)' THEN 'Farmhouse Inns'
										WHEN pd.PartnerName = 'Flaming Grill (Cardnet)' THEN 'Flaming Grill'
										WHEN pd.PartnerName = 'Fayre & Square  (Lloyds Cardnet)' THEN 'Fayre & Square'
										WHEN pd.PartnerName = 'Hungry Horse (Cardnet)' THEN 'Hungry Horse'
										WHEN pd.PartnerName = 'Hungry Horse (RBS)' THEN 'Hungry Horse'
										WHEN pd.PartnerName = 'PAUL Patisserie' THEN 'Paul'
										WHEN pd.PartnerName = 'Golfbreaks.com' THEN 'Golfbreaks'
										WHEN pd.PartnerName = 'Halfords Autocentres' THEN 'Halfords'
										WHEN pd.PartnerName = 'Matalan (Lloyds Cardnet)' THEN 'Matalan'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										WHEN pd.PartnerName = 'xxxxxxxxxxx' THEN 'xxxxxxxxxxx'
										ELSE pd.PartnerName
									END AS PartnerName
								,	AcquireDef = 'Last shopped over ' + pd.Acquire + ' months ago, or never shopped'
								,	LapsedDef = 'Last shopped between ' + pd.Lapsed + ' and ' + pd.Acquire + ' months ago'
								,	ShopperDef = 'Last shopped in the last ' + pd.Lapsed + ' months'
								,	pd.Acquire
								,	pd.Lapsed
								,	pd.Shopper
								,	o.Override
							FROM PartnerDetails pd
							LEFT JOIN Override o
								ON pd.PartnerID = o.PartnerID)
								
		SELECT	COALESCE(pa.PartnerID, rd.PartnerID) AS PartnerID
			,	rd.PartnerName
			,	rd.AcquireDef
			,	rd.LapsedDef
			,	rd.ShopperDef
			,	rd.Acquire
			,	rd.Lapsed
			,	rd.Shopper
			,	MAX(rd.Override) AS Override
		FROM RetailerDetails rd
		LEFT JOIN Partner pa
			ON rd.PartnerName = pa.PartnerName
		WHERE rd.PartnerID NOT IN (4642, 4615, 4521, 4497, 4535, 4555, 4648, 4488, 4782, 4498, 4716, 4527)
		GROUP BY	COALESCE(pa.PartnerID, rd.PartnerID)
				,	rd.PartnerName
				,	rd.AcquireDef
				,	rd.LapsedDef
				,	rd.ShopperDef
				,	rd.Acquire
				,	rd.Lapsed
				,	rd.Shopper
		ORDER BY rd.PartnerName


		
			
	END

GO
GRANT EXECUTE
    ON OBJECT::[Selections].[BriefRequestTool_UpdateRetailerDetails] TO [ExcelQuery_DataOps]
    AS [dbo];

