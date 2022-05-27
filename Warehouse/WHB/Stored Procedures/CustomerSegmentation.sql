CREATE PROCEDURE [WHB].[CustomerSegmentation]
AS

BEGIN

DECLARE @EDate DATE = (	SELECT MIN(EmailDate)
						FROM [Selections].[CampaignSetup_POS]
						WHERE GETDATE() < EmailDate)

EXEC [Segmentation].[Segmentation_CloseDeactivatedCustomers]

PRINT CHAR(10)

EXEC [Segmentation].[Segmentation_Loop_POS] @EDate

EXEC [Lion].[OPE_CustomerRelevance]

END