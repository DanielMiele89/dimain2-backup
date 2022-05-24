
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Insert Checks after a calculation has run

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_CheckFlags]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @SalesPerc decimal(4,2) = .05
DECLARE @IncSalesPerc decimal(4,2) = .10

-- If this is ClientServicesRef and StartDate is in the CheckFlags table then set it as archived
UPDATE c 
SET Archived = 1
FROM MI.CampaignReport_checkflags c
JOIN MI.CampaignReportlog l ON l.clientservicesref = c.clientservicesref AND l.startdate = c.startdate
WHERE CAST(CalcDate AS DATE) = CAST(GETDATE() AS DATE) AND ExtendedPeriod = 0

INSERT INTO MI.CampaignReport_CheckFlags (
      [ClientServicesRef]
      ,[StartDate]
      ,[MaxEndDate]
      ,[InternalControlGroup]
      ,[ExternalControlGroup]
      ,[Cardholders]
      ,[InternalControlGroupSize]
      ,[ExternalControlGroupSize]
      ,[Sales]
      ,[Commission]
      ,[InternalSalesUplift]
      ,[ExternalSalesUplift]
      ,[InternalSignificantUpliftSPC]
      ,[ExternalSignificantUpliftSPC]
      ,[SalesCheck]
      ,[UpliftCheck]
      ,[AdjFactorCapCheck]
	  ,[IncrementalSalesCheck]
	  ,CampaignName
)
SELECT DISTINCT
	a.ClientServicesRef, a.StartDate, a.MaxEndDate, 
	b.[Internal Control Group], b.[External Control Group],
	Cardholders,
	b.[Internal Control Group Size], b.[External Control Group Size],
	Sales, Commission, 
	b.[Internal Sales Uplift], b.[External Sales Uplift],
	b.[Internal SignificantUpliftSPC], b.[External SignificantUpliftSPC],
	SalesCheck, UpliftCheck,AdjFactorCapCheck, IncrementalSalesCheck, CampaignName
