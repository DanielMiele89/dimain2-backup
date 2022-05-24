-- =============================================
-- Author:		<Adam Scott>
-- Create date: <27/05/2014>
-- Description:	<Cumulative monthly SUTNLE_fetch>
-- =============================================

CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeSUTNLE_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
DECLARE @startID INT 

SET @startID = (SELECT startmonthid 
                FROM   mi.schememarginsandtargets 
                WHERE  partnerid = @PartnerID) 

SELECT p.partnerid               AS PartnerID, 
       c.labelid, 
       MAX(SUTM.id)              AS MonthID, 
       SUM(SUT.amount)           AS ActivatedSales, 
       COUNT(*)                  AS ActivatedTrans, 
       COUNT(DISTINCT SUT.fanid) AS ActivatedSpender 
FROM   warehouse.relational.[schemeuplifttrans] AS SUT 
       INNER JOIN [Warehouse].[MI].[stagingcustomer_nle] AS c 
               ON SUT.fanid = c.fanid 
                  AND c.partnerid = sut.partnerid 
       INNER JOIN warehouse.relational.partner AS p 
               ON SUT.partnerid = p.partnerid 
       INNER JOIN relational.schemeuplifttrans_month SUTM 
               ON SUT.addeddate BETWEEN SUTM.startdate AND SUTM.enddate 
WHERE  SUT.isretailreport = 1 
       AND SUT.amount > 0 
       AND -- SUT.Amount is not null and 
       c.labelid IN ( 27, 28, 29 ) 
       AND SUTM.id BETWEEN @startID AND @MonthID 
       AND P.partnerid = @PartnerID 
       AND c.monthid = @MonthID 
GROUP  BY p.partnerid, 
          c.labelid 

END