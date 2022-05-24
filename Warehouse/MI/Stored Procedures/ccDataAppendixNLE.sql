-- =============================================
-- Author:		<Adam Scott>
-- Create date: <10/02/2015>
-- Description:	<DataAppendixNLE>
-- =============================================
CREATE PROCEDURE [MI].[ccDataAppendixNLE] (@DateID int, @PartnerID int, @ClientServicesRef nvarchar(20), @CumulativeTypeID INT)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
--Declare @Dateid int, @partnerid int, @ClientServicesRef nvarchar
--set @Dateid = 37
--set @partnerid = 3960
--set @ClientServicesRef = '0'

DECLARE @CustAtt01 int, @CustAtt03 int, @CustAtt04 int

IF @CumulativeTypeID = 1
BEGIN
	SET @CustAtt01 = 1001
	SET @CustAtt03 = 1003
	SET @CustAtt04 = 1004
END
ELSE
BEGIN
	SET @CustAtt01 = 2001
	SET @CustAtt03 = 2003
	SET @CustAtt04 = 2004
END

select max(CA.ReportDescription) as ReportDescription,case when @PartnerID <> 3960 then  AA.CustomerAttributeID else case when aa.CustomerAttributeID = @CustAtt01 then @CustAtt01 else @CustAtt04 end end as CustomerAttributeID,CA.Description as CustomerAttribute, SUM(MembersCardholders) as MembersCardholders, SUM(MembersPostActivationSales) as MembersPostActivationSales, Sum(MembersPostActivationSpenders) as MembersPostActivationSpenders, 
Sum(MembersPostActivationTransactions) as MembersPostActivationTransactions, 
SUM(MembersSales) as MembersSales, SUM(MembersSpenders) as MembersSpenders, SUM(MembersTransactions) as MembersTransactions, SUM(Commission) as Commission,
SUM(ControlCardHolders) as ControlCardHolders, SUM(Controlsales) as Controlsales, SUM(ControlSpenders) as ControlSpenders, SUM(ControlTransactions) as ControlTransactions, 
SUM(AdjFactorRR) as AdjFactorRR, SUM(AdjFactorSPC) as AdjFactorSPC, SUM(AdjFactorTPC) as AdjFactorTPC, SUM(MonthlyMembersCardholders) as MonthlyMembersCardholders,
SUM(MonthlyMembersPostActivationSales) as MonthlyMembersPostActivationSales,
SUM(MonthlyMembersPostActivationSpenders) as MonthlyMembersPostActivationSpenders,
SUM(MonthlyMembersPostActivationTransactions) as MonthlyMembersPostActivationTransactions,
SUM(MonthlyMembersSales) as MonthlyMembersSales,
SUM(MonthlyMembersSpenders) as MonthlyMembersSpenders,
SUM(MonthlyMembersTransactions) as MonthlyMembersTransactions,
SUM(MonthlyCommission) as MonthlyCommission,
SUM(MonthlyControlCardHolders) as MonthlyControlCardHolders,
SUM(MonthlyControlsales) as MonthlyControlsales,
SUM(MonthlyControlSpenders) as MonthlyControlSpenders,
SUM(MonthlyControlTransactions) as MonthlyControlTransactions,
SUM(MonthlyAdjFactorRR) as MonthlyAdjFactorRR,
SUM(MonthlyAdjFactorSPC) as MonthlyAdjFactorSPC,
SUM(MonthlyAdjFactorTPC) as MonthlyAdjFactorTPC,
max(Margin) as Margin

