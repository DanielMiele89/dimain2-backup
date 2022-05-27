CREATE TABLE [Staging].[nFIPartnerDeals_Holding_V2] (
    [ID]            INT             NULL,
    [ClubID]        INT             NULL,
    [PartnerID]     INT             NULL,
    [ManagedBy]     NVARCHAR (255)  NULL,
    [StartDate]     NVARCHAR (255)  NULL,
    [EndDate]       NVARCHAR (255)  NULL,
    [Override]      DECIMAL (32, 3) NULL,
    [Publisher]     NVARCHAR (255)  NULL,
    [Reward]        NVARCHAR (255)  NULL,
    [FixedOverride] NVARCHAR (255)  NULL
);

