
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<MI.WorkingCustomerCount_load>
-- =============================================
CREATE PROCEDURE [MI].[WorkingCustomerCount_load] (@dateid int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SET NOCOUNT ON;

        SELECT 
	   cs.ProgramID
	  ,0 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
	  into #cus
  FROM Mi.Staging_Customer_Temp cs
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
 
 insert into #cus
  	   SELECT 
	   cs.ProgramID
	  ,1 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
  FROM Mi.Staging_Customer_Temp cs
   Inner join [Relational].[CustomerPaymentMethodsAvailable] c
   ON CS.FanID = c.fanid 
   where c.[StartDate] <= cs.EndDate and (c.[EndDate] >= cs.StartDate or c.[EndDate] is null) and PaymentMethodsAvailableID in (0,2)
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3

 insert into #cus
  	   SELECT 
	   cs.ProgramID
	  ,2 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
  FROM Mi.Staging_Customer_Temp cs
   Inner join [Relational].[CustomerPaymentMethodsAvailable] c
   ON CS.FanID = c.fanid 
   where c.[StartDate] <= cs.EndDate and (c.[EndDate] >= cs.StartDate or c.[EndDate] is null) and PaymentMethodsAvailableID in (1,2)
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3

 insert into #cus
SELECT 
	   cs.ProgramID
	  ,0 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
  FROM Mi.Staging_Customer_TempCUMLandNonCore cs
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3

 insert into #cus
  	   SELECT 
	   cs.ProgramID
	  ,1 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
  FROM Mi.Staging_Customer_TempCUMLandNonCore cs
   Inner join [Relational].[CustomerPaymentMethodsAvailable] c
   ON CS.FanID = c.fanid 
   where c.[StartDate] <= cs.EndDate and (c.[EndDate] >= cs.StartDate or c.[EndDate] is null) and PaymentMethodsAvailableID in (0,2)
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3

 insert into #cus
  	   SELECT 
	   cs.ProgramID
	  ,2 as PaymentRegisteredWithid
	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,COUNT(DISTINCT cs.FanID)  Customers
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3
  FROM Mi.Staging_Customer_TempCUMLandNonCore cs
   Inner join [Relational].[CustomerPaymentMethodsAvailable] c
   ON CS.FanID = c.fanid 
   where c.[StartDate] <= cs.EndDate and (c.[EndDate] >= cs.StartDate or c.[EndDate] is null) and PaymentMethodsAvailableID in (1,2)
  GROUP BY cs.ProgramID
  	  ,cs.PartnerID
	  ,cs.ClientServicesRef
	  ,cs.CumulativeTypeID
	  ,cs.PeriodTypeID
	  ,cs.DateID
	  ,cs.CustomerAttributeID_0
	  ,cs.CustomerAttributeID_0BP
	  ,cs.CustomerAttributeID_1
	  ,cs.CustomerAttributeID_1BP
	  ,cs.CustomerAttributeID_2
	  ,cs.CustomerAttributeID_2BP
	  ,cs.CustomerAttributeID_3

SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
INTO #Customers	
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=0
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_0
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_0BP
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_1
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_1BP
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_2
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_2BP
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 
UNION ALL
SELECT  con.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,con.PaymentRegisteredWithid as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,con.PeriodTypeID
	  ,con.DateID 
      ,SUM(Customers) as CardHolders
FROM  #cus con
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_3
GROUP BY isnull(CON.ClientServicesRef,'0'),con.PaymentRegisteredWithid,con.CumulativeTypeID, con.ProgramID,CON.PartnerID, ca.CustomerAttributeID
,con.PeriodTypeID,con.DateID 

Update MI.MembersSalesWorking
set MembersCardholders = NC.Cardholders
From  MI.MemberssalesWorking MS 
inner join #Customers NC on NC.PartnerID = MS.PartnerID and NC.ClientServiceRef = MS.ClientServiceRef and NC.PaymentTypeID  = MS.PaymentTypeID
AND nc.CumulativeTypeID=ms.CumulativeTypeID AND nc.Programid=ms.Programid
AND nc.CustomerAttributeID=ms.CustomerAttributeID AND MS.DateID = nc.DateID and ms.PeriodTypeID=nc.PeriodTypeID
WHERE MS.DateID=@DateID

Update MI.INSchemeSalesWorking
set Cardholders = NC.Cardholders
From  MI.INSchemeSalesWorking MS 
inner join #Customers NC on NC.PartnerID = MS.PartnerID and NC.ClientServiceRef = MS.ClientServiceRef and NC.PaymentTypeID  = MS.PaymentTypeID
AND nc.CumulativeTypeID=ms.CumulativeTypeID AND nc.Programid=ms.Programid
AND nc.CustomerAttributeID=ms.CustomerAttributeID AND MS.DateID = nc.DateID and ms.PeriodTypeID=nc.PeriodTypeID
WHERE MS.DateID=@DateID

  DELETE FROM Warehouse.mi.memberssalesworking
  where MembersCardholders=0

  DELETE FROM MI.INSchemeSalesWorking
  where Cardholders=0

drop table #cus
drop table #Customers

END