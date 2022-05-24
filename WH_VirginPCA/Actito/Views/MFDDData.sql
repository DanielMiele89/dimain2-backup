



CREATE VIEW [Actito].[MFDDData]
AS

--WITH
--MFDD_TriggerEmail AS (	SELECT	PartnerID
--							,	IronOfferID
--							,	MAX(TransactionNumber) AS TransactionNumber
--							,	FanID
--							,	ROW_NUMBER () OVER (PARTITION BY FanID ORDER BY IronOfferID DESC) AS FanRowNum
--						FROM [SmartEmail].[SFD_DailyLoad_MFDD_TriggerEmail] mfdd
--						WHERE EmailDate = CONVERT(DATE, GETDATE())
--						GROUP BY PartnerID
--								, IronOfferID
--								, FanID),

--MFDD_Email AS (	SELECT	FanID
--					,	MFDDEmail = STUFF((	SELECT ';' + CONVERT(VARCHAR(5), PartnerID) + '-' + CONVERT(VARCHAR(5), TransactionNumber)
--											FROM MFDD_TriggerEmail t1
--											WHERE t1.FanID = t2.FanID
--											FOR XML PATH ('')), 1, 1, '')
--				FROM MFDD_TriggerEmail t2
--				GROUP BY FanID)

SELECT	dd.FanID
	,	RetailerID = 9999
	,	RetailerPaymentNumber = 2
FROM [WH_VirginPCA].[Email].[DailyData] dd
--INNER JOIN MFDD_Email mf
--	ON dd.FanID = mf.FanID
WHERE dd.Marketable = 1
AND 1 = 2


