
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<loads MI.Staging_Customer_TempCUMLandNonCore>
-- =============================================
CREATE PROCEDURE [MI].[Staging_Customer_TempCUMLandNonCore_NONcore_load] (@DateID INT, @PartnerID INT, @CumulativetypeID INT , @ClientServiceRef nvarchar(30))
--	WITH EXECUTE AS OWNER
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Insert statements for procedure here
Declare --@DateID as int, 
@EndDate as Date,-- @partnerID as int,
--@ClientServiceRef nvarchar(30),
@StartDate as Date,
--@CumulativetypeID as int,
@cumstartdate as Date,
@StartDateID int,
@EndDateID int
--Set @partnerID = 4494
--Set @DateID = 34
--set @ClientServiceRef = 'to001'
--set @CumulativetypeID = 1
Select @cumstartdate =  StartDate from MI.WorkingCumlDates where Partnerid = @PartnerID and ClientServicesref = @ClientServiceRef and Cumlitivetype =@CumulativetypeID


set @StartDate = (select MIN(StartDate) from Relational.SchemeUpliftTrans_Month where id between (Select ID from Relational.SchemeUpliftTrans_Month where StartDate =  @cumstartdate) and  @DateID)
Set @EndDate = (select MAX(EndDate) from Relational.SchemeUpliftTrans_Month where id between (Select ID from Relational.SchemeUpliftTrans_Month where StartDate =  @cumstartdate) and  @DateID)

set @StartDateID = (select MIN(ID) from Relational.SchemeUpliftTrans_Month where id between (Select ID from Relational.SchemeUpliftTrans_Month where StartDate =  @cumstartdate) and  @DateID)
Set @EndDateID = (select MAX(ID) from Relational.SchemeUpliftTrans_Month where id between (Select ID from Relational.SchemeUpliftTrans_Month where StartDate =  @cumstartdate) and  @DateID)


select @DateID as DateID,  c.FanID,   @PartnerID as PartnerID , @ClientServiceRef as ClientServicesRef,
MIN(cap.ActivationStart) as [StartDate] ,Max(CASE WHEN ISNULL(cap.UpdatedDate,(CASE WHEN cap.AddedDate='2014-11-12' THEN '1900-01-01' ELSE cap.AddedDate END))<=dateadd(day,1,@EndDate) THEN cap.ActivationEnd END) as [EndDate]  -- Ignore deactivations that where added after month ended
, @CumulativetypeID as CumulativeTypeID
Into #cus_stage1
From Relational.Customer c
inner join Warehouse.Stratification.BaseOfferMembers_NonCore_Compressed s on c.FanID=s.FanID and s.PartnerID=@PartnerID and s.ClientServicesRef=@ClientServiceRef
and s.MinMonthID<=@EndDateID and s.MaxMonthID>=@StartDateID 
inner join MI.CustomerActivationPeriod cap
on cap.FanID = c.FanID
					 where cap.ActivationStart   <= @EndDate     
                     and      (cap.ActivationEnd >= @StartDate or cap.ActivationEnd is null)
					 and   (CASE WHEN cap.AddedDate='2014-11-12' THEN '1900-01-01' ELSE cap.AddedDate END)<=dateadd(day,1,@EndDate)  -- Ignore activations that where added after month ended
				group by c.fanid

SELECT * 
INTO  #ExistingCustomers_Rolling_Compressed
FROM   Stratification.ExistingCustomers_Rolling_Compressed ecr
WHERE ecr.PartnerID=@PartnerID 
and @DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
and ecr.ClientServicesref = @ClientServiceref 
and  @CumulativeTypeID=0 

CREATE CLUSTERED INDEX IND ON #ExistingCustomers_Rolling_Compressed(FanID)

SELECT * 
INTO  #ExistingCustomers_YTD
FROM  Stratification.ExistingCustomers_YTD ecy
WHERE ecy.PartnerID=@PartnerID 
and @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
and ecy.ClientServicesref = @ClientServiceref 
and @CumulativeTypeID IN (0,1)

CREATE CLUSTERED INDEX IND ON #ExistingCustomers_YTD(FanID)

SELECT * 
INTO  #ExistingCustomers
FROM  Stratification.ExistingCustomers ec
WHERE ec.PartnerID=@PartnerID 
and @DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
and ec.ClientServicesref = @ClientServiceref 
and @CumulativeTypeID IN (0,2)

