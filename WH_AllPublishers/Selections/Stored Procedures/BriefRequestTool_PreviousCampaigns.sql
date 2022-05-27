/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Selections].[BriefRequestTool_PreviousCampaigns]
--WITH EXECUTE AS 'Rory'
AS
	BEGIN

		
		;WITH
		CSR_Details AS (		SELECT	DISTINCT
										LTRIM(RTRIM(PartnerName)) AS PartnerName
									,	LTRIM(RTRIM(ClientServicesRef)) AS ClientServicesRef
								FROM [Warehouse].[Selections].[AllPublisher_CampaignDetails]
								UNION
								SELECT	DISTINCT
										LTRIM(RTRIM(RetailerName)) AS PartnerName
									,	LTRIM(RTRIM(CampaignCode)) AS ClientServicesRef
								FROM [Selections].[BriefRequestTool_CampaignSetup]
								UNION
								SELECT	DISTINCT
										LTRIM(RTRIM(pa.Name)) AS PartnerName
									,	LTRIM(RTRIM(htm.ClientServicesRef)) AS ClientServicesRef
								FROM [Warehouse].[Relational].[IronOffer_Campaign_HTM] htm
								INNER JOIN [SLC_REPL].[dbo].[Partner] pa
									ON htm.PartnerID = pa.ID
								UNION
								SELECT	DISTINCT
										LTRIM(RTRIM(pa.Name)) AS PartnerName
									,	LTRIM(RTRIM(htm.ClientServicesRef)) AS ClientServicesRef
								FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] htm
								INNER JOIN [SLC_REPL].[dbo].[Partner] pa
									ON htm.PartnerID = pa.ID
								UNION
								SELECT	DISTINCT
										LTRIM(RTRIM(pa.Name)) AS PartnerName
									,	LTRIM(RTRIM(htm.ClientServicesRef)) AS ClientServicesRef
								FROM [WH_Visa].[Derived].[IronOffer_Campaign_HTM] htm
								INNER JOIN [SLC_REPL].[dbo].[Partner] pa
									ON htm.PartnerID = pa.ID
									),

		CSR_Details_Clean AS (	SELECT	csr3.PartnerName
									,	csr3.ClientServicesRef
									,	csr3.ClientServicesRef_String
									,	SUBSTRING(csr3.ClientServicesRef, csr3.CSR_FirstNumber, csr3.SecondNonNumeric - 1) AS ClientServicesRef_Number
									,	csr3.CSR_FirstNumber
									,	csr3.SecondNonNumeric
								FROM CSR_Details csr
								CROSS APPLY (	SELECT	csr.PartnerName
													,	csr.ClientServicesRef
													,	CASE
															WHEN csr.ClientServicesRef LIKE 'B52%' THEN 4
															WHEN csr.ClientServicesRef LIKE 'F21%' THEN 4
															WHEN csr.ClientServicesRef LIKE 'P4U%' THEN 4
															ELSE PATINDEX('%[0-9]%', csr.ClientServicesRef)
														END AS CSR_FirstNumber
												FROM CSR_Details csr2
												WHERE csr.ClientServicesRef = csr2.ClientServicesRef
												AND csr.PartnerName = csr2.PartnerName) csr2
								CROSS APPLY (	SELECT	csr2.PartnerName
													,	csr2.ClientServicesRef
													,	csr2.CSR_FirstNumber
													,	LEFT(ClientServicesRef, CSR_FirstNumber - 1) AS ClientServicesRef_String
													,	CASE
															WHEN PATINDEX('%[^0-9]%', SUBSTRING(csr2.ClientServicesRef, csr2.CSR_FirstNumber, 999)) = 0 THEN 999
															ELSE PATINDEX('%[^0-9]%', SUBSTRING(csr2.ClientServicesRef, csr2.CSR_FirstNumber, 999))
														END AS SecondNonNumeric
												FROM CSR_Details csr3
												WHERE csr2.ClientServicesRef = csr3.ClientServicesRef
												AND csr2.PartnerName = csr3.PartnerName) csr3
								CROSS APPLY (	SELECT	csr3.PartnerName
													,	csr3.ClientServicesRef
													,	csr3.CSR_FirstNumber
													,	csr3.ClientServicesRef_String
													,	csr3.SecondNonNumeric
												FROM CSR_Details csr4
												WHERE csr3.ClientServicesRef = csr4.ClientServicesRef
												AND csr3.PartnerName = csr4.PartnerName) csr4
								WHERE LEN(csr.ClientServicesRef) <= 7
								AND PATINDEX('%[0-9]%', csr.ClientServicesRef) > 0)

		SELECT	MAX(CASE
						WHEN PartnerName = 'Barrhead Travel (Lloyds Cardnet)' THEN 'Barrhead Travel'
						WHEN PartnerName = 'Butlins (Lloyds Cardnet)' THEN 'Butlins'
						WHEN PartnerName = 'Caffe Nero (e)' THEN 'Caffè Nero'
						WHEN PartnerName = 'Carluccios - Archive' THEN 'Carluccio''s'
						WHEN PartnerName = 'Chef & Brewer -WorldPay' THEN 'Chef & Brewer'
						WHEN PartnerName = 'Space.NK.apothecary' THEN 'Space NK'
						WHEN PartnerName = 'Office Outlet - Online Only' THEN 'Office Outlet'
						WHEN PartnerName = 'Office Outlet - Offline Only' THEN 'Office Outlet'
						WHEN PartnerName = 'Laithwaite''s Wine  -archive' THEN 'Laithwaites Wine'
						WHEN PartnerName = 'Kate Spade New York' THEN 'Kate Spade'
						WHEN PartnerName = 'Farmhouse Inns-Lloyds Cardnet (RBS)' THEN 'Farmhouse Inns'
						WHEN PartnerName = 'Flaming Grill (Cardnet)' THEN 'Flaming Grill'
						WHEN PartnerName = 'Fayre & Square  (Lloyds Cardnet)' THEN 'Fayre & Square'
						WHEN PartnerName = 'Hungry Horse (Cardnet)' THEN 'Hungry Horse'
						WHEN PartnerName = 'Hungry Horse (RBS)' THEN 'Hungry Horse'
						WHEN PartnerName = 'PAUL Patisserie' THEN 'Paul'
						WHEN PartnerName = 'Golfbreaks.com' THEN 'Golfbreaks'
						WHEN PartnerName = 'Halfords Autocentres' THEN 'Halfords'
						WHEN PartnerName = 'Matalan (Lloyds Cardnet)' THEN 'Matalan'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						WHEN PartnerName = 'xxxxxxxxx' THEN 'xxxxxxxxx'
						ELSE PartnerName
					END) AS PartnerName
			,	ClientServicesRef_String + ClientServicesRef_Number AS ClientServicesRef
			,	ClientServicesRef_String
			,	ClientServicesRef_Number
		FROM CSR_Details_Clean

		GROUP BY	ClientServicesRef_String + ClientServicesRef_Number
				,	ClientServicesRef_String
				,	ClientServicesRef_Number
		ORDER BY	1
				,	ClientServicesRef_String
				,	TRY_CONVERT(INT, ClientServicesRef_Number)
				,	ClientServicesRef_Number


	END

GO
GRANT EXECUTE
    ON OBJECT::[Selections].[BriefRequestTool_PreviousCampaigns] TO [ExcelQuery_DataOps]
    AS [dbo];

