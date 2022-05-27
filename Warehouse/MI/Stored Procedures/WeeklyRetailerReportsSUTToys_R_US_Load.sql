-- =============================================
-- Author:		<Adam SCOTT>
-- Create date: <26/08/2014>
-- Description:	<loads Control monthy for Toys R us>
-- =============================================
CREATE PROCEDURE [MI].[WeeklyRetailerReportsSUTToys_R_US_Load]
	-- Add the parameters for the stored procedure here
(@MonthID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


SELECT * 
INTO   #ch 
FROM  -- [Warehouse].[Relational].[campaign_history] CH
--inner join
 Relational.Control_Stratified CS-- on
	  -- CS.PartnerID = CH.PartnerID and
	   --CH.FanID = CS.FanID
WHERE  --grp = 'Control' 
        Cs.partnerid = 4494 
	  -- and IronOfferID not in (6927,6926,6928)
	   AND Cs.ClientServicesRef in ('TO001','TO002')
	   and CS.MonthID = @MonthID

ALTER TABLE #ch 
  ALTER COLUMN fanid INT NOT NULL 

ALTER TABLE #ch 
  ADD PRIMARY KEY (fanid) 

Create Index partner_
on  #ch (Partnerid) 

SELECT MAX(p.partnerid)          AS PartnerID, 
	   max(SUTW.ID) as WeekID,
       MAX(CH.partnerid)         AS p, 
       SUM(SUT.amount)           AS TranAmount, 
       COUNT(*)                  AS TranCount, 
       COUNT(DISTINCT SUT.fanid) AS CustomerNo, 
       CH.ClientServicesRef 
	   into #ConSplit
FROM  [Warehouse].[Relational].[schemeuplifttrans] AS SUT 
      INNER JOIN warehouse.relational.partner AS p 
              ON SUT.partnerid = p.partnerid 
      INNER JOIN #ch CH 
              ON CH.partnerid = p.partnerid 
                 AND CH.fanid = SUT.fanid 
	  --INNER JOIN Relational.Control_Stratified CON 
			--  ON CON.fanID = SUT.fanID and p.PartnerID = CON.PartnerID
	  INNER JOIN Relational.SchemeUpliftTrans_Week SUTW
			  ON SUT.addeddate between SUTW.StartDate and SUTW.EndDate
      INNER JOIN relational.schemeuplifttrans_month SUTM 
              ON SUTW.[MonthID]= SUTM.id --and CON.MonthID = SUTM.ID 
                 --AND CH.sdate <= SUTW.enddate 
                 --AND CH.edate >= SUTW.enddate 
      INNER JOIN mi.activeofferspartners_fetchnon AO 
              ON AO.partnerid = P.partnerid 
WHERE  SUTM.id = @MonthID
       AND SUT.amount > 0 
       AND SUT.isretailreport = 1 
       --AND CH.grp = 'Control' 
       AND CH.partnerid = 4494 
GROUP  BY SUTM.id,  SUTW.StartDate,
          p.partnerid, 
          CH.ClientServicesRef 
ORDER  BY SUTM.id , SUTW.StartDate
drop table #ch
--select * from #ConSplit
update [Warehouse].[MI].[RetailerReportWeekly]
set [ControlSpender] = CS.[CustomerNo]
,[Controlsales] = CS.[TranAmount]
,[ControlTrans]= CS.[TranCount]
 from [Warehouse].[MI].[RetailerReportWeekly] RW
 inner join #ConSplit CS on RW.PartnerID = CS.partnerid 
 	and RW.weekid = CS.weekid 
	and RW.ClientServicesRef = CS.ClientServicesRef 
	and RW.[LabelID] = 101 


drop table #ConSplit


END
