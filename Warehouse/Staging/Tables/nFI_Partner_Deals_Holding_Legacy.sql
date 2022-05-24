CREATE TABLE [Staging].[nFI_Partner_Deals_Holding_Legacy] (
    [ID]           INT            NULL,
    [ClubID]       INT            NULL,
    [PartnerID]    INT            NULL,
    [BrandID]      INT            NULL,
    [IntroducedBy] NVARCHAR (255) NULL,
    [ManagedBy]    NVARCHAR (255) NULL,
    [StartDate]    NVARCHAR (255) NULL,
    [EndDate]      NVARCHAR (255) NULL,
    [Cashback]     FLOAT (53)     NULL,
    [Publisher]    FLOAT (53)     NULL,
    [Reward]       FLOAT (53)     NULL
);

