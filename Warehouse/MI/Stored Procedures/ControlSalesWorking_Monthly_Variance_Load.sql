-- =============================================
-- Author:		Dorota
-- Create date:     02/01/2015
-- Description:	Control Sales Monthly Variance
-- =============================================
CREATE PROCEDURE [MI].[ControlSalesWorking_Monthly_Variance_Load] (@DateID int, @Partnerid int, @ControlPartnerid int)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @DateID as int, @Partnerid as int, @ControlPartnerid as int
--set @DateID = 36
--SET @Partnerid = 3730
--Set @ControlPartnerid = 3730

SELECT DISTINCT SUT.FanID
	  ,1 as Programid
	  ,0 as PartnerGroupID 
	  ,SUT.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,SUT.PaymentTypeID as PaymentTypeID
	  ,0 as ChannelID
	  ,0 as CustomerAttributeID
	  ,0 as Mid_SplitID
	  ,0 as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
       ,SUM(Amount) as ControlSales
	  ,Count(*) as ControlTransactions
       ,Count(distinct SUT.FanID) as ControlSpenders
INTO #Sales	
FROM Relational.SchemeUpliftTrans SUT
inner join Relational.Control_Stratified CON on
		CON.FanID = SUT.FanID AND CON.monthid = @DateID AND CON.Partnerid = @ControlPartnerid 
inner join Relational.SchemeUpliftTrans_Month SUTM
		on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and SUTM.id=@DateID
--left Join MI.OutletAttribute OA 
--		on OA.OutletID = SUT.OutletID AND SUT.AddedDate between OA.StartDate and OA.EndDate
where     SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		SUT.PartnerID = @Partnerid 
Group BY SUT.PartnerID, isnull(CON.ClientServicesRef,'0'), SUT.FanID, SUT.PaymentTypeID,
CUBE(SUT.PaymentTypeID)

UPDATE #Sales
SET PaymentTypeID=0 
WHERE PaymentTypeID IS NULL

SELECT CON.FanID  
	  ,1 as Programid
	  ,0 as PartnerGroupID 
	  ,@PartnerID as PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,1 as PaymentTypeID
	  ,0 as CustomerAttributeID
	  ,0 as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
       ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
INTO #Customers	
FROM  Relational.Control_Stratified CON 
--CROSS JOIN MI.RetailerMetricPaymentypes p
WHERE CON.monthid = @DateID AND CON.Partnerid = @ControlPartnerid 
--and p.PaymentID<>2 and p.ProgramID=1
GROUP BY isnull(CON.ClientServicesRef,'0'), CON.FanID

INSERT INTO MI.ControlSalesWorking_Variance
SELECT c.Programid
	 ,c.PartnerGroupID
	 ,c.PartnerID
	 ,c.ClientServiceRef
	 ,c.PaymentTypeID
	 ,0 ChannelID
	 ,0 CustomerAttributeID
	 ,0 Mid_SplitID
	 ,c.CumulativeTypeID
	 ,c.PeriodTypeID
	 ,c.DateID
	 ,Varp(coalesce(1.0*ControlSales,0)) SPC_Var
	 ,Varp(1.0*ControlSales) SPS_Var
	 ,(1.0*count(distinct s.FanID)/count(distinct c.FanID))*(1.0*(count(distinct c.FanID)-count(distinct s.FanID))/count(distinct c.FanID)) RR_Var
FROM #Customers c
Left Join #Sales s on c.FanID=s.FanID and c.Programid=s.Programid 
and c.PartnerID=s.PartnerID and c.ClientServiceRef=s.ClientServiceRef
and c.PaymentTypeID=s.PaymentTypeID and c.CumulativeTypeID=s.CumulativeTypeID
and c.PeriodTypeID=s.PeriodTypeID and c.DateID=s.DateID 
GROUP BY c.Programid
	 ,c.PartnerGroupID
	 ,c.PartnerID
	 ,c.ClientServiceRef
	 ,c.PaymentTypeID
	 ,c.CumulativeTypeID
	 ,c.PeriodTypeID
	 ,c.DateID

DROP TABLE #Sales
DROP TABLE #Customers

END



