CREATE PROCEDURE [Staging].[WarehouseLoad_ETL_SoW_V1_0]
AS

BEGIN

DECLARE @EDate DATE = (	SELECT MIN(EmailDate)
						FROM [Selections].[ROCShopperSegment_PreSelection_ALS]
						WHERE GETDATE() < EmailDate)

EXEC [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3] @EDate
EXEC [Segmentation].[Segmentation_CloseDeactivatedCustomers]

EXEC [Lion].[OPE_CustomerRelevance]

END