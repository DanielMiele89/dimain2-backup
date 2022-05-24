
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Fetch the parameters that have been stored to calculate in the
	automated process

	======================= Change Log =======================

     26/09/2016 
	   - Extended version has become legacy and removed from the code
	
	29/09/2016 
	   - Extended code added back. 
	   Extended version has been requested by Client Services and it has
	   been agreed that these calculations will only occur on an ad-hoc basis.
	   

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_Params] 
    (@Extended bit = 0)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get Params from Log Table
	SELECT DISTINCT
		r.ClientServicesRef,
		r.StartDate
	FROM MI.CampaignReportLog r
	LEFT JOIN MI.CampaignReport_OfferSplit os ON os.ClientServicesRef = r.ClientServicesRef AND os.SSOffer = 0
	WHERE ReportDate IS NULL
		AND IsError = 0
		AND ExtendedPeriod = @Extended
		AND CAST(CalcDate as DATE) = CAST(GetDate() as DATE)
		and Status = 'Calculation Starting'
	--	and ClientServicesRef = 'HC010' /* Specific CS Ref */
   -- ORDER BY CASE ClientServicesRef WHEN 'HG003' THEN 'A' WHEN 'TC003' THEN 'A' ELSE 'Z' END /* Specific Ordering of calculation */

END