
/***********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Get the list of reports to generate

	Fetch reports that have not been created, have not errored and is for the ExtendedPeriod defined

	======================= Change Log =======================

	- 14/08/2015 Added check for final table to ensure that reports that have been removed from the 
	final table are not generated

	- 26/09/2016 Extended version has become legacy and removed from the code
	
	- 29/09/2016 Extended code added back. 
	  Extended version has been requested by Client Services and it has
	  been agreed that these calculations will only occur on an ad-hoc basis.

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Fetch_ReportGroups] 
    (@Extended bit = 0)
AS
BEGIN
	SET NOCOUNT ON;

	-- Get Params from Log Table
	SELECT DISTINCT
		w.ClientServicesRef,
		w.StartDate,
		ExtendedPeriod
	FROM MI.CampaignReportLog m
	JOIN MI.CampaignInternalResultsFinalWave w on w.ClientServicesRef = m.ClientServicesRef 
	   AND w.StartDate = m.StartDate
	WHERE IsError = 0
	   AND ExtendedPeriod = @Extended and reportdate is null
	   AND Status = 'Calculation Completed'
	   --AND m.ClientServicesRef like 'CN087'
	   --AND cast(calcdate as date) = '2015-12-10'
	   --AND substring(m.ClientServicesRef, 0, ISNULL(NULLIF(charindex('bespoke', m.clientservicesref, 0), 0), 99)) in ('WA061')
	   and not exists (
			 select 1 from mi.CampaignReport_OfferSplit o
			 where o.ClientServicesRef = m.ClientServicesRef
				 and o.SSOffer = 1 	   
		  )	  	   
END




