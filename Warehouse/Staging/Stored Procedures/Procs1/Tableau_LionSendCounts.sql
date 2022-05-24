

CREATE PROCEDURE [Staging].[Tableau_LionSendCounts]

AS
BEGIN
	SET NOCOUNT ON;

			IF OBJECT_ID('tempdb..#LionSendCounts') IS NOT NULL DROP TABLE #LionSendCounts
			SELECT osd.LionSendID
				 , osd.OfferType
				 , cu.MarketableByEmail
				 , cu.CurrentlyActive
				 , COUNT(DISTINCT osd.FanID) AS CustomerCount
			INTO #LionSendCounts
			FROM [SmartEmail].[CombinedOfferSlotData] osd
			INNER JOIN [Relational].[Customer] cu
				ON osd.FanID = cu.FanID
			GROUP BY osd.LionSendID
					, osd.OfferType
					, cu.MarketableByEmail
					, cu.CurrentlyActive
			UNION
			SELECT osd.LionSendID
				 , osd.OfferType
				 , cu.MarketableByEmail
				 , cu.CurrentlyActive
				 , COUNT(DISTINCT osd.FanID) AS CustomerCount
			FROM [SmartEmail].[CombinedOfferSlotData] osd
			INNER JOIN [SmartEmail].[SampleCustomersList] lis
				ON osd.FanID = lis.FanID
			INNER JOIN [SmartEmail].[SampleCustomerLinks] lin
				ON lis.ID = lin.SampleCustomerID
			INNER JOIN [Relational].[Customer] cu
				ON lin.RealCustomerFanID = cu.FanID
			GROUP BY osd.LionSendID
					, osd.OfferType
					, cu.MarketableByEmail
					, cu.CurrentlyActive;
					
			SELECT *
			FROM (	SELECT LionSendID
						 , 'Total Customer Counts' AS CustomerGroup
						 , SUM(CustomerCount) / 2 AS CustomerCount
					FROM #LionSendCounts
					GROUP BY LionSendID
					UNION
					SELECT LionSendID
						 , 'Earn Customer Counts' AS CustomerGroup
						 , SUM(CustomerCount) AS CustomerCount
					FROM #LionSendCounts
					WHERE OfferType = 1
					GROUP BY LionSendID
					UNION
					SELECT LionSendID
						 , 'Burn Customer Counts' AS CustomerGroup
						 , SUM(CustomerCount) AS CustomerCount
					FROM #LionSendCounts
					WHERE OfferType = 3
					GROUP BY LionSendID
					UNION
					SELECT LionSendID
						 , 'Activated CustomerCount' AS CustomerGroup
						 , SUM(CustomerCount) AS CustomerCount
					FROM #LionSendCounts
					WHERE MarketableByEmail = 1
					AND CurrentlyActive = 1
					GROUP BY LionSendID
					UNION
					SELECT LionSendID
						 , 'Emailable CustomerCount' AS CustomerGroup
						 , SUM(CustomerCount) AS CustomerCount
					FROM #LionSendCounts
					WHERE MarketableByEmail = 1
					GROUP BY LionSendID
					UNION
					SELECT LionSendID
						 , 'Deactivated CustomerCount' AS CustomerGroup
						 , SUM(CustomerCount) AS CustomerCount
					FROM #LionSendCounts
					WHERE CurrentlyActive = 0
					GROUP BY LionSendID) a;

END