CREATE CLUSTERED INDEX IND ON #ExistingCustomers(FanID)

SELECT * 
INTO  #NewSpendersCohort
FROM Stratification.NewSpendersCohort coh
WHERE coh.PartnerID=@PartnerID 
and coh.FirstMonth<=@DateID
and coh.ClientServicesref = @ClientServiceref 
AND  @CumulativeTypeID IN (0,2,1)

CREATE CLUSTERED INDEX IND ON #NewSpendersCohort(FanID)


SELECT c.*,
CustomerAttributeID_0=CASE WHEN ecr.CustType='E' THEN 3 WHEN ecr.CustType='L' THEN 2 WHEN c.CumulativeTypeID=0 THEN 1 END,
CustomerAttributeID_0BP=CASE WHEN c.PartnerID='3960' /*BP*/ AND  ecr.CustType IN ('E' ,'L') THEN 4 END,
CustomerAttributeID_1=CASE WHEN ecy.CustType='E' THEN 1003 WHEN ecy.CustType='L' THEN 1002 WHEN c.CumulativeTypeID IN (0,1) THEN 1001 END,
CustomerAttributeID_1BP=CASE WHEN c.PartnerID='3960' /*BP*/ AND  ecy.CustType IN ('E' ,'L') THEN 1004 END,
CustomerAttributeID_2=CASE WHEN ec.CustType='E' THEN 2003 WHEN ec.CustType='L' THEN 2002 WHEN c.CumulativeTypeID IN (0,2) THEN 2001 END,
CustomerAttributeID_2BP=CASE WHEN c.PartnerID='3960' /*BP*/ AND  ec.CustType IN ('E' ,'L') THEN 2004 END,
CustomerAttributeID_3=CASE WHEN c.CumulativeTypeID IN (0,1,2) THeN coh.FirstMonth+3000 END
into #cus
FROM #cus_stage1 c
LEFT JOIN #ExistingCustomers_Rolling_Compressed ecr
on ecr.FanID=c.FanID and ecr.PartnerID=c.PartnerID 
and c.DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
and ecr.ClientServicesref = c.ClientServicesref 
and  c.CumulativeTypeID=0
LEFT JOIN #ExistingCustomers_YTD ecy
on ecy.FanID=c.FanID and ecy.PartnerID=c.PartnerID 
and c.DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
and ecy.ClientServicesref = c.ClientServicesref 
and c.CumulativeTypeID IN (0,1)
LEFT JOIN #ExistingCustomers ec
on ec.FanID=c.FanID and ec.PartnerID=c.PartnerID 
and c.DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
and ec.ClientServicesref = c.ClientServicesref 
and c.CumulativeTypeID IN (0,2)
LEFT JOIN #NewSpendersCohort coh
on coh.FanID=c.FanID and coh.PartnerID=c.PartnerID 
and coh.FirstMonth<=c.DateID
and coh.ClientServicesref = c.ClientServicesref 
AND  c.CumulativeTypeID IN (0,2,1)

insert into MI.Staging_Customer_TempCUMLandNonCore (FanID,
ProgramID,
PartnerID,
ClientServicesRef,
CumulativeTypeID,
PeriodTypeID,
DateID,
StartDate,
EndDate,
CustomerAttributeID_0,
CustomerAttributeID_0BP,
CustomerAttributeID_1,
CustomerAttributeID_1BP,
CustomerAttributeID_2,
CustomerAttributeID_2BP,
CustomerAttributeID_3
)
SELECT distinct cs.FanID
	  ,1 as ProgramID
	  ,PartnerID
	  ,ClientServicesRef
	  ,@CumulativetypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,cs.DateID
	  ,cS.[StartDate] as StartDate
      ,isnull(cS.[EndDate], @EndDate) as EndDate
,CustomerAttributeID_0
,CustomerAttributeID_0BP
,CustomerAttributeID_1
,CustomerAttributeID_1BP
,CustomerAttributeID_2
,CustomerAttributeID_2BP
,CustomerAttributeID_3
FROM #cus CS 

--ALTER INDEX ALL ON MI.Staging_Customer_TempCUMLandNonCore REBUILD

Drop Table #cus_stage1
Drop Table #cus

DROP TABLE #ExistingCustomers_Rolling_Compressed
DROP TABLE  #ExistingCustomers_YTD
DROP TABLE  #ExistingCustomers
DROP TABLE  #NewSpendersCohort

END