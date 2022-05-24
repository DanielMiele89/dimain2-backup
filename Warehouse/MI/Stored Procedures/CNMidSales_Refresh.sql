
/**********************************************************************

	Author:		Hayden Reid
	Create date:	28/06/2016
	Description:	Gets the total sales for each MID owned by both of Caffe Nero's
				partner records across MyRewards and nFI publishers
***********************************************************************/


CREATE PROCEDURE [MI].[CNMidSales_Refresh]
AS
BEGIN
	SET NOCOUNT ON;
	
    TRUNCATE TABLE MI.CNMidSales

    DECLARE @StartDate DATE, @EndDate DATE;

    SET @StartDate = DATEADD(WEEK, ((DATEDIFF(DAY, '2016-04-28', GETDATE())/28)-1)*4, '2016-04-28')
    SET @EndDate = DATEADD(WEEK, ((DATEDIFF(DAY, '2016-04-28', GETDATE())/28)-1)*4, '2016-05-25')

    ;WITH mnths
    AS
    (
	   SELECT 1 as ID,  @StartDate as StartDate, @EndDate as EndDate
	   UNION ALL
	   SELECT ID+1, DATEADD(WEEK, -4, StartDate), DATEADD(WEEK, -4, EndDate)
	   FROM mnths
	   WHERE ID < 12
    )
    INSERT INTO MI.CNMidSales
    SELECT
	   'MyRewards' as Scheme
	   , m.StartDate
	   , m.EndDate
	   , o.MerchantID
	   , NULLIF(CONCAT(o.Address1, ISNULL(NULLIF(', ' + Address2, ', '), ''), ISNULL(NULLIF(', ' + o.City, ', '), '')), '') AS FullAddress
	   , SUM(pt.TransactionAmount)
	   , NULLIF(o.Postcode, '') PostCode
    FROM relational.partnertrans pt with (nolock)
    JOIN mnths m on pt.TransactionDate >= m.StartDate and pt.TransactionDate <= m.EndDate
    JOIN relational.outlet o on o.OutletID = pt.OutletID
    WHERE (pt.PartnerID = 4319 or pt.PartnerID = 4523)
	   AND pt.EligibleForCashBack = 1
    GROUP BY o.MerchantID, m.StartDate, m.EndDate
	   , CONCAT(o.Address1, ISNULL(NULLIF(', ' + Address2, ', '), ''), ISNULL(NULLIF(', ' + City, ', '), ''))
	   , PostCode

    UNION ALL

    SELECT
	   'nFI'
	   , m.StartDate
	   , m.EndDate
	   , o.MerchantID
	   , NULLIF(CONCAT(o.Address1, ISNULL(NULLIF(', ' + Address2, ', '), ''), ISNULL(NULLIF(', ' + o.City, ', '), '')), '') AS FullAddress
	   , SUM(pt.TransactionAmount)
	   , NULLIF(o.Postcode, '') PostCode
    FROM nfi.relational.partnertrans pt with (nolock)
    JOIN mnths m on pt.TransactionDate >= m.StartDate and pt.TransactionDate <= m.EndDate
    JOIN nfi.relational.outlet o on o.ID = pt.OutletID
    WHERE (pt.PartnerID = 4319 or pt.PartnerID = 4523)
    GROUP BY o.MerchantID, m.StartDate, m.EndDate
	   , CONCAT(o.Address1, ISNULL(NULLIF(', ' + Address2, ', '), ''), ISNULL(NULLIF(', ' + City, ', '), ''))
	   , PostCode

END


