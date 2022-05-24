

CREATE PROCEDURE [Staging].[SSRS_R0192_RedemtptionStats_V2] (@StartDate DATETIME
														  , @EndDate DATETIME)
AS
BEGIN

	IF OBJECT_ID('tempdb..#RedemptionItem') IS NOT NULL DROP TABLE #RedemptionItem
	SELECT ri.RedeemID
		 , ri.PrivateDescription
		 , ri.RedeemType
		 , ri.PartnerName
		 , RANK() OVER (ORDER BY RedemptionPartnerRank, ItemRank) AS ItemRank
	INTO #RedemptionItem
	FROM (SELECT ri.RedeemID
	  		   , CASE
	  	  			WHEN ri.RedeemID IN (7111, 7176) THEN 'Cash Back'
	  	  			WHEN ri.RedeemID IN (7178, 7179) THEN 'Pay to Credit'
	  	  			ELSE ri.RedeemType
	  			 END AS RedeemType
	  		   , CASE
	  	  			WHEN ri.RedeemType = 'Charity' AND ri.RedeemID NOT IN (7111, 7176, 7178, 7179) THEN 1
	  	  			WHEN (ri.RedeemType = 'Cash Back' OR ri.RedeemID IN (7111, 7176)) AND ri.RedeemID NOT IN (7178, 7179) THEN 2
	  	  			WHEN (ri.RedeemType = 'Pay to Credit' OR ri.RedeemID IN (7178, 7179)) AND ri.RedeemID NOT IN (7111, 7176) THEN 2
	  	  			ELSE 3
	  			 END AS ItemOrder
			   , ri.PrivateDescription
	  		   , pa.PartnerName
	  		   , DENSE_RANK() OVER (ORDER BY CASE
	  								   			WHEN pa.PartnerName = 'B&Q' THEN 1
	  								   			WHEN pa.PartnerName = 'Currys PC World' THEN 2
	  								   			WHEN pa.PartnerName = 'Debenhams' THEN 3
	  								   			WHEN pa.PartnerName = 'Marks & Spencer' THEN 4
	  								   			WHEN pa.PartnerName = 'Cineworld' THEN 5
	  								   			WHEN pa.PartnerName = 'Pizza Express' THEN 6
	  								   			WHEN pa.PartnerName = 'Red Letter Days' THEN 7
	  								   			WHEN pa.PartnerName = 'SpaBreaks.com' THEN 8
	  								   			WHEN pa.PartnerName = 'Caffe Nero ' THEN 9
	  								   			WHEN pa.PartnerName = 'Argos' THEN 10
	  								   			WHEN pa.PartnerName = 'Avios' THEN 11
												WHEN pa.PartnerName IS NULL THEN 99
	  								   			ELSE 12
	  										 END, PartnerName) AS RedemptionPartnerRank
	  		   , DENSE_RANK() OVER (ORDER BY tuv.TradeUp_Value, tuv.TradeUp_ClubCashRequired, PrivateDescription) AS ItemRank
		  FROM Relational.RedemptionItem ri
		  LEFT JOIN Relational.RedemptionItem_TradeUpValue tuv
	  		ON ri.RedeemID = tuv.RedeemID
		  LEFT JOIN Relational.Partner pa
	  		ON tuv.PartnerID = pa.PartnerID) ri

	DECLARE @EndDateCalc DATETIME = DATEADD( ss, -1, DATEADD(d, 1, @Enddate));

	WITH
	RL (ItemID
	  , ClubCash
	  , Date
	  , Counter)
	AS (SELECT ItemID
			 , ClubCash
			 , Date
			 , 1
		FROM SLC_Repl..Trans t
		WHERE Date BETWEEN @StartDate AND @EndDateCalc
		AND typeid = 3
		UNION ALL
		SELECT tr.ItemID
			 , -t.ClubCash
			 , t.Date
			 , -1
		FROM SLC_REPL..trans t
		INNER JOIN SLC_REPL..trans tr
			ON t.itemID = tr.ID
		WHERE t.Date BETWEEN @StartDate AND @EndDateCalc
		AND t.typeid = 4
		AND tr.typeID = 3)

	SELECT RedeemType
		 , t.ItemID
		 , ri.PartnerName
		 , ri.ItemRank
		 , r.Description
		 , SUM(Counter) AS Total
		 , SUM(ClubCash) AS TotalClubCash
		 , MIN(Date) AS FirstDate
		 , MAX(Date) AS LastDate
	FROM RL t
	LEFT JOIN SLC_REPL..Redeem r
		ON t.ItemID = r.ID
	LEFT JOIN #RedemptionItem ri 
		ON ri.RedeemID = t.ItemID
	GROUP BY RedeemType
		   , t.ItemID
		   , r.Description
		   , r.Description
		   , ri.ItemRank
		   , ri.PartnerName
	ORDER BY ItemRank

END