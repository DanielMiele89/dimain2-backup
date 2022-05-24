

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 27/07/2016													  --
-- Description: Shows the tracking status of retailers						  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0128_RetailerTrackingStatus]
AS


IF OBJECT_ID ('tempdb..#PartnerDetails') IS NOT NULL DROP TABLE #PartnerDetails
SELECT			b.BrandID
,				b.BrandName
,				CAST(p.PartnerID AS VARCHAR) AS PartnerID
,				p.PartnerName
,				a.AcquirerName
,				tr.Trackable
INTO			#PartnerDetails
FROM			Staging.TrackableRetailers AS tr
LEFT JOIN		Relational.Partner AS p
		ON		tr.PartnerID = p.PartnerID
LEFT JOIN		Relational.Brand AS b
		ON		tr.BrandID = b.BrandID
INNER JOIN		Relational.Acquirer AS a
		ON		tr.AcquirerID = a.AcquirerID


IF OBJECT_ID ('tempdb..#TrackableSpend') IS NOT NULL DROP TABLE #TrackableSpend
SELECT			SUM(rt.AnnualSpend) AS Spend
,				pd.BrandID
INTO			#TrackableSpend
FROM			MI.RetailerTrackingAcquirer rt
INNER JOIN		Relational.Acquirer AS a
		ON		rt.AcquirerID = a.AcquirerID
INNER JOIN		Relational.ConsumerCombination AS cc WITH (NOLOCK)
		ON		rt.ConsumerCombinationID = cc.ConsumerCombinationID
INNER JOIN		#PartnerDetails AS pd
		ON		pd.BrandID = cc.BrandID
		AND		a.RewardTrackable = 1
GROUP BY		pd.BrandID


IF OBJECT_ID ('tempdb..#TotalSpend') IS NOT NULL DROP TABLE #TotalSpend
SELECT			SUM(rt.AnnualSpend) AS TotalSpend
,				pd.BrandID
INTO			#TotalSpend
FROM			MI.RetailerTrackingAcquirer AS rt
INNER JOIN		Relational.Acquirer AS a
		ON		rt.AcquirerID = a.AcquirerID
INNER JOIN		Relational.ConsumerCombination AS cc WITH (NOLOCK)
		ON		rt.ConsumerCombinationID = cc.ConsumerCombinationID
INNER JOIN		#PartnerDetails AS pd
		ON		pd.BrandID = cc.BrandID
GROUP BY		pd.BrandID


IF OBJECT_ID ('tempdb..#TrackablePercentage') IS NOT NULL DROP TABLE #TrackablePercentage
SELECT			t.BrandID
,				ISNULL(ts.Spend/t.TotalSpend * 100,0) AS TrackablePercentage
INTO			#TrackablePercentage
FROM			#TotalSpend AS t
LEFT OUTER JOIN	#TrackableSpend AS ts
		ON		ts.BrandID = t.BrandID


SELECT			CASE 
					WHEN pd.BrandID IS NULL THEN ''
					ELSE pd.BrandID
				END AS BrandID
,				CASE 
					WHEN BrandName IS NULL THEN ''
					ELSE BrandName
				END AS BrandName
,				CASE 
					WHEN PartnerID IS NULL THEN ''
					ELSE PartnerID
				END AS PartnerID
,				CASE 
					WHEN PartnerName IS NULL THEN ''
					ELSE PartnerName
				END AS PartnerName
,				CASE 
					WHEN AcquirerName IS NULL THEN ''
					ELSE AcquirerName
				END AS AcquirerName
,				CASE 
					WHEN Trackable IS NULL THEN ''
					ELSE Trackable
				END AS IsTrackable
,				tp.TrackablePercentage
FROM			#PartnerDetails AS pd
INNER JOIN		#TrackablePercentage AS tp
		ON		pd.BrandID = tp.BrandID
ORDER BY		PartnerName