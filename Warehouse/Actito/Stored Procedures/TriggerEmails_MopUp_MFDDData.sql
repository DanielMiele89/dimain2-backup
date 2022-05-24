
CREATE PROCEDURE [Actito].[TriggerEmails_MopUp_MFDDData]
AS
BEGIN

		DECLARE @SendDate_Start DATE = '2021-07-21'
			,	@SendDate_End DATE = '2021-07-22'

		IF OBJECT_ID('tempdb..#MFDD_TriggerEmail') IS NOT NULL DROP TABLE #MFDD_TriggerEmail;
		SELECT	PartnerID
			,	IronOfferID
			,	MAX(TransactionNumber) AS TransactionNumber
			,	FanID
		INTO #MFDD_TriggerEmail
		FROM [SmartEmail].[SFD_DailyLoad_MFDD_TriggerEmail] mfdd
		WHERE EmailDate BETWEEN @SendDate_Start AND @SendDate_End
		GROUP BY PartnerID
				, IronOfferID
				, FanID

		IF OBJECT_ID('tempdb..#DailyData') IS NOT NULL DROP TABLE #DailyData;
		WITH
		MFDD_Email AS (	SELECT	FanID
							,	MFDDEmail = STUFF((	SELECT ';' + CONVERT(VARCHAR(5), PartnerID) + '-' + CONVERT(VARCHAR(5), TransactionNumber)
													FROM #MFDD_TriggerEmail t1
													WHERE t1.FanID = t2.FanID
													FOR XML PATH ('')), 1, 1, '')
						FROM #MFDD_TriggerEmail t2
						GROUP BY FanID)

		SELECT	dd.FanID
			,	mf.MFDDEmail AS RetailerPaymentNumber
		INTO #DailyData
		FROM [Warehouse].[SmartEmail].[DailyData] dd
		INNER JOIN MFDD_Email mf
			ON dd.FanID = mf.FanID
		WHERE dd.Marketable = 1

		SELECT	FanID
			,	RetailerPaymentNumber
		FROM #DailyData
		ORDER BY LEN(RetailerPaymentNumber) DESC

	END

	/*

		SELECT	CASE
					WHEN ClubID = 132 THEN 'NW'
					ELSE 'RBS'
				END AS Brand
			,	CASE
					WHEN IsLoyalty = 0 THEN 'Core'
					ELSE 'Premier'
				END AS Loyalty
			,	COUNT(*)
			,	pa.Name + ' ' + CASE
									WHEN TransactionNumber = 1 THEN 'First Payment'
									ELSE 'First Earn'
								END AS Email
		FROM #MFDD_TriggerEmail te
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON te.PartnerID = pa.ID
		INNER JOIN SmartEmail.DailyData dd
			ON te.FanID = dd.FanID
		GROUP BY	pa.Name + ' ' + CASE
										WHEN TransactionNumber = 1 THEN 'First Payment'
										ELSE 'First Earn'
									END
				,	CASE
						WHEN ClubID = 132 THEN 'NW'
						ELSE 'RBS'
					END
				,	CASE
						WHEN IsLoyalty = 0 THEN 'Core'
						ELSE 'Premier'
					END
		ORDER BY	pa.Name + ' ' + CASE
										WHEN TransactionNumber = 1 THEN 'First Payment'
										ELSE 'First Earn'
									END
				,	CASE
						WHEN ClubID = 132 THEN 'NW'
						ELSE 'RBS'
					END
				,	CASE
						WHEN IsLoyalty = 0 THEN 'Core'
						ELSE 'Premier'
					END

					*/