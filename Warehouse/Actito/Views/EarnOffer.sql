

CREATE VIEW [Actito].[EarnOffer]
AS

WITH
Customers AS (	
				SELECT	[FanID]
					,	CASE
							WHEN [MarketableByEmail] = 0 OR [CurrentlyActive] = 0 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Warehouse].[Relational].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [SmartEmail].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Warehouse].[SmartEmail].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)
								
				),

Samples AS (	
				SELECT	FanID
					,	ID
				FROM [Warehouse].[SmartEmail].[SampleCustomersList] slc
				WHERE 1 = 1
				),

OPE AS (	SELECT	PartnerID
				,	IronOfferID
				,	CustomerNum
				,	ROW_NUMBER() OVER (PARTITION BY CustomerNum ORDER BY (SELECT NULL)) AS RowNum
			FROM (	SELECT	PartnerID
						,	IronOfferID
						,	(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) / 7 AS CustomerNum
					FROM (	SELECT	*
								,	ROW_NUMBER() OVER (PARTITION BY PartnerID ORDER BY Weighting DESC) AS PartnerRank
							FROM [Selections].[OfferPrioritisation]
							WHERE EmailDate = (SELECT MAX(EmailDate) FROM [Selections].[OfferPrioritisation])) a) a),

AllCycleDates AS (		
				SELECT	CycleID
					,	StartDate
					,	DATEADD(DAY, -14, EndDate) AS EndDate
				FROM [Relational].[ROC_CycleDates] cd
				UNION
				SELECT	CycleID
					,	DATEADD(DAY, 14, StartDate) AS StartDate
					,	EndDate
				FROM [Relational].[ROC_CycleDates] cd2				
				),

CycleDates AS (
				SELECT	MIN(StartDate) AS StartDate
					,	MIN(EndDate) AS EndDate
				FROM AllCycleDates
				WHERE CONVERT(DATE, GETDATE()) <= StartDate
				)

SELECT	FanID = cu.FanID	-- Earn Offer
	,	[EmailSendID] = COALESCE(CASE WHEN [ToBeEmailed] = 0 THEN 0 ELSE osd.[LionSendID] END, '')
	,	EmailSendName = ''

	,	EarnOfferID_Hero =	COALESCE([Offer7], 8495)
	,	EarnOfferID_1 =		COALESCE([Offer1], 8495)
	,	EarnOfferID_2 =		COALESCE([Offer2], 8495)
	,	EarnOfferID_3 =		COALESCE([Offer3], 8495)
	,	EarnOfferID_4 =		COALESCE([Offer4], 8495)
	,	EarnOfferID_5 =		COALESCE([Offer5], 8495)
	,	EarnOfferID_6 =		COALESCE([Offer6], 8495)
	,	EarnOfferID_7 =		CAST('' AS INT)
	,	EarnOfferID_8 =		CAST('' AS INT)
	
	,	EarnOfferStartDate_Hero =	CONVERT(DATE, CASE WHEN [Offer7] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer7StartDate], '') END)
	,	EarnOfferStartDate_1 =		CONVERT(DATE, CASE WHEN [Offer1] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer1StartDate], '') END)
	,	EarnOfferStartDate_2 =		CONVERT(DATE, CASE WHEN [Offer2] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer2StartDate], '') END)
	,	EarnOfferStartDate_3 =		CONVERT(DATE, CASE WHEN [Offer3] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer3StartDate], '') END)
	,	EarnOfferStartDate_4 =		CONVERT(DATE, CASE WHEN [Offer4] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer4StartDate], '') END)
	,	EarnOfferStartDate_5 =		CONVERT(DATE, CASE WHEN [Offer5] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer5StartDate], '') END)
	,	EarnOfferStartDate_6 =		CONVERT(DATE, CASE WHEN [Offer6] = 8495 THEN (SELECT StartDate FROM CycleDates) ELSE COALESCE([Offer6StartDate], '') END)
	,	EarnOfferStartDate_7 =		CONVERT(DATE, '')
	,	EarnOfferStartDate_8 =		CONVERT(DATE, '')
	
	,	EarnOfferEndDate_Hero =	COALESCE([Offer7EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_1 =	COALESCE([Offer1EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_2 =	COALESCE([Offer2EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_3 =	COALESCE([Offer3EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_4 =	COALESCE([Offer4EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_5 =	COALESCE([Offer5EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_6 =	COALESCE([Offer6EndDate], (SELECT EndDate FROM CycleDates))
	,	EarnOfferEndDate_7 =	CAST('' AS DATE)
	,	EarnOfferEndDate_8 =	CAST('' AS DATE)
FROM Customers cu
LEFT JOIN [Warehouse].[SmartEmail].[OfferSlotData] osd
	ON cu.FanID = osd.FanID

UNION ALL

SELECT	sa.FanID
	,	EmailSendID = COALESCE(LionSendID, '')
	,	EmailSendName = ''
	
	,	EarnOfferID_Hero =	COALESCE([Offer7],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 1), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 1))
	,	EarnOfferID_1 =		COALESCE([Offer1],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 2), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 2))
	,	EarnOfferID_2 =		COALESCE([Offer2],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 3), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 3))
	,	EarnOfferID_3 =		COALESCE([Offer3],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 4), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 4))
	,	EarnOfferID_4 =		COALESCE([Offer4],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 5), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 5))
	,	EarnOfferID_5 =		COALESCE([Offer5],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 6), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 6))
	,	EarnOfferID_6 =		COALESCE([Offer6],	(SELECT IronOfferID FROM OPE WHERE sa.ID % 7 = OPE.CustomerNum AND ope.RowNum = 7), (SELECT IronOfferID FROM OPE WHERE 0 = OPE.CustomerNum AND ope.RowNum = 7))
	,	EarnOfferID_7 =		CAST('' AS INT)
	,	EarnOfferID_8 =		CAST('' AS INT)
	
	,	EarnOfferStartDate_Hero =	CONVERT(DATE, COALESCE([Offer7StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_1 =		CONVERT(DATE, COALESCE([Offer1StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_2 =		CONVERT(DATE, COALESCE([Offer2StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_3 =		CONVERT(DATE, COALESCE([Offer3StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_4 =		CONVERT(DATE, COALESCE([Offer4StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_5 =		CONVERT(DATE, COALESCE([Offer5StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_6 =		CONVERT(DATE, COALESCE([Offer6StartDate],	(SELECT StartDate FROM CycleDates)))
	,	EarnOfferStartDate_7 =		CONVERT(DATE, '')
	,	EarnOfferStartDate_8 =		CONVERT(DATE, '')
	
	,	EarnOfferEndDate_Hero =	CONVERT(DATE, COALESCE([Offer7EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_1 =	CONVERT(DATE, COALESCE([Offer1EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_2 =	CONVERT(DATE, COALESCE([Offer2EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_3 =	CONVERT(DATE, COALESCE([Offer3EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_4 =	CONVERT(DATE, COALESCE([Offer4EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_5 =	CONVERT(DATE, COALESCE([Offer5EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_6 =	CONVERT(DATE, COALESCE([Offer6EndDate],	(SELECT EndDate FROM CycleDates)))
	,	EarnOfferEndDate_7 =	CONVERT(DATE, '')
	,	EarnOfferEndDate_8 =	CONVERT(DATE, '')
FROM Samples sa
LEFT JOIN [Warehouse].[SmartEmail].[OfferSlotData] osd
	ON sa.FanID = osd.FanID


