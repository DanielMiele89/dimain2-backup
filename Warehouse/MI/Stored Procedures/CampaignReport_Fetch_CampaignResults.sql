
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Gets campaign results for report creation on Campaign_Details page

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_CampaignResults]
(
	@ClientServicesRef varchar(40),
	@StartDate date,
	@CalcStartDate date = NULL,
	@CalcEndDate date = NULL
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	SET @ClientServicesRef = SUBSTRING(@ClientServicesRef, 0, ISNULL(NULLIF(CHARINDEX('Bespoke', @ClientServicesRef, 0), 0), 99))

SELECT 
	'Total' Level, 'Total' ID , d.ClientServicesRef, 
	CASE m.Tier WHEN 1 THEN 'Gold' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Bronze' END as Tier,
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 0 ELSE MAX(p.PartnerID) END PartnerID, 
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 'Various' ELSE MAX(Partnername) END Partnername,
	 MAX(CampaignName) CampaignName, MAx(CampaignType) CampaignType,
	 COALESCE(@CalcStartDate, MAX(MinStartDate)) StartDate, COALESCE(@CalcEndDate, MAX(MaxEndDate)) EndDate, 
	 MAX(TargetedAcquire) TargetedAcquire, MAX(TargetedGrow) TargetedGrow, MAX(TargetedRetain) TargetedRetain,
	 MIN(MinCashback) MinCashback, MAX(MaxCashback) MaxCashback, AVG(AvgCashback) AvgCashback, 
	 SUM(TargetedVolume) TargetedVolume, SUM(ControlVolume) ControlVolume,
	 SUM(BASE) Base, SUM(MarketableBase) MarketableBase, AVG(WeeksAfterPreviousCampaign) WeeksAfterPreviousCampaign,
	 MAX(SpendTreshhold) SpendThreshold, MIN(SpendTreshhold_Min) SpendThreshold_Min, MAX(SpendTreshhold_Max) SpendThreshold_Max, AVG(SpendTreshhold_Avg) SpendThreshold_Avg,
	 MAX(QualifyingMids) QualifyingMids, CASE WHEN COUNT(DISTINCT AwardingMIDs)>1 THEN 'Various' ELSE MAX(AwardingMIDs) END AwardingMIDs,
	 MAX(FirstName) FirstName, MAX(Surname) Surname,MAX(JobTitle) JobTitle,MAx(COALESCE(DeskTelephone,'+44 (0)20 3397 4000')) DeskTelephone,MAX(COALESCE(MobileTelephone, DeskTelephone,'+44 (0)20 3397 4000')) MobileTelephone,MAX(ContactEmail) ContactEmail,
	 AVG(Margin) Margin
 FROM Warehouse.MI.CampaignDetailsWave d
 INNER JOIN Warehouse.MI.CampaignDetailsWave_PartnerLookup pl ON pl.ClientServicesRef=d.ClientServicesRef AND pl.StartDate=d.StartDate
 INNER JOIN Warehouse.Relational.Partner p ON p.PartnerID=pl.PartnerID
 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=p.PartnerID
 LEFT JOIN Warehouse.Staging.Reward_StaffTable s ON m.CS_Lead_ID=s.StaffID
 WHERE d.ClientServicesRef=@ClientServicesRef AND d.StartDate=@StartDate
 GROUP BY d.ClientServicesRef, m.Tier

 UNION

 SELECT 
	 'Segment' Level, CAST(SegmentID AS VARCHAR(MAX)) , d.ClientServicesRef, 
	 CASE m.Tier WHEN 1 THEN 'Gold' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Bronze' END as Tier,
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 0 ELSE MAX(p.PartnerID) END PartnerID, 
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 'Various' ELSE MAX(Partnername) END Partnername,
	 NULL CampaignName, NULL CampaignType,
	 COALESCE(@CalcStartDate, MAX(MinStartDate)) StartDate, COALESCE(@CalcEndDate, MAX(MaxEndDate)), 
	 MAX(TargetedAcquire) TargetedAcquire, MAX(TargetedGrow) TargetedGrow, MAX(TargetedRetain) TargetedRetain,
	 MIN(MinCashback), MAX(MaxCashback), AVG(AvgCashback), 
	 SUM(TargetedVolume), SUM(ControlVolume),
	 SUM(BASE), SUM(MarketableBase), AVG(WeeksAfterPreviousCampaign),
	 MAX(SpendTreshhold), MIN(SpendTreshhold_Min), MAX(SpendTreshhold_Max),AVG(SpendTreshhold_Avg) AVGST,
	 MAX(QualifyingMids), CASE WHEN COUNT(DISTINCT AwardingMIDs)>1 THEN 'Various' ELSE MAX(AwardingMIDs) END AwardingMIDs,
	 MAX(FirstName), MAX(Surname),MAX(JobTitle),MAx(COALESCE(DeskTelephone,'+44 (0)20 3397 4000')),MAX(COALESCE(MobileTelephone, DeskTelephone,'+44 (0)20 3397 4000')),MAX(ContactEmail),
	 AVG(Margin) Margin
 FROM Warehouse.MI.CampaignDetailsWave_Segment d
 INNER JOIN Warehouse.MI.CampaignDetailsWave_PartnerLookup pl ON pl.ClientServicesRef=d.ClientServicesRef AND pl.StartDate=d.StartDate
 INNER JOIN Warehouse.Relational.Partner p ON p.PartnerID=pl.PartnerID
 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=p.PartnerID
 LEFT JOIN Warehouse.Staging.Reward_StaffTable s ON m.CS_Lead_ID=s.StaffID
 WHERE d.ClientServicesRef=@ClientServicesRef AND d.StartDate=@StartDate
 GROUP BY d.ClientServicesRef, SegmentID, m.Tier

 UNION

 SELECT 
	 'SuperSegment' Level, CAST(SegmentID AS VARCHAR(MAX))  , d.ClientServicesRef, 
	 CASE m.Tier WHEN 1 THEN 'Gold' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Bronze' END as Tier,
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 0 ELSE MAX(p.PartnerID) END PartnerID, 
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 'Various' ELSE MAX(Partnername) END Partnername,
	 NULL CampaignName, NULL CampaignType,
	 COALESCE(@CalcStartDate, MAX(MinStartDate)) StartDate, COALESCE(@CalcEndDate, MAX(MaxEndDate)), 
	 MAX(TargetedAcquire) TargetedAcquire, MAX(TargetedGrow) TargetedGrow, MAX(TargetedRetain) TargetedRetain,
	 MIN(MinCashback), MAX(MaxCashback), AVG(AvgCashback), 
	 SUM(TargetedVolume), SUM(ControlVolume),
	 SUM(BASE), SUM(MarketableBase), AVG(WeeksAfterPreviousCampaign),
	 MAX(SpendTreshhold), MIN(SpendTreshhold_Min), MAX(SpendTreshhold_Max),AVG(SpendTreshhold_Avg) AVGST,
	 MAX(QualifyingMids), CASE WHEN COUNT(DISTINCT AwardingMIDs)>1 THEN 'Various' ELSE MAX(AwardingMIDs) END AwardingMIDs,
	 MAX(FirstName), MAX(Surname),MAX(JobTitle),MAx(COALESCE(DeskTelephone,'+44 (0)20 3397 4000')),MAX(COALESCE(MobileTelephone, DeskTelephone,'+44 (0)20 3397 4000')),MAX(ContactEmail),
	 AVG(Margin) Margin
 FROM Warehouse.MI.CampaignDetailsWave_SuperSegment d
 INNER JOIN Warehouse.MI.CampaignDetailsWave_PartnerLookup pl ON pl.ClientServicesRef=d.ClientServicesRef AND pl.StartDate=d.StartDate
 INNER JOIN Warehouse.Relational.Partner p ON p.PartnerID=pl.PartnerID
 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=p.PartnerID
 LEFT JOIN Warehouse.Staging.Reward_StaffTable s ON m.CS_Lead_ID=s.StaffID
 WHERE d.ClientServicesRef=@ClientServicesRef AND d.StartDate=@StartDate
 GROUP BY d.ClientServicesRef, SegmentID, m.Tier

 UNION

 SELECT 
	 'BespokeCell' Level, Cell , d.ClientServicesRef, 
	 CASE m.Tier WHEN 1 THEN 'Gold' WHEN 2 THEN 'Silver' WHEN 3 THEN 'Bronze' END as Tier,
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 0 ELSE MAX(p.PartnerID) END PartnerID, 
	 CASE WHEN COUNT(DISTINCT PartnerName)>1 THEN 'Various' ELSE MAX(Partnername) END Partnername,
	 NULL CampaignName, NULL CampaignType,
	 COALESCE(@CalcStartDate, MAX(MinStartDate)) StartDate, COALESCE(@CalcEndDate, MAX(MaxEndDate)), 
	 MAX(TargetedAcquire) TargetedAcquire, MAX(TargetedGrow) TargetedGrow, MAX(TargetedRetain) TargetedRetain,
	 MIN(MinCashback), MAX(MaxCashback), AVG(AvgCashback), 
	 SUM(TargetedVolume), SUM(ControlVolume),
	 SUM(BASE), SUM(MarketableBase), AVG(WeeksAfterPreviousCampaign),
	 MAX(SpendTreshhold), MIN(SpendTreshhold_Min), MAX(SpendTreshhold_Max),AVG(SpendTreshhold_Avg) AVGST,
	 MAX(QualifyingMids), CASE WHEN COUNT(DISTINCT AwardingMIDs)>1 THEN 'Various' ELSE MAX(AwardingMIDs) END AwardingMIDs,
	 MAX(FirstName), MAX(Surname),MAX(JobTitle),MAx(COALESCE(DeskTelephone,'+44 (0)20 3397 4000')),MAX(COALESCE(MobileTelephone, DeskTelephone,'+44 (0)20 3397 4000')),MAX(ContactEmail),
	 AVG(Margin) Margin
 FROM Warehouse.MI.CampaignDetailsWave_BespokeCell d
 INNER JOIN Warehouse.MI.CampaignDetailsWave_PartnerLookup pl ON pl.ClientServicesRef=d.ClientServicesRef AND pl.StartDate=d.StartDate
 INNER JOIN Warehouse.Relational.Partner p ON p.PartnerID=pl.PartnerID
 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=p.PartnerID
 LEFT JOIN Warehouse.Staging.Reward_StaffTable s ON m.CS_Lead_ID=s.StaffID
 WHERE d.ClientServicesRef=@ClientServicesRef AND d.StartDate=@StartDate
 GROUP BY d.ClientServicesRef, Cell, m.Tier
 ORDER BY 1 DESC, 2

END