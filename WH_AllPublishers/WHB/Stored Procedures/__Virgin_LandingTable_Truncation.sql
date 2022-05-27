

CREATE PROC [WHB].[__Virgin_LandingTable_Truncation]
AS
	DECLARE @SourceSystemID INT = 3


	TRUNCATE TABLE [Inbound].[Virgin_Customer]
	TRUNCATE TABLE [Inbound].[Virgin_IronOffer]
	TRUNCATE TABLE [Inbound].[Virgin_PartnerTrans]

	EXEC WHB.TableLoadStatus_Reset @SourceSystemID
