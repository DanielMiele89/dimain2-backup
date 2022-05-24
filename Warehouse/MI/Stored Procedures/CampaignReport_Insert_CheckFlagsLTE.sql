
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Insert Checks after a calculation has run for LTE

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_CheckFlagsLTE]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


-- If this is ClientServicesRef and StartDate is in the CheckFlagsLTE table then set it as archived
UPDATE c 
SET Archived = 1
FROM MI.CampaignReport_CheckFlagsLTE c
JOIN MI.CampaignReportlog l ON l.clientservicesref = c.clientservicesref AND l.startdate = c.startdate
WHERE CAST(CalcDate AS DATE) = CAST(GETDATE() AS DATE) AND ExtendedPeriod = 1
	
INSERT INTO MI.CampaignReport_CheckFlagsLTE
(
	[ClientServicesRef]
      ,[StartDate]
      ,[MaxEndDate]
      ,[InternalControlGroup]
      ,[ExternalControlGroup]
      ,[Cardholders]
      ,[Sales]
      ,[Commission]
      ,[IncrementalSales_Internal]
      ,[IncrementalSales_External]
      ,[Cardholders_Awareness]
      ,[Sales_Awareness]
      ,[IncrementalSales_Internal_Awareness]
      ,[IncrementalSales_External_Awareness]
      ,[Cardholders_Loyalty]
      ,[Sales_Loyalty]
      ,[IncrementalSales_Internal_Loyalty]
      ,[IncrementalSales_External_Loyalty]
      ,[AwarenessCheck]
      ,[LoyaltyCheck]
	  ,[CampaignName]
      ,[UpliftCardholders_Perc_Internal_Awareness]
      ,[UpliftCardholders_Perc_External_Awareness]
      ,[UpliftCardholders_Perc_Internal_Loyalty]
      ,[UpliftCardholders_Perc_External_Loyalty]
)

	
-- Check Awareness/Loyalty effect
-- If awareness results have a 0 value in incremental sales 
-- If loyalty results have a 0 value in incremental sales 


SELECT x.ClientServicesRef, x.StartDate, x.MaxEndDate, x.[Internal Control Group], x.[External Control Group], x.Cardholders, x.Sales, x.Commission, 
	x.[Incremental Sales Internal], x.[Incremental Sales External],
	x.[Awareness - Cardholders], [Awareness - Sales], [IncrementalSales - Internal - Awareness], [IncrementalSales - External - Awareness],
	y.[Loyalty - Cardholders], [Loyalty - Sales], [IncrementalSales - Internal - Loyalty], [IncrementalSales - External - Loyalty],
	CASE WHEN x.[IncrementalSales - Internal - Awareness] = 0 OR [IncrementalSales - External - Awareness] = 0 THEN 'Inc Sales = 0' ELSE '-' END 'Awareness Check',
	CASE WHEN y.[IncrementalSales - Internal - Loyalty] = 0 OR [IncrementalSales - External - Loyalty] = 0 THEN 'Inc Sales = 0' ELSE '-' END 'Loyalty Check',
	CampaignName, x.UpliftCardholders_Perc_Internal_Awareness, x.UpliftCardholders_Perc_External_Awareness, y.UpliftCardholdersPerc_Internal_Loyalty, y.UpliftCardholdersPerc_External_Loyalty
FROM (
	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.ControlGroup 'Internal Control Group', we.ControlGroup 'External Control Group', 
		w.Cardholders, w.Sales, w.Commission, 
		w.IncrementalSales 'Incremental Sales Internal', we.IncrementalSales 'Incremental Sales External',
		lw.IncrementalSales 'IncrementalSales - Internal - Awareness',	lwe.IncrementalSales 'IncrementalSales - External - Awareness',
		lw.CardHolders 'Awareness - Cardholders', lw.Sales 'Awareness - Sales', cw.CampaignName, lw.UpliftCardholders_Perc 'UpliftCardholders_Perc_Internal_Awareness',
		lwe.UpliftCardholders_Perc 'UpliftCardholders_Perc_External_Awareness'
	FROM MI.CampaignReportLog l
	JOIN MI.CampaignInternalResultsFinalWave w on w.ClientServicesRef = l.ClientServicesRef and w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsFinalWave we on we.ClientServicesRef = l.ClientServicesRef and we.StartDate = l.StartDate
	JOIN MI.CampaignInternalResultsLTEFinalWave lw on lw.ClientServicesRef = l.ClientServicesRef and lw.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsLTEFinalWave lwe on lwe.ClientServicesRef = l.ClientServicesRef and lwe.StartDate = l.StartDate and lwe.Effect = lw.Effect
	JOIN MI.CampaignDetailsWave cw on cw.ClientServicesRef = l.ClientServicesRef and cw.StartDate = l.StartDate
	WHERE cast(CalcDate as Date) = cast(getdate() as date) and lw.Effect = 'Awareness' and ExtendedPeriod = 1 and IsError = 0
) x
JOIN (
	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.ControlGroup 'Internal Control Group', we.ControlGroup 'External Control Group', 
		w.Cardholders, w.Sales, w.Commission, 
		w.IncrementalSales 'Incremental Sales Internal', we.IncrementalSales 'Incremental Sales External',
		lw.IncrementalSales 'IncrementalSales - Internal - Loyalty', lwe.IncrementalSales 'IncrementalSales - External - Loyalty',
		lw.CardHolders 'Loyalty - Cardholders', lw.Sales 'Loyalty - Sales', lw.UpliftCardholders_Perc 'UpliftCardholdersPerc_Internal_Loyalty',
		lwe.UpliftCardholders_Perc 'UpliftCardholdersPerc_External_Loyalty'
	FROM MI.CampaignReportLog l
	JOIN MI.CampaignInternalResultsFinalWave w on w.ClientServicesRef = l.ClientServicesRef and w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsFinalWave we on we.ClientServicesRef = l.ClientServicesRef and we.StartDate = l.StartDate
	JOIN MI.CampaignInternalResultsLTEFinalWave lw on lw.ClientServicesRef = l.ClientServicesRef and lw.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsLTEFinalWave lwe on lwe.ClientServicesRef = l.ClientServicesRef and lwe.StartDate = l.StartDate and lwe.Effect = lw.Effect
	JOIN MI.CampaignDetailsWave cw on cw.ClientServicesRef = l.ClientServicesRef and cw.StartDate = l.StartDate
	WHERE cast(CalcDate as Date) = cast(getdate() as date) and lw.Effect = 'Loyalty' and ExtendedPeriod = 1 and isError = 0
) y on y.ClientServicesRef = x.ClientServicesRef and y.StartDate = x.StartDate

END