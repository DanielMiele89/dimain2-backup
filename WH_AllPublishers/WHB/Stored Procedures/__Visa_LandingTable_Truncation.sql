

CREATE PROC [WHB].[__Visa_LandingTable_Truncation]
AS
	DECLARE @SourceSystemID INT = 4


	TRUNCATE TABLE [Inbound].[Visa_Customer]
	TRUNCATE TABLE [Inbound].[Visa_IronOffer]
	TRUNCATE TABLE [Inbound].[Visa_PartnerTrans]

	EXEC WHB.TableLoadStatus_Reset @SourceSystemID
