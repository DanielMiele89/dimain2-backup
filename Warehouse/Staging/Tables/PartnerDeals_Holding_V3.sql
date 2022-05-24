CREATE TABLE [Staging].[PartnerDeals_Holding_V3] (
    [ID]              INT            NULL,
    [ClubID]          INT            NULL,
    [PartnerID]       INT            NULL,
    [ManagedBy]       NVARCHAR (255) NULL,
    [StartDate]       NVARCHAR (255) NULL,
    [EndDate]         NVARCHAR (255) NULL,
    [Override]        NVARCHAR (255) NULL,
    [PlatformFee]     NVARCHAR (255) NULL,
    [AccMgmtFee]      NVARCHAR (255) NULL,
    [OfferSourceFee]  NVARCHAR (255) NULL,
    [DistributionFee] NVARCHAR (255) NULL,
    [FixedOverride]   NVARCHAR (255) NULL
);

