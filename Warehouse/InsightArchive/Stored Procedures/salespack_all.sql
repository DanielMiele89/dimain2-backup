CREATE PROCEDURE insightarchive.salespack_all @sp_main_brand_id int,
@sp_firstbrandid int,
@sp_secondbrandid int,
@sp_thirdbrandid int,
@sp_forthbrandid int,
@sp_fifthbrandid int,
@sp_sixthbrandid int,
@sp_seventhtbrandid int,
@sp_eighthbrandid int
AS

EXEC insightarchive.salespack_brandaffinity_sp @main_brand_id = @sp_main_brand_id;
EXEC insightarchive.salespack_demographic_profiling_sp @main_brand_id = @sp_main_brand_id;
EXEC insightarchive.salespack_marketsharewinners_sp @main_brand_id=@sp_main_brand_id,
@firstbrandid=@sp_firstbrandid,
@secondbrandid=@sp_secondbrandid,
@thirdbrandid=@sp_thirdbrandid,
@forthbrandid=@sp_forthbrandid,
@fifthbrandid=@sp_fifthbrandid,
@sixthbrandid=@sp_sixthbrandid,
@seventhtbrandid=@sp_seventhtbrandid,
@eighthbrandid=@sp_eighthbrandid
EXEC insightarchive.salespack_marketshare_sp @main_brand_id=@sp_main_brand_id,
@firstbrandid=@sp_firstbrandid,
@secondbrandid=@sp_secondbrandid,
@thirdbrandid=@sp_thirdbrandid,
@forthbrandid=@sp_forthbrandid,
@fifthbrandid=@sp_fifthbrandid,
@sixthbrandid=@sp_sixthbrandid,
@seventhtbrandid=@sp_seventhtbrandid,
@eighthbrandid=@sp_eighthbrandid
EXEC insightarchive.salespack_sow_sp @sow_brand_id = @sp_main_brand_id,
@firstbrandid=@sp_firstbrandid,
@secondbrandid=@sp_secondbrandid,
@thirdbrandid=@sp_thirdbrandid,
@forthbrandid=@sp_forthbrandid,
@fifthbrandid=@sp_fifthbrandid,
@sixthbrandid=@sp_sixthbrandid,
@seventhtbrandid=@sp_seventhtbrandid,
@eighthbrandid=@sp_eighthbrandid
EXEC insightarchive.salespack_spenddistribution @brandid = @sp_main_brand_id;
EXEC insightarchive.salespack_storepostcodes @brandid = @sp_main_brand_id;
EXEC insightarchive.salespack_top_figures @brandid = @sp_main_brand_id;