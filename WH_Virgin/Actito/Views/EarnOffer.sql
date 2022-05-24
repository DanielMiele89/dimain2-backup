


CREATE VIEW [Actito].[EarnOffer]
AS

WITH
Customers AS (	
				SELECT	FanID
					,	CASE
							WHEN MarketableByEmail = 0 OR CurrentlyActive = 0 THEN 0
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
				SELECT	FanID
					,	ID
				FROM [Email].[SampleCustomersList] slc
				WHERE 1 = 1
				AND ID <= 750
				),

OPE AS (	SELECT	a.PartnerID
				,	iof.HydraOfferID
				,	a.CustomerNum
				,	ROW_NUMBER() OVER (PARTITION BY a.CustomerNum ORDER BY (SELECT NULL)) AS RowNum
			FROM (	SELECT	PartnerID
						,	IronOfferID
						,	(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) / 9 AS CustomerNum
					FROM (	SELECT	*
								,	ROW_NUMBER() OVER (PARTITION BY PartnerID ORDER BY Weighting DESC) AS PartnerRank
							FROM Email.Newsletter_OfferPrioritisation
							WHERE EmailDate = (SELECT MAX(EmailDate) FROM Email.Newsletter_OfferPrioritisation WHERE EmailDate < GETDATE())) a
					WHERE PartnerRank = 1) a
			INNER JOIN [Derived].[IronOffer] iof
				ON a.IronOfferID = iof.IronOfferID),

AllCycleDates AS (		
				SELECT	CycleID
					,	StartDate
					,	DATEADD(DAY, -14, EndDate) AS EndDate
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd
				UNION
				SELECT	CycleID
					,	DATEADD(DAY, 14, StartDate) AS StartDate
					,	EndDate
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd2				
				),

CycleDates AS (
				SELECT	MIN(StartDate) AS StartDate
					,	MIN(EndDate) AS EndDate
				FROM AllCycleDates
				WHERE CONVERT(DATE, GETDATE()) <= StartDate
				)

SELECT	FanID = cu.FanID	-- Earn Offer
	,	EmailSendID = COALESCE(CASE WHEN ToBeEmailed = 0 THEN 0 ELSE osd.[LionSendID] END, '')
	,	EmailSendName = ''
	
	,	[EarnOfferID_Hero] =	COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_Hero]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_1] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_1]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_2] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_2]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_3] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_3]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_4] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_4]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_5] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_5]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_6] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_6]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_7] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_7]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')
	,	[EarnOfferID_8] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[HydraOfferID]) FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_8]), '7130E152-A5EB-4F9D-AA60-085B8CC6326F')

	,	EarnOfferStartDate_Hero =	CONVERT(DATE, COALESCE([OfferStartDate_Hero],	''))
	,	EarnOfferStartDate_1 =		CONVERT(DATE, COALESCE([OfferStartDate_1],		''))
	,	EarnOfferStartDate_2 =		CONVERT(DATE, COALESCE([OfferStartDate_2],		''))
	,	EarnOfferStartDate_3 =		CONVERT(DATE, COALESCE([OfferStartDate_3],		''))
	,	EarnOfferStartDate_4 =		CONVERT(DATE, COALESCE([OfferStartDate_4],		''))
	,	EarnOfferStartDate_5 =		CONVERT(DATE, COALESCE([OfferStartDate_5],		''))
	,	EarnOfferStartDate_6 =		CONVERT(DATE, COALESCE([OfferStartDate_6],		''))
	,	EarnOfferStartDate_7 =		CONVERT(DATE, COALESCE([OfferStartDate_7],		''))
	,	EarnOfferStartDate_8 =		CONVERT(DATE, COALESCE([OfferStartDate_8],		''))
	
	,	EarnOfferEndDate_Hero =	COALESCE([OfferEndDate_Hero],	'')
	,	EarnOfferEndDate_1 =	COALESCE([OfferEndDate_1],		'')
	,	EarnOfferEndDate_2 =	COALESCE([OfferEndDate_2],		'')
	,	EarnOfferEndDate_3 =	COALESCE([OfferEndDate_3],		'')
	,	EarnOfferEndDate_4 =	COALESCE([OfferEndDate_4],		'')
	,	EarnOfferEndDate_5 =	COALESCE([OfferEndDate_5],		'')
	,	EarnOfferEndDate_6 =	COALESCE([OfferEndDate_6],		'')
	,	EarnOfferEndDate_7 =	COALESCE([OfferEndDate_7],		'')
	,	EarnOfferEndDate_8 =	COALESCE([OfferEndDate_8],		'')
FROM Customers cu
LEFT JOIN [Email].[OfferSlotData] osd
	ON cu.FanID = osd.FanID
	
UNION ALL

SELECT	FanID = sa.FanID	-- Earn Offer
	,	EmailSendID = COALESCE(osd.[LionSendID], '')
	,	EmailSendName = ''

	,	[EarnOfferID_Hero] =	CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_Hero]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 1), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 1)))
	,	[EarnOfferID_1] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_1]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 2), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 2)))
	,	[EarnOfferID_2] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_2]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 3), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 3)))
	,	[EarnOfferID_3] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_3]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 4), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 4)))
	,	[EarnOfferID_4] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_4]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 5), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 5)))
	,	[EarnOfferID_5] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_5]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 6), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 6)))
	,	[EarnOfferID_6] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_6]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 7), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 7)))
	,	[EarnOfferID_7] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_7]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 8), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 8)))
	,	[EarnOfferID_8] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[HydraOfferID] FROM [Derived].[IronOffer] iof WHERE iof.[IronOfferID] = osd.[OfferID_8]),	(SELECT HydraOfferID FROM OPE WHERE sa.ID % 9 = OPE.CustomerNum AND ope.RowNum = 9), (SELECT HydraOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 9)))

	
	,	EarnOfferStartDate_Hero =	CONVERT(DATE, COALESCE([OfferStartDate_Hero],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_1 =		CONVERT(DATE, COALESCE([OfferStartDate_1],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_2 =		CONVERT(DATE, COALESCE([OfferStartDate_2],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_3 =		CONVERT(DATE, COALESCE([OfferStartDate_3],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_4 =		CONVERT(DATE, COALESCE([OfferStartDate_4],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_5 =		CONVERT(DATE, COALESCE([OfferStartDate_5],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_6 =		CONVERT(DATE, COALESCE([OfferStartDate_6],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_7 =		CONVERT(DATE, COALESCE([OfferStartDate_7],		(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_8 =		CONVERT(DATE, COALESCE([OfferStartDate_8],		(SELECT StartDate FROM CycleDates)))
	
	,	EarnOfferEndDate_Hero =	COALESCE([OfferEndDate_Hero],	(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_1 =	COALESCE([OfferEndDate_1],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_2 =	COALESCE([OfferEndDate_2],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_3 =	COALESCE([OfferEndDate_3],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_4 =	COALESCE([OfferEndDate_4],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_5 =	COALESCE([OfferEndDate_5],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_6 =	COALESCE([OfferEndDate_6],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_7 =	COALESCE([OfferEndDate_7],		(SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_8 =	COALESCE([OfferEndDate_8],		(SELECT EndDate FROM CycleDates))
FROM Samples sa
LEFT JOIN [Email].[OfferSlotData] osd
	ON sa.FanID = osd.FanID


GO
DENY SELECT
    ON OBJECT::[Actito].[EarnOffer] TO [New_Insight]
    AS [dbo];

