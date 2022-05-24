




CREATE VIEW [Actito].[MFDDData]
AS

WITH
MFDD_TriggerEmail AS (	SELECT	PartnerID
							,	IronOfferID
							,	MAX(TransactionNumber) AS TransactionNumber
							,	FanID
							,	ROW_NUMBER () OVER (PARTITION BY FanID ORDER BY IronOfferID DESC) AS FanRowNum
						FROM [SmartEmail].[SFD_DailyLoad_MFDD_TriggerEmail] mfdd
						WHERE EmailDate >= CONVERT(DATE, GETDATE())
					--	OR EmailDate BETWEEN '2021-12-04' AND '2021-12-12'
						GROUP BY PartnerID
								, IronOfferID
								, FanID),

MFDD_Email AS (	SELECT	FanID
					,	MFDDEmail = STUFF((	SELECT ';' + CONVERT(VARCHAR(5), PartnerID) + '-' + CONVERT(VARCHAR(5), TransactionNumber)
											FROM MFDD_TriggerEmail t1
											WHERE t1.FanID = t2.FanID
											FOR XML PATH ('')), 1, 1, '')
				FROM MFDD_TriggerEmail t2
				GROUP BY FanID)

SELECT	dd.FanID
	,	mf.MFDDEmail AS RetailerPaymentNumber
FROM [Warehouse].[SmartEmail].[DailyData] dd
INNER JOIN MFDD_Email mf
	ON dd.FanID = mf.FanID
WHERE dd.Marketable = 1

	--	AND dd.FanID < 1900000000	--	Exclude Sample Customers