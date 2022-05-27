

CREATE PROC [WHB].[__RBS_LandingTable_Truncation]
AS
	DECLARE @SourceSystemID INT = 1


	TRUNCATE TABLE [Inbound].[RBS_Customer]
	TRUNCATE TABLE [Inbound].[RBS_IronOffer]
	TRUNCATE TABLE [Inbound].[RBS_PartnerTrans]

	EXEC WHB.TableLoadStatus_Reset @SourceSystemID
