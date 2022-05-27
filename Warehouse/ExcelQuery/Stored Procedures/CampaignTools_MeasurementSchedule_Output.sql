-- =============================================
-- Author:		Dorota
-- Create date:	09/04/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[CampaignTools_MeasurementSchedule_Output]

AS
BEGIN
	SET NOCOUNT ON;
		  SELECT cs1.FirstName CS_Lead, di1.FirstName DI_Lead, 
		  CASE WHEN Bespoke=1 AND AnalysisType='Full' THEN 'Bespoke' ELSE AnalysisType END AnalysisType2, b.* FROM
		  (SELECT 'Full' AnalysisType, a.*, CASE WHEN AnalysisDue < CAST(GETDATE() AS  DATE) THEN '  Overdue'
		  WHEN AnalysisDue BETWEEN CAST(GETDATE() AS  DATE) AND CAST(GETDATE()+6 AS  DATE) THEN '  This Week'
		  WHEN AnalysisDue BETWEEN CAST(GETDATE()+7 AS  DATE) AND CAST(GETDATE()+6+7 AS  DATE) THEN ' Next Week'
		  WHEN AnalysisDue=DATEADD(day,500,CAST(GETDATE() AS DATE))  THEN 'TBA'
		  ELSE datename(month, AnalysisDue)+ ' '+ datename(year, AnalysisDue) END Week,
		  CASE WHEN ClientServicesRef=COALESCE(TriggerMeasureAfter,ClientServicesRef) THEN 1 ELSE 0 END Include FROM
		  (SELECT t.ClientServicesRef, t.PartnerID, t.CampaignName, t.StartDate, t.EndDate,CASE WHEN Bespoke=1 THEN 'Yes' ELSE '' END Bespoke,TriggerMeasureAfter,
		  CASE WHEN d.EndDate IS NULL THEN DATEADD(day,14,'2015-07-01') ELSE DATEADD(day, CASE WHEN Bespoke=1 THEN 4*7 ELSE 2*7 END ,d.EndDate) END AnalysisDue
		   FROM Warehouse.MI.CampaignDetails_Total t
		   LEFT JOIN Warehouse.MI.CampaignAnalysisTiming a ON t.ClientServicesRef=a.ClientServicesRef
		   LEFT JOIN Warehouse.MI.CampaignDetails_Total d ON COALESCE (TriggerMeasureAfter,t.ClientServicesRef)=d.ClientServicesRef AND d.EnDDate<='2015-07-01'
		   WHERE t.ClientServicesRef NOT IN 
		  (SELECT ClientServicesRef FROM Warehouse.MI.CampaignResults_Total)
		  AND t.CampaignType NOT LIKE '%Base%' --and EndDate<=GETDATE()-7
		  ) a
		  UNION ALL
		  SELECT 'Interim' AnalysisType, a.*, CASE WHEN AnalysisDue < CAST(GETDATE() AS  DATE) THEN '  Overdue'
		  WHEN AnalysisDue BETWEEN CAST(GETDATE() AS  DATE) AND CAST(GETDATE()+6 AS  DATE) THEN '  This Week'
		  WHEN AnalysisDue BETWEEN CAST(GETDATE()+7 AS  DATE) AND CAST(GETDATE()+6+7 AS  DATE) THEN ' Next Week'
		  WHEN AnalysisDue=DATEADD(day,500,CAST(GETDATE() AS DATE))  THEN 'TBA'
		  ELSE datename(month, AnalysisDue)+ ' '+ datename(year, AnalysisDue) END,
		  1 FROM
		  (SELECT t.ClientServicesRef, t.PartnerID, t.CampaignName, t.StartDate, t.EndDate,CASE WHEN Bespoke=1 THEN 'Yes' ELSE '' END Bespoke,TriggerMeasureAfter,
		  CASE WHEN d.EndDate IS NULL THEN DATEADD(day,14,'2015-07-01') ELSE DATEADD(day, CASE WHEN Bespoke=1 THEN 4*7 ELSE 2*7 END ,d.EndDate) END AnalysisDue
		   FROM Warehouse.MI.CampaignDetails_Total t
		   LEFT JOIN Warehouse.MI.CampaignAnalysisTiming a ON t.ClientServicesRef=a.ClientServicesRef
		   LEFT JOIN Warehouse.MI.CampaignDetails_Total d ON t.ClientServicesRef=d.ClientServicesRef
		   WHERE t.ClientServicesRef NOT IN 
		  (SELECT ClientServicesRef FROM Warehouse.MI.CampaignResults_Total)
		  AND t.CampaignType NOT LIKE '%Base%' --and EndDate<=GETDATE()-7
		  UNION
		  SELECT CONCAT(t.ClientServicesRef, ' - Wave ', d.StartDate) , t.PartnerID, t.CampaignName, d.StartDate, d.EndDate,  CASE WHEN Bespoke=1 THEN 'Yes' ELSE '' END Bespoke, CONCAT('Wave ', d.StartDate) TriggerMeasureAfter,
		  CASE WHEN d.EndDate IS NULL THEN DATEADD(day,500,CAST(GETDATE() AS DATE)) ELSE DATEADD(day, CASE WHEN Bespoke=1 THEN 4*7 ELSE 2*7 END ,d.EndDate) END AnalysisDue
		   FROM Warehouse.MI.CampaignDetails_Total t
		   LEFT JOIN Warehouse.MI.CampaignAnalysisTiming a ON t.ClientServicesRef=a.ClientServicesRef
		  INNER JOIN Warehouse.MI.CampaignWaves_Total d ON t.ClientServicesRef=d.ClientServicesRef
		   WHERE t.ClientServicesRef NOT IN 
		  (SELECT ClientServicesRef FROM Warehouse.MI.CampaignResults_Total)
		  AND t.CampaignType NOT LIKE '%Base%' --and EndDate<=GETDATE()-7 
		  ) a
		  WHERE TriggerMeasureAfter<>ClientServicesRef and AnalysisDue>=CAST(GETDATE() AS DATE)
		  ) b
		  LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=b.PArtnerID
		  LEFT JOIN Warehouse.Staging.Reward_StaffTable cs1 ON cs1.StaffID=CS_Lead_ID
		  LEFT JOIN Warehouse.Staging.Reward_StaffTable di1 ON di1.StaffID=D_I_Lead_ID
		  WHERE EnDDate<='2015-07-01'
		  Order by AnalysisDue

		  END
