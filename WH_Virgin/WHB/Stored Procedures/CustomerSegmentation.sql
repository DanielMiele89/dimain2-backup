CREATE PROCEDURE [WHB].[CustomerSegmentation]
AS

BEGIN

DECLARE @EDate DATE = (	SELECT MIN([Selections].[CampaignSetup_POS].[EmailDate])
						FROM [Selections].[CampaignSetup_POS]
						WHERE GETDATE() < [Selections].[CampaignSetup_POS].[EmailDate])

EXEC [Segmentation].[Segmentation_CloseDeactivatedCustomers]
EXEC [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3] @EDate

EXEC [Email].[OPE_CustomerRelevance]

END