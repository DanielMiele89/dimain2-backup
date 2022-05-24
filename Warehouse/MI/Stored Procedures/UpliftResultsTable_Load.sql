
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <04/11/2014>
-- Description:	<Loads UpliftResultsTable>
-- Edited 11:11:11 11/11/2013
-- =============================================
CREATE PROCEDURE [MI].[UpliftResultsTable_Load] (@DateID AS INT, @PartnerID INT = NULL) 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--	declare @DateID AS INT, @PeriodTypeID AS INT
--Set @DateID = 33
--Set @PeriodTypeID = 1

Insert INTO [MI].[Uplift_Results_Table]
      ([Programid]
      ,[PartnerGroupID]
      ,[PartnerID]
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders])

--	select   warehouse.stratification.greatest(2,1), warehouse.stratification.least(2,1)

select CW.[Programid]
      ,CW.[PartnerGroupID]
      ,CW.[PartnerID]
      ,CW.[ClientServiceRef]
      ,CW.[PaymentTypeID]
      ,CW.[ChannelID]
      ,CW.[CustomerAttributeID]
      ,CW.[Mid_SplitID]
      ,CW.[CumulativeTypeID]
      ,CW.[PeriodTypeID]
      ,CW.[DateID]
,CASE WHEN CW.AdjFactorSPC IS NULL OR CW.AdjFactorSPC=0 THEN NULL ELSE CONVERT(float,stratification.least((1.0*MW.MembersSales/MW.MembersCardholders-1.0*CW.AdjFactorSPC*CW.Controlsales/CW.ControlCardHolders)*Mw.MembersCardholders,1.0*MW.MembersPostActivationSales))/
CONVERT(float, stratification.greatest(1.0,1.0*MW.MembersPostActivationSales-((1.0*MW.MembersSales/MW.MembersCardholders-1.0*CW.AdjFactorSPC*CW.Controlsales/CW.ControlCardholders)*Mw.MembersCardholders)) ) END as UpliftSales

,CASE WHEN CW.AdjFactorTPC IS NULL OR CW.AdjFactorTPC=0 THEN NULL ELSE CONVERT(float, stratification.least((1.0*MW.MembersTransactions /MW.MembersCardholders-1.0*CW.AdjFactorTPC*CW.ControlTransactions/CW.ControlCardHolders)*Mw.MembersCardholders,1.0*MW.MembersPostActivationTransactions))/
CONVERT(float, stratification.greatest(1.0,1.0*MW.MembersPostActivationTransactions-((1.0*MW.MembersTransactions/MW.MembersCardholders-1.0*CW.AdjFactorTPC*CW.ControlTransactions/CW.ControlCardholders)*Mw.MembersCardholders)) ) END as UpliftTransactions

,CASE WHEN CW.AdjFactorRR IS NULL OR CW.AdjFactorRR=0 THEN NULL ELSE CONVERT(float, stratification.least((1.0*MW.MembersSpenders/MW.MembersCardholders-1.0*CW.AdjFactorRR*CW.ControlSpenders/CW.ControlCardHolders)*Mw.MembersCardholders,1.0*MW.MembersPostActivationSpenders))/
CONVERT(float, stratification.greatest(1.0,1.0*MW.MembersPostActivationSpenders-((1.0*MW.MembersSpenders/MW.MembersCardholders-1.0*CW.AdjFactorRR*CW.ControlSpenders/CW.ControlCardholders)*Mw.MembersCardholders)) ) END as UpliftSpenders

	  from 
MI.ControlSalesWorking CW
inner join MI.MemberssalesWorking MW
on CW.[Programid] =MW.[Programid]
      and CW.[PartnerGroupID] = MW.[PartnerGroupID]
      and CW.[PartnerID] = MW.[PartnerID]
      and CW.[ClientServiceRef] = MW.[ClientServiceRef]
      and CW.[PaymentTypeID] = MW.[PaymentTypeID]
      and CW.[ChannelID] = MW.ChannelID 
      And CW.[CustomerAttributeID] = MW.[CustomerAttributeID]
      And CW.[Mid_SplitID] = MW.Mid_SplitID
      And CW.[CumulativeTypeID] = MW.[CumulativeTypeID]
      And CW.[PeriodTypeID] = MW.PeriodTypeID
      And CW.[DateID] = MW.DateID
inner join MI.INSchemeSalesWorking IW
on CW.[Programid] =IW.[Programid]
      and CW.[PartnerGroupID] = IW.[PartnerGroupID]
      and CW.[PartnerID] = IW.[PartnerID]
      and CW.[ClientServiceRef] = IW.[ClientServiceRef]
      and CW.[PaymentTypeID] = IW.[PaymentTypeID]
      and CW.[ChannelID] = IW.ChannelID 
      And CW.[CustomerAttributeID] = IW.[CustomerAttributeID]
      And CW.[Mid_SplitID] = IW.Mid_SplitID
      And CW.[CumulativeTypeID] = IW.[CumulativeTypeID]
      And CW.[PeriodTypeID] = IW.PeriodTypeID
      And CW.[DateID] = IW.DateID
where (CW.AdjFactorRR is not null or CW.AdjFactorSPC is not null or CW.AdjFactorTPC is not null) 
AND (@PartnerID IS NULL OR cw.PartnerID = @PartnerID)
and (CW.AdjFactorRR <> 0 or CW.AdjFactorSPC <> 0 or CW.AdjFactorTPC <> 0) and
CW.DateID = @DateID --and CW.PeriodTypeID = @PeriodTypeID
and Mw.MembersCardholders > 0

END


--select  stratification.least(5,311919)