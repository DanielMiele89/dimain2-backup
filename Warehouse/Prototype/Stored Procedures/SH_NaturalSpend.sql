CREATE PROCEDURE Prototype.SH_NaturalSpend 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select distinct BrandName
				,BrandID
				,Publisher
				,Timepoint
				,Segment
				,Perbase
				,case when RR is null then 0 else RR end as RR
				,case when SPS is null then 0 else SPS end as SPS
				,avgw_spder
				,case when SPC is null then 0 else SPC end as SPC
				,case when RR_Instore is null then 0 else RR_Instore end as RR_Instore
				,case when RBS_SPS_InStore is null then 0 else RBS_SPS_InStore end as RBS_SPS_InStore
				,avgw_spder_Instore
				,case when SPC_Instore is null then 0 else SPC_Instore end as SPC_Instore
				,RRScale
				,case when RBS_RR is null then 0 else RBS_RR end as RBS_RR
				,case when RBS_RR_Instore is null then 0 else RBS_RR_Instore end as RBS_RR_Instore
from  warehouse.Prototype.ROCP2_NaturalSalesPub_FinalOutput2 
END
