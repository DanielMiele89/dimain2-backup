﻿
-- =============================================
-- Author:		Dorota
-- Create date:	28/11/2014
-- Description:	Capping of Cumulative Incremental Speders in MI.RetailerReportMetric
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetricCumulativeFix_IncrementalSpenders]  (@DateID INT, @CumulativeTypeID INT, @PartnerID INT = NULL)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 Select 1 CumulativeTypeID, t.partnerid, m.Reporting_Start_MonthID StartMonthID, MAX(DateID) DateID 
	 into #OldPartners
	 from MI.RetailerReportMetric t 
	 left join Relational.Master_Retailer_Table m 
	 on m.PartnerID=t.PartnerID
	 where @CumulativeTypeID=1
	 and CumulativeTypeID=0
	 and t.DateID>=m.Reporting_Start_MonthID
	 AND (@PartnerID IS NULL OR t.PartnerID = @PartnerID)
	 group By t.partnerid, m.Reporting_Start_MonthID
	 UNION
	 Select 2 CumulativeTypeID, t.partnerid, 20 StartMonthID,  MAX(DateID) DateID 
	 from MI.RetailerReportMetric t 
	 left join Relational.Master_Retailer_Table m 
	 on m.PartnerID=t.PartnerID
	 where @CumulativeTypeID=2
	 and CumulativeTypeID=0
	 and t.DateID>=20
	 AND (@PartnerID IS NULL OR t.PartnerID = @PartnerID)
	 group By t.partnerid


  SELECT rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.Cumlitivetype CumulativeTypeID
      ,rm.PeriodTypeID
      ,d.DateID
	 ,SUM(IncrementalSpenders) MonthlyIncrementalSpenders
	 ,COUNT(DISTINCT rm.DateID) Months
  INTO #NewValues
  FROM MI.RetailerReportMetric rm
  INNER JOIN MI.WorkingCumlDates d ON rm.PartnerID=d.PartnerID and rm.ClientServiceRef=d.ClientServicesRef 
  AND d.Cumlitivetype=@CumulativeTypeID AND d.DateID=@DateID
  WHERE rm.DateID BETWEEN d.StartMonthID AND d.DateID
  AND rm.CumulativeTypeID=0
  AND (@PartnerID IS NULL OR rm.PartnerID = @PartnerID)
  GROUP BY rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.Cumlitivetype 
      ,rm.PeriodTypeID
      ,d.DateID  
UNION
 SELECT rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.CumulativeTypeID CumulativeTypeID
      ,rm.PeriodTypeID
      ,@DateID
	 ,SUM(IncrementalSpenders) MonthlyIncrementalSpenders
	 ,COUNT(DISTINCT rm.DateID) Months
  FROM MI.RetailerReportMetric rm
  INNER JOIN #OldPartners d ON rm.PartnerID=d.PartnerID 
  AND d.CumulativeTypeID=@CumulativeTypeID AND d.DateID<@DateID
  WHERE rm.DateID BETWEEN d.StartMonthID AND d.DateID
  AND rm.CumulativeTypeID=0
  GROUP BY rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.CumulativeTypeID
      ,rm.PeriodTypeID
	  

Update MI.RetailerReportMetric
SET IncrementalSpenders=Stratification.least (rm.IncrementalSpenders,n.MonthlyIncrementalSpenders),
UpliftSpenders=1.0*Stratification.least (rm.IncrementalSpenders,n.MonthlyIncrementalSpenders)/Stratification.greatest (rm.Spenders- Stratification.least (rm.IncrementalSpenders,n.MonthlyIncrementalSpenders),1)
FROM MI.RetailerReportMetric rm
INNER JOIN #NewValues n 
ON rm.ProgramID=n.ProgramID
AND rm.PartnerGroupID=n.PartnerGroupID
AND rm.PartnerID=n.PartnerID
AND rm.ClientServiceRef=n.ClientServiceRef
AND rm.PaymentTypeID=n.PaymentTypeID
AND rm.ChannelID=n.ChannelID
AND rm.CustomerAttributeID=n.CustomerAttributeID
AND rm.Mid_SplitID=n.Mid_SplitID
AND rm.CumulativeTypeID=n.CumulativeTypeID
AND rm.PeriodTypeID=n.PeriodTypeID
AND rm.DateID=n.DateID
and rm.CustomerAttributeID =0
DROP TABLE #NewValues
DROP TABLE #OldPartners

END