from (
Select isw.CustomerAttributeID, MSW.MembersCardholders, Msw.MembersPostActivationSales, MSW.MembersPostActivationSpenders, MSW.MembersPostActivationTransactions, 
MSW.MembersSales, MSW.MembersSpenders, MSW.MembersTransactions, ISW.Commission,
CSW.ControlCardHolders, CSW.Controlsales, CSW.ControlSpenders, Csw.ControlTransactions, CSW.AdjFactorRR, CSW.AdjFactorSPC, CSW.AdjFactorTPC, 0 as MonthlyMembersCardholders,
0 as MonthlyMembersPostActivationSales,
0 as MonthlyMembersPostActivationSpenders,
0 as MonthlyMembersPostActivationTransactions,
0 as MonthlyMembersSales,
0 as MonthlyMembersSpenders,
0 as MonthlyMembersTransactions,
0 as MonthlyCommission,
0 as MonthlyControlCardHolders,
0 as MonthlyControlsales,
0 as MonthlyControlSpenders,
0 as MonthlyControlTransactions,
0 as MonthlyAdjFactorRR,
0 as MonthlyAdjFactorSPC,
0 as MonthlyAdjFactorTPC
,rm.Margin

from mi.RetailerReportMetric ISW 
inner join MI.MemberssalesWorking MSW on ISW.PartnerID = MSW.PartnerID 
and ISW.ClientServiceRef = MSW.ClientServiceRef 
and ISW.ChannelID = MSW.ChannelID
and ISW.CustomerAttributeID = MSW.CustomerAttributeID
and ISW.DateID = MSW.DateID
and ISW.Mid_SplitID = MSW.Mid_SplitID
and ISW.PaymentTypeID = MSW.PaymentTypeID
and ISW.CumulativeTypeID = MSW.CumulativeTypeID
Inner join MI.ControlSalesWorking CSW on ISW.PartnerID = CSW.PartnerID 
and ISW.ClientServiceRef = CSW.ClientServiceRef 
and ISW.ChannelID = CSW.ChannelID
and ISW.CustomerAttributeID = CSW.CustomerAttributeID
and ISW.DateID = CSW.DateID
and ISW.Mid_SplitID = CSW.Mid_SplitID
and ISW.PaymentTypeID = CSW.PaymentTypeID
and ISW.CumulativeTypeID = CSW.CumulativeTypeID
inner join MI.RetailerReportMetric RM on ISW.PartnerID = RM.PartnerID 
and ISW.ClientServiceRef = RM.ClientServiceRef 
and ISW.ChannelID = RM.ChannelID
and ISW.CustomerAttributeID = RM.CustomerAttributeID
and ISW.DateID = RM.DateID
and ISW.Mid_SplitID = RM.Mid_SplitID
and ISW.PaymentTypeID = RM.PaymentTypeID
and ISW.CumulativeTypeID = RM.CumulativeTypeID

where ISW.DateID = @DateID
and isw.PartnerID = @PartnerID
and ISW.ClientServiceRef = @ClientServicesRef
and isw.ChannelID =0
and isw.Mid_SplitID = 0
and isw.PaymentTypeID = 0 
and isw.CumulativeTypeID = @CumulativeTypeID
and isw.CustomerAttributeID between @CustAtt01 and @CustAtt03

union all


Select isw.CustomerAttributeID, 0 as MembersCardholders, 0 as MembersPostActivationSales, 0 as MembersPostActivationSpenders, 0 as MembersPostActivationTransactions, 
0 as MembersSales, 0 as MembersSpenders, 0 as MembersTransactions, 0 as Commission,
0 as ControlCardHolders, 0 as Controlsales, 0 as ControlSpenders, 0 as ControlTransactions, 0 as AdjFactorRR, 0 as AdjFactorSPC, 0 as AdjFactorTPC, MSW.MembersCardholders as MonthlyMembersCardholders,
Msw.MembersPostActivationSales as MonthlyMembersPostActivationSales,
MSW.MembersPostActivationSpenders as MonthlyMembersPostActivationSpenders,
MSW.MembersPostActivationTransactions as MonthlyMembersPostActivationTransactions,
MSW.MembersSales as MonthlyMembersSales,
MSW.MembersSpenders as MonthlyMembersSpenders,
MSW.MembersTransactions as MonthlyMembersTransactions,
ISW.Commission as MonthlyCommission,
CSW.ControlCardHolders as MonthlyControlCardHolders,
CSW.Controlsales as MonthlyControlsales,
CSW.ControlSpenders as MonthlyControlSpenders,
Csw.ControlTransactions as MonthlyControlTransactions,
CSW.AdjFactorRR as MonthlyAdjFactorRR,
CSW.AdjFactorSPC as MonthlyAdjFactorSPC,
CSW.AdjFactorTPC as MonthlyAdjFactorTPC
,rm.Margin

from mi.RetailerReportMetric ISW 
inner join MI.MemberssalesWorking MSW on ISW.PartnerID = MSW.PartnerID 
and ISW.ClientServiceRef = MSW.ClientServiceRef 
and ISW.ChannelID = MSW.ChannelID
and ISW.CustomerAttributeID = MSW.CustomerAttributeID

and ISW.DateID = MSW.DateID
and ISW.Mid_SplitID = MSW.Mid_SplitID
and ISW.PaymentTypeID = MSW.PaymentTypeID
and ISW.CumulativeTypeID = MSW.CumulativeTypeID
Inner join MI.ControlSalesWorking CSW on ISW.PartnerID = CSW.PartnerID 
and ISW.ClientServiceRef = CSW.ClientServiceRef 
and ISW.ChannelID = CSW.ChannelID
and ISW.CustomerAttributeID = CSW.CustomerAttributeID

and ISW.DateID = CSW.DateID
and ISW.Mid_SplitID = CSW.Mid_SplitID
and ISW.PaymentTypeID = CSW.PaymentTypeID
and ISW.CumulativeTypeID = CSW.CumulativeTypeID
inner join MI.RetailerReportMetric RM on ISW.PartnerID = RM.PartnerID 
and ISW.ClientServiceRef = RM.ClientServiceRef 
and ISW.ChannelID = RM.ChannelID
and ISW.CustomerAttributeID = RM.CustomerAttributeID

and ISW.DateID = RM.DateID
and ISW.Mid_SplitID = RM.Mid_SplitID
and ISW.PaymentTypeID = RM.PaymentTypeID
and ISW.CumulativeTypeID = RM.CumulativeTypeID

where ISW.DateID = @DateID
and isw.PartnerID = @PartnerID
and ISW.ClientServiceRef = @ClientServicesRef
and isw.ChannelID =0

and isw.Mid_SplitID = 0
and isw.PaymentTypeID = 0 
and isw.CumulativeTypeID = 0 
and isw.CustomerAttributeID between @CustAtt01 and @CustAtt03
)aa inner join MI.RetailerMetricCustomerAttribute CA on CA.CustomerAttributeID = (case when @PartnerID <> 3960 then  AA.CustomerAttributeID else case when aa.CustomerAttributeID = @CustAtt01 then @CustAtt01 else @CustAtt04 end end)



group by CA.Description,case when @PartnerID <> 3960 then  AA.CustomerAttributeID else case when aa.CustomerAttributeID = @CustAtt01 then @CustAtt01 else @CustAtt04 end end
--having not (@PartnerID = 3960 and ca.CustomerAttributeID in (2002,2003)) 

END