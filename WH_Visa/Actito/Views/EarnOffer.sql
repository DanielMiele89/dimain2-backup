
CREATE VIEW [Actito].[EarnOffer]
AS

WITH
Customers AS (	
				SELECT	[FanID]
					,	CASE
							WHEN [MarketableByEmail] = 0 OR [CurrentlyActive] = 0 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [Email].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Email].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)
			--	AND 1 = 2
				),

Samples AS (	
				SELECT	[FanID]
					,	[ID]
				FROM [Email].[SampleCustomersList] scl
				WHERE 1 = 1
				),

OPE AS (	SELECT	PartnerID
				,	IronOfferID
				,	HydraOfferID
				,	CustomerNum
				,	ROW_NUMBER() OVER (PARTITION BY CustomerNum ORDER BY (SELECT NULL)) AS RowNum
			FROM (	SELECT	PartnerID
						,	IronOfferID
						,	HydraOfferID
						,	(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) / 7 AS CustomerNum
					FROM (	SELECT	op.PartnerID
								,	op.IronOfferID
								,	op.Weighting
								,	iof.HydraOfferID
								,	ROW_NUMBER() OVER (PARTITION BY op.PartnerID ORDER BY Weighting DESC) AS PartnerRank
							FROM [Email].[Newsletter_OfferPrioritisation] op
							INNER JOIN [Derived].[IronOffer] iof
								ON op.IronOfferID = iof.IronOfferID
							WHERE EmailDate = (SELECT MAX(EmailDate) FROM [Email].[Newsletter_OfferPrioritisation] WHERE EmailDate < GETDATE())) a
					WHERE PartnerRank = 1) a),

AllCycleDates AS (		
				SELECT	[CycleID]
					,	[StartDate]
					,	[EndDate] = DATEADD(DAY, -14, [EndDate])
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd
				WHERE StartDate < GETDATE()										--	To remove after 26/05/22
				UNION
				SELECT	[CycleID]
					,	[StartDate] = DATEADD(DAY, 14, [StartDate])
					,	[EndDate]
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd2	
				WHERE DATEADD(DAY, 14, [StartDate]) < GETDATE()					--	To remove after 26/05/22
				),

CycleDates AS (
				SELECT	MIN(StartDate) AS StartDate
					,	MIN(EndDate) AS EndDate
				FROM AllCycleDates
		--		WHERE CONVERT(DATE, GETDATE()) <= StartDate						--	To uncomment after 26/05/22
				WHERE CONVERT(DATE, DATEADD(DAY, -10, GETDATE())) <= StartDate						--	To remove after 26/05/22
				)

SELECT	[FanID] = cu.[FanID]	-- Earn Offer
	,	[EmailSendID] = COALESCE(CASE WHEN [ToBeEmailed] = 0 THEN 0 ELSE osd.[LionSendID] END, '')
	,	[EmailSendName] = ''

	,	[EarnOfferID_Hero] =	COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_Hero]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_1] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_1]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_2] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_2]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_3] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_3]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_4] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_4]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_5] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_5]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_6] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_6]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_7] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_7]), '0B728533-1C89-44A3-B70A-1B894389C09F')
	,	[EarnOfferID_8] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_8]), '0B728533-1C89-44A3-B70A-1B894389C09F')

	,	[EarnOfferStartDate_Hero] =	CASE
										WHEN osd.[OfferStartDate_Hero] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_Hero] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_Hero]
									END
	,	[EarnOfferStartDate_1] =	CASE
										WHEN osd.[OfferStartDate_1] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_1] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_1]
									END
	,	[EarnOfferStartDate_2] =	CASE
										WHEN osd.[OfferStartDate_2] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_2] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_2]
									END
	,	[EarnOfferStartDate_3] =	CASE
										WHEN osd.[OfferStartDate_3] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_3] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_3]
									END
	,	[EarnOfferStartDate_4] =	CASE
										WHEN osd.[OfferStartDate_4] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_4] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_4]
									END
	,	[EarnOfferStartDate_5] =	CASE
										WHEN osd.[OfferStartDate_5] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_5] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_5]
									END
	,	[EarnOfferStartDate_6] =	CASE
										WHEN osd.[OfferStartDate_6] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_6] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_6]
									END
	,	[EarnOfferStartDate_7] =	CASE
										WHEN osd.[OfferStartDate_7] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_7] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_7]
									END
	,	[EarnOfferStartDate_8] =	CASE
										WHEN osd.[OfferStartDate_8] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_8] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_8]
									END

	,	[EarnOfferEndDate_Hero] =	(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_Hero] <=		acd.[EndDate])
	,	[EarnOfferEndDate_1] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_1] <=		acd.[EndDate])
	,	[EarnOfferEndDate_2] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_2] <=		acd.[EndDate])
	,	[EarnOfferEndDate_3] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_3] <=		acd.[EndDate])
	,	[EarnOfferEndDate_4] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_4] <=		acd.[EndDate])
	,	[EarnOfferEndDate_5] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_5] <=		acd.[EndDate])
	,	[EarnOfferEndDate_6] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_6] <=		acd.[EndDate])
	,	[EarnOfferEndDate_7] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_7] <=		acd.[EndDate])
	,	[EarnOfferEndDate_8] =		(SELECT MIN([EndDate])		FROM AllCycleDates acd WHERE osd.[OfferEndDate_8] <=		acd.[EndDate])
FROM Customers cu
LEFT JOIN [Email].[OfferSlotData] osd
	ON osd.[FanID] = cu.[FanID]

UNION ALL
				
SELECT	[FanID] = sa.[FanID]	-- Earn Offer
	,	[EmailSendID] = COALESCE(osd.[LionSendID], '')
	,	[EmailSendName] = ''

	,	[EarnOfferID_Hero] =	CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_Hero]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 1), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 1)))
	,	[EarnOfferID_1] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_1]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 2), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 2)))
	,	[EarnOfferID_2] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_2]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 3), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 3)))
	,	[EarnOfferID_3] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_3]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 4), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 4)))
	,	[EarnOfferID_4] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_4]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 5), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 5)))
	,	[EarnOfferID_5] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_5]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 6), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 6)))
	,	[EarnOfferID_6] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_6]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 7), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 7)))
	,	[EarnOfferID_7] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_7]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 8), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 8)))
	,	[EarnOfferID_8] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_8]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 9), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 9)))
		
	,	[EarnOfferStartDate_Hero] =	CASE
										WHEN osd.[OfferStartDate_Hero] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_Hero] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_Hero]
									END
	,	[EarnOfferStartDate_1] =	CASE
										WHEN osd.[OfferStartDate_1] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_1] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_1]
									END
	,	[EarnOfferStartDate_2] =	CASE
										WHEN osd.[OfferStartDate_2] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_2] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_2]
									END
	,	[EarnOfferStartDate_3] =	CASE
										WHEN osd.[OfferStartDate_3] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_3] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_3]
									END
	,	[EarnOfferStartDate_4] =	CASE
										WHEN osd.[OfferStartDate_4] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_4] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_4]
									END
	,	[EarnOfferStartDate_5] =	CASE
										WHEN osd.[OfferStartDate_5] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_5] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_5]
									END
	,	[EarnOfferStartDate_6] =	CASE
										WHEN osd.[OfferStartDate_6] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_6] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_6]
									END
	,	[EarnOfferStartDate_7] =	CASE
										WHEN osd.[OfferStartDate_7] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_7] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_7]
									END
	,	[EarnOfferStartDate_8] =	CASE
										WHEN osd.[OfferStartDate_8] < (SELECT [StartDate] FROM CycleDates) THEN (SELECT [StartDate] FROM CycleDates)
										WHEN osd.[OfferStartDate_8] IS NULL THEN (SELECT [StartDate] FROM CycleDates)
										ELSE osd.[OfferStartDate_8]
									END

	,	[EarnOfferEndDate_Hero] =	COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_Hero] <= acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_1] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_1] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_2] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_2] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_3] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_3] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_4] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_4] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_5] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_5] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_6] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_6] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_7] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_7] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
	,	[EarnOfferEndDate_8] =		COALESCE((SELECT MIN([EndDate]) FROM AllCycleDates acd WHERE osd.[OfferEndDate_8] <=	acd.[EndDate]),	(SELECT [EndDate] FROM CycleDates))
FROM Samples sa
LEFT JOIN [Email].[OfferSlotData] osd
	ON osd.[FanID] = sa.[FanID]

--GO


