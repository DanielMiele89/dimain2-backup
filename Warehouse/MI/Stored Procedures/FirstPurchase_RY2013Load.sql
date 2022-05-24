-- =============================================
-- Author:		<Adam scott>
-- Create date: <10/10/2013>
-- Description:	<FirstPurchase_RY2013Load>
-- =============================================
CREATE PROCEDURE MI.FirstPurchase_RY2013Load 
	(
		@MonthID Int
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	If object_id('tempdb..#fpac') is not null drop table #fpac
select p.PartnerID, SUTM.ID MonthID, count(distinct c.FanID) ActivatedCardholders,
		count(distinct case when fp.FanID is null then c.FanID end) FP_ActivatedCardholders,
		count(distinct case when fp.FanID is null and sut.FanID is not null then c.FanID end) FP_ActivatedSpender
		into #fpac
		From Warehouse.Relational.Customer	c
		cross join 
			(select distinct PartnerId from warehouse.relational.partner) p
		cross join 
			Relational.SchemeUpliftTrans_Month SUTM
		left join 
			Warehouse.[Stratification].FirstPurchase_RY2013 fp 
		on fp.FAnID=c.FanID and p.PartnerID=fp.PartnerID and fp.MinMonth<SUTM.ID
		left join 
			[Relational].[SchemeUpliftTrans] sut 
		on sut.FanID=c.FanID and sut.AddedDate between SUTM.StartDate and SUTM.Enddate and Sut.PArtnerId=p.partnerID and isretailreport=1 and Amount>0 
		Where exists (select 1 from  Warehouse.MI.CustomerActivationPeriod cap 
			where cap.ActivationStart   <= SUTM.EndDate	/*Take all active customers at the end of the reporting month*/
			and	  (cap.ActivationEnd >= SUTM.StartDate or cap.ActivationEnd is null)
			and cap.FanID=c.FanID)
			and SUTM.ID=@MonthID 
		group by SUTM.ID, p. partnerid 

-- Control Cardholders
If object_id('tempdb..#fpcc') is not null drop table #fpcc
select p.PartnerID, SUTM.ID MonthID, count(distinct c.FanID) ControlCardholders,
		count(distinct case when fp.FanID is null then c.FanID end) FP_ControlCardholders,
		count(distinct case when fp.FanID is null and sut.FanID is not null then c.FanID end) FP_ControlSpender
		into #fpcc
		from Relational.Control_Stratified C
		cross join 
			(select distinct PartnerId from warehouse.relational.partner where partnerid not in (select partnerid from Relational.Control_Stratified) ) p
		inner join
			 Relational.SchemeUpliftTrans_Month SUTM 
		on c.MonthId=SUTM.ID
		left join 
			Warehouse.[Stratification].FirstPurchase_RY2013 fp 
		on fp.FAnID=c.FanID and p.PartnerID=fp.PartnerID and fp.MinMonth<SUTM.ID
		left join 
			[Relational].[SchemeUpliftTrans] sut 
		on sut.FanID=c.FanID and sut.AddedDate between SUTM.StartDate and SUTM.Enddate and Sut.PartnerId=p.partnerID and isretailreport=1 and Amount>0 
		where C.PartnerID =0
		and SUTM.ID=@MonthID 
		group by SUTM.ID, p. partnerid
		union
		select c.PartnerID, SUTM.ID MonthID, count(distinct c.FanID) ControlCardholders,
		count(distinct case when fp.FanID is null then c.FanID end) FP_ControlCardholders,
		count(distinct case when fp.FanID is null and sut.FanID is not null then c.FanID end) FP_ControlSpender
		from Relational.Control_Stratified C
		inner join 
			Relational.SchemeUpliftTrans_Month SUTM 
		on c.MonthId=SUTM.ID
		left join 
			Warehouse.[Stratification].FirstPurchase_RY2013 fp 
		on fp.FAnID=c.FanID and c.PartnerID=fp.PartnerID and fp.MinMonth<SUTM.ID
		left join 
			[Relational].[SchemeUpliftTrans] sut 
		on sut.FanID=c.FanID and sut.AddedDate between SUTM.StartDate and SUTM.Enddate and Sut.PartnerId=c.partnerID and isretailreport=1 and Amount>0
		where C.PartnerID <>0
		and SUTM.ID=@MonthID
		group by SUTM.ID, c. partnerid

		select * from #fpac


END