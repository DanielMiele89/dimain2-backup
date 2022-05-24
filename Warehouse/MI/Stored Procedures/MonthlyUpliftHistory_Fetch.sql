
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Fetches monthly uplift results
***********************************************************************/
CREATE PROCEDURE [MI].[MonthlyUpliftHistory_Fetch]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    ;WITH PartnerDateList
    AS 
    (
		  SELECT DISTINCT y.ID AS DateID, MonthDesc, ClientServiceRef, PartnerID FROM MI.RetailerReportMetric rrm
		  CROSS JOIN
		  (
			 SELECT ID, MonthDesc FROM Relational.SchemeUpliftTrans_Month sutm
			 WHERE ID >= 20 AND ID <= (SELECT max(dateid) FROM mi.RetailerReportMetric rrm)
		  ) y
    )
    SELECT 
	   CASE WHEN x.ClientServiceRef <> '0' THEN p.PartnerName + ' ' + x.ClientServiceRef ELSE p.PartnerName END as PartnerName,
	   x.PartnerID, x.ClientServiceRef
	   , UpliftSales
	   , x.DateID
	   , MonthDesc
	   , CAST(IncrementalSales as float) as IncrementalSales
	   , (SELECT MAX(DateID) FROM MI.RetailerReportMetric m where m.PartnerID = x.PartnerID and m.ClientServiceRef = x.ClientServiceRef) - 12 as MaxDate
    FROM PartnerDateList x
    JOIN Relational.Partner p on p.PartnerID = x.PartnerID
    LEFT JOIN MI.RetailerReportMetric rrm ON rrm.PartnerID = x.PartnerID 
	   AND rrm.ClientServiceRef = x.ClientServiceRef
	   AND rrm.DateID = x.DateID 
	   AND rrm.PaymentTypeID = 0 
	   AND rrm.ChannelID = 0 
	   AND rrm.Mid_SplitID = 0 
	   AND rrm.CumulativeTypeID = 0 
	   AND rrm.CustomerAttributeID = 0
    ORDER BY p.PartnerName, ID

END