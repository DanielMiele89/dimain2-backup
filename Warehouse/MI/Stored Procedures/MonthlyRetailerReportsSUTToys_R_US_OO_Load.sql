-- =============================================
-- Author:		<Adam SCOTT>
-- Create date: <26/08/2014>
-- Description:	<loads Control monthy for Toys R us>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyRetailerReportsSUTToys_R_US_OO_Load]
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

SELECT MAX(p.partnerid)          AS PartnerID,
		case when SUT.isonline = 1 then 102 else 103 end as lableid, 
       MAX(SUTM.id)              AS MonthID, 
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
      INNER JOIN relational.schemeuplifttrans_month SUTM 
              ON SUT.addeddate BETWEEN SUTM.startdate AND SUTM.enddate 
                 --AND CH.sdate <= SUTM.enddate 
                 --AND CH.edate >= SUTM.enddate 
      INNER JOIN mi.activeofferspartners_fetchnon AO 
              ON AO.partnerid = P.partnerid 
	inner join Relational.Control_Stratified CON
			  ON CON.fanID = SUT.fanID and P.PartnerID = Con.PartnerID and sutm.ID = CON.MonthID
WHERE  SUTM.id = @MonthID
       AND SUT.amount > 0 
       AND SUT.isretailreport = 1 
       --AND CH.grp = 'Control' 
       AND CH.partnerid = 4494 
GROUP  BY SUTM.id, 
          p.partnerid, 
		  case when SUT.isonline = 1 then 102 else 103 end,
          CH.ClientServicesRef
ORDER  BY SUTM.id 
drop table #ch
--select * from #ConSplit
update [Warehouse].[MI].[RetailerReportMonthly]
set [ControlSpender] = CS.[CustomerNo]
,[ControlCardholdersales] = CS.[TranAmount]
,[ControlTrans]= CS.[TranCount]
 from [Warehouse].[MI].[RetailerReportMonthly] RM
 inner join #ConSplit CS on RM.PartnerID = CS.partnerid 
 	and RM.Monthid = CS.Monthid
	and RM.ClientServicesRef  = CS.ClientServicesRef 
	and RM.[LabelID] = CS.lableid


drop table #ConSplit


END
