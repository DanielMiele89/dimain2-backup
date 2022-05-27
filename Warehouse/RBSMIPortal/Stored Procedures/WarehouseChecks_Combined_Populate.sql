
/*-----------------------------------------------
Created by: Zoe Taylor 
Date Created: 16/06/2019

-----------------------------------------------*/

CREATE PROCEDURE RBSMIPortal.WarehouseChecks_Combined_Populate
as 
begin


		DECLARE @startdate date = DATEADD(m, -1, getdate())
			, @EndDate_PT date = (select * from RBSMIPortal.SchemeCashback_PT_AddedDateLoaded)
			, @EndDate_ACBA date = (select * from RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded)
			, @EndDate_ACBAJ date = (select * from RBSMIPortal.SchemeCashback_ACAJ_AddedDateLoaded)
	
	
		Insert into Warehouse.RBSMIPortal.WarehouseChecks_Combined
		select 'PartnerTrans' [Table]
			, addeddate
			, COUNT(*)
			, SUM(cashbackearned)
		from Relational.PartnerTrans with (nolock)
		where AddedDate between @StartDate and @EndDate_PT
		group by AddedDate 
		order by AddedDate desc


		Insert into Warehouse.RBSMIPortal.WarehouseChecks_Combined
		select 'AdditionalCashbackAward' [Table]
			, addeddate
			, COUNT(*)
			, SUM(cashbackearned)
		from Relational.AdditionalCashbackAward with (nolock)
		where AddedDate between @StartDate and @EndDate_ACBA
		group by AddedDate 
		order by AddedDate desc


		Insert into Warehouse.RBSMIPortal.WarehouseChecks_Combined
		select 'AdditionalCashbackAdjust' [Table]
			, addeddate
			, COUNT(*)
			, SUM(cashbackearned)
		from Relational.AdditionalCashbackAdjustment a with (nolock)
		INNER JOIN Relational.AdditionalCashbackAdjustmentType at ON a.AdditionalCashbackAdjustmentTypeID = at.AdditionalCashbackAdjustmentTypeID
		where AddedDate between @StartDate and @EndDate_ACBAJ
		and AdditionalCashbackAdjustmentCategoryID > 1
		group by AddedDate 
		order by AddedDate desc


End --sproc
