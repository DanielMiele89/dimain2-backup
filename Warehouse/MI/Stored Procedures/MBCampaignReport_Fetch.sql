
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 21/03/2016
	Description: Returns the interim/extended metrics for Mitchell and Butler campaigns

	======================= Change Log =======================

***********************************************************************/


CREATE PROCEDURE [MI].[MBCampaignReport_Fetch] (@Extended bit)
AS
BEGIN
    IF @Extended = 0
	   BEGIN
		  
		  SELECT
			 w.ClientServicesRef
			 , w.StartDate AS StartDate
			 , CASE Cell WHEN '' THEN 'Total' ELSE Cell END AS Cell
			 , Transactions_M AS TransactionsMailed
			 , Transactions_C AS TransactionsControl
			 , Spenders_M AS SpendersMailed
			 , Spenders_C AS SpendersControl
			 , SUM(Sales_M) AS SalesMailed
			 , SUM(Sales_C) AS SalesControl
			 , Cardholders_M AS CardholdersMailed
			 , Cardholders_C AS CardholdersControl
			 , SUM(ExtraCommissionGenerated) AS CampaignCost
			 , w.Cashback_M AS Cashback
			 , Adj_FactorRR
			 , Adj_FactorSPC 
		  FROM MI.CampaignExternalResults_Workings w
		  JOIN MI.CampaignDetailsWave_PartnerLookup pl on pl.ClientServicesRef = w.ClientServicesRef
			 AND pl.StartDate = w.StartDate
		  JOIN Relational.Partner p on p.PartnerID = pl.PartnerID
		  JOIN Relational.Brand b on b.BrandID = p.BrandID
		  WHERE BrandGroupID = 42 AND SegmentID = 0
			 AND CustomerUniverse = 'FULL' 
			 AND SalesType = 'Main Results (Qualifying MIDs or Channels Only)'
		  GROUP BY
			 w.ClientServicesRef, w.StartDate, Transactions_C, Transactions_M, Spenders_C, Spenders_M, Sales_C, Sales_M
			 , Cardholders_M, Cardholders_C, Adj_FactorRR, Adj_FactorSPC, Cashback_M
			 , CASE Cell WHEN '' THEN 'Total' ELSE Cell END 
	   END
    ELSE IF @Extended = 1
	   BEGIN
		  
		  SELECT
			 w.ClientServicesRef
			 , w.StartDate AS StartDate
			 , CASE Cell WHEN '' THEN 'Total' ELSE Cell END AS Cell
			 , SUM(Transactions_M) AS TransactionsMailed
			 , SUM(Transactions_C) AS TransactionsControl
			 , SUM(Spenders_M) AS SpendersMailed
			 , SUM(Spenders_C) AS SpendersControl
			 , SUM(Sales_M) AS SalesMailed
			 , SUM(Sales_C) AS SalesControl
			 , SUM(Cardholders_M) AS CardholdersMailed
			 , SUM(Cardholders_C) AS CardholdersControl
			 , SUM(ExtraCommissionGenerated) AS CampaignCost
			 , Adj_FactorRR
			 , Adj_FactorSPC
		  FROM MI.CampaignExternalResultsLTE_Workings w
		  JOIN MI.CampaignDetailsWave_PartnerLookup pl on pl.ClientServicesRef = w.CLientServicesRef 
			 AND pl.StartDate = w.StartDate
		  JOIN Relational.Partner p on p.PartnerID = pl.PartnerID
		  JOIN Relational.Brand b on b.BrandID = p.BrandID
		  WHERE BrandGroupID = 42 AND SegmentID = 0
			 AND CustomerUniverse = 'FULL'
			 AND SalesType = 'Main Results (Qualifying MIDs or Channels Only)'
		  GROUP BY
			 w.ClientServicesRef, w.StartDate, Adj_FactorRR, Adj_FactorSPC
			 , CASE Cell WHEN '' THEN 'Total' ELSE Cell END

	   END


END