FROM 
(
	-- Check Sales
	-- If sales in the PureSales table is more than +/- 10% difference of the sales in the Workings table
	SELECT DISTINCT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, cw.CampaignName
		,CASE
			WHEN ps.Sales > w.Sales_M*(1+@SalesPerc) THEN 'Pure Sales Above (Internal)' WHEN ps.Sales < w.Sales_M*(1-@SalesPerc) THEN 'Pure Sales Below (Internal)' 
			WHEN pse.Sales > we.Sales_M*(1+@SalesPerc) THEN 'Pure Sales Above (External)' WHEN pse.Sales < we.Sales_M*(1-@SalesPerc) THEN 'Pure Sales Below (External)' 
			ELSE '-' 
		END SalesCheck
	FROM MI.CampaignInternalResults_PureSales ps
	JOIN MI.CampaignExternalResults_PureSales pse
		ON pse.ClientServicesRef = ps.ClientServicesRef 
			AND pse.StartDate = ps.StartDate 
	LEFT JOIN mi.CampaignInternalResults_Workings w 
		ON w.ClientServicesRef = ps.ClientServicesRef 
			AND w.StartDate = ps.StartDate 
			AND w.CustomerUniverse = ps.CustomerUniverse
			AND w.level = ps.Level
			AND w.SegmentID = ps.SegmentID
			AND w.Cell = ps.Cell
			AND w.SalesType = ps.SalesType
			AND w.ControlGroup = ps.ControlGroup
	LEFT JOIN mi.CampaignExternalResults_Workings we
		ON we.ClientServicesRef = pse.ClientServicesRef 
			AND we.StartDate = pse.StartDate 
			AND we.CustomerUniverse = pse.CustomerUniverse
			AND we.level = pse.Level
			AND we.SegmentID = pse.SegmentID
			AND we.Cell = pse.Cell
			AND we.SalesType = pse.SalesType
			AND we.ControlGroup = pse.ControlGroup
	JOIN mi.CampaignReportLog l ON l.ClientServicesRef = ps.ClientServicesRef AND l.StartDate = ps.StartDate
	JOIN mi.campaigndetailswave cw ON cw.ClientServicesRef = substring(l.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', l.clientservicesref, 0), 0), 99)) AND cw.StartDate = l.StartDate
	WHERE ps.SalesType = 'Main Results (Qualifying MIDs or Channels Only)'
		AND CAST(CalcDate AS DATE) =CAST(GETDATE() AS DATE) and ExtendedPeriod = 0
		and ps.Level = 'Total' and pse.Level = 'Total'
) a
JOIN (
	-- Check uplift/incrementalSales
	-- If Uplift in the FinalWave table is more than +/- 10% difference of the uplift in the BespokeCell/Segment 
	-- If total incremental sales is not equal sum of incremental sales in SoW (Segment/BespokeCell if applicable) 
	SELECT DISTINCT * FROM (
	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, 
		w.ControlGroupSize 'Internal Control Group Size', w.ControlGroup 'Internal Control Group', w.SalesUplift 'Internal Sales Uplift', w.SignificantUpliftSPC 'Internal SignificantUpliftSPC',
		we.ControlGroupSize 'External Control Group Size',  we.ControlGroup 'External Control Group', we.SalesUplift 'External Sales Uplift', we.SignificantUpliftSPC 'External SignificantUpliftSPC',
		w.Sales, w.Commission
		,CASE 
			WHEN w.SalesUplift > 0.50 THEN 'High (Internal)'
			WHEN w.SalesUplift < 0 THEN 'Low (Internal)'
			WHEN we.SalesUplift > 0.50 THEN 'High (External)'
			WHEN we.SalesUplift < 0 THEN 'Low (External)'
			ELSE '-' 
		END UpliftCheck
		,CASE 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) > ABS(bc.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (Bespoke Internal)' 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) < ABS(bc.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (Bespoke Internal)' 
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) > ABS(bce.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (Bespoke External)'
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) < ABS(bce.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (Bespoke External)'
			ELSE '-' 
		END IncrementalSalesCheck
	FROM mi.CampaignReportLog l
	JOIN MI.CampaignInternalResultsFinalWave w ON w.ClientServicesRef = l.ClientServicesRef AND w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsFinalWave we ON we.ClientServicesRef = l.ClientServicesRef AND we.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell
		GROUP BY ClientServicesRef, StartDate
	) bc on bc.ClientServicesRef = l.ClientServicesRef and bc.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell
		GROUP BY ClientServicesRef, StartDate
	) bce on bce.ClientServicesRef = l.clientservicesref and bce.StartDate = l.startdate
	JOIN mi.campaigndetailswave cw ON cw.ClientServicesRef = substring(l.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', l.clientservicesref, 0), 0), 99)) AND cw.StartDate = l.StartDate
	WHERE CAST(CalcDate AS DATE) =CAST(GETDATE() AS DATE) and ExtendedPeriod = 0

	UNION ALL

	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, 
		w.ControlGroupSize 'Internal Control Group Size', w.ControlGroup 'Internal Control Group', w.SalesUplift 'Internal Sales Uplift', w.SignificantUpliftSPC 'Internal SignificantUpliftSPC',
		we.ControlGroupSize 'External Control Group Size',  we.ControlGroup 'External Control Group', we.SalesUplift 'External Sales Uplift', we.SignificantUpliftSPC 'External SignificantUpliftSPC',
		w.Sales, w.Commission
		,CASE 
			WHEN w.SalesUplift > 0.5 THEN 'High (Internal)'
			WHEN w.SalesUplift < 0 THEN 'Low (Internal)'
			WHEN we.SalesUplift > 0.5 THEN 'High (External)'
			WHEN we.SalesUplift < 0 THEN 'Low (External)'
			ELSE '-' 
		END UpliftCheck
		,CASE 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) > ABS(bc.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (Segment Internal)' 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) < ABS(bc.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (Segment Internal)' 
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) > ABS(bce.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (Segment External)'
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) < ABS(bce.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (Segment External)'
			ELSE '-' 
		END IncrementalSalesCheck
	FROM mi.CampaignReportLog l
	JOIN MI.CampaignInternalResultsFinalWave w ON w.ClientServicesRef = l.ClientServicesRef AND w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsFinalWave we ON we.ClientServicesRef = l.ClientServicesRef AND we.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment
		GROUP BY ClientServicesRef, StartDate
	) bc on bc.ClientServicesRef = l.ClientServicesRef and bc.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment
		GROUP BY ClientServicesRef, StartDate
	) bce on bce.ClientServicesRef = l.clientservicesref and bce.StartDate = l.startdate
	JOIN mi.campaigndetailswave cw ON cw.ClientServicesRef = substring(l.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', l.clientservicesref, 0), 0), 99)) AND cw.StartDate = l.StartDate
	WHERE CAST(CalcDate AS DATE) =CAST(GETDATE() AS DATE) and ExtendedPeriod = 0

	UNION ALL

	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, 
		w.ControlGroupSize 'Internal Control Group Size', w.ControlGroup 'Internal Control Group', w.SalesUplift 'Internal Sales Uplift', w.SignificantUpliftSPC 'Internal SignificantUpliftSPC',
		we.ControlGroupSize 'External Control Group Size',  we.ControlGroup 'External Control Group', we.SalesUplift 'External Sales Uplift', we.SignificantUpliftSPC 'External SignificantUpliftSPC',
		w.Sales, w.Commission
		,CASE 
			WHEN w.SalesUplift > 0.5 THEN 'High (Internal)'
			WHEN w.SalesUplift < 0 THEN 'Low (Internal)'
			WHEN we.SalesUplift > 0.5 THEN 'High (External)'
			WHEN we.SalesUplift < 0 THEN 'Low (External)'
			ELSE '-' 
		END UpliftCheck
		,CASE 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) > ABS(bc.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (SuperSegment Internal)' 
			WHEN bc.ClientServicesRef is not null AND ABS(w.IncrementalSales) < ABS(bc.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (SuperSegment Internal)' 
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) > ABS(bce.IncrementalSales)*(1+@IncSalesPerc) THEN 'Wave Above (SuperSegment External)'
			WHEN bce.ClientServicesRef is not null AND ABS(we.IncrementalSales) < ABS(bce.IncrementalSales)*(1-@IncSalesPerc) THEN 'Wave Below (SuperSegment External)'
			ELSE '-' 
		END IncrementalSalesCheck
	FROM mi.CampaignReportLog l
	JOIN MI.CampaignInternalResultsFinalWave w ON w.ClientServicesRef = l.ClientServicesRef AND w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsFinalWave we ON we.ClientServicesRef = l.ClientServicesRef AND we.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment
		GROUP BY ClientServicesRef, StartDate
	) bc on bc.ClientServicesRef = l.ClientServicesRef and bc.StartDate = l.StartDate
	LEFT JOIN 
	(
		SELECT ClientServicesRef, StartDate, SUM(IncrementalSales) IncrementalSales
		FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment
		GROUP BY ClientServicesRef, StartDate
	) bce on bce.ClientServicesRef = l.clientservicesref and bce.StartDate = l.startdate
	JOIN mi.campaigndetailswave cw ON cw.ClientServicesRef = substring(l.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', l.clientservicesref, 0), 0), 99)) AND cw.StartDate = l.StartDate
	WHERE CAST(CalcDate AS DATE) =CAST(GETDATE() AS DATE) and ExtendedPeriod = 0

	) x
) b ON b.ClientServicesRef = a.ClientServicesRef AND b.StartDate = a.StartDate AND b.MaxEndDate = a.MaxEndDate

JOIN (
-- Check AdjFactor Capped
-- If the AdjFactor is set to capped

	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate
		, CASE WHEN a.isCapped = 1 OR ae.IsCapped = 1 THEN 'Capped' ELSE '-' END AdjFactorCapCheck
	 FROM mi.CampaignReportLog l
	LEFT JOIN mi.CampaignInternalResults_AdjFactor a ON a.ClientServicesRef = l.ClientServicesRef and a.StartDate = l.StartDate AND a.isCapped = 1
	LEFT JOIN MI.CampaignExternalResults_AdjFactor ae on ae.ClientServicesRef = l.ClientServicesRef and ae.StartDate = l.StartDate and ae.IsCapped = 1
	JOIN mi.campaigndetailswave cw ON cw.ClientServicesRef = substring(l.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', l.clientservicesref, 0), 0), 99)) AND cw.StartDate = l.StartDate
	WHERE CAST(CalcDate AS DATE) =CAST(GETDATE() AS DATE) and ExtendedPeriod = 0
) c ON c.ClientServicesRef = a.ClientServicesRef AND c.StartDate = a.StartDate AND c.MaxEndDate = a.MaxEndDate


END




