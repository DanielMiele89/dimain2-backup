CREATE TABLE [InsightArchive].[nFI_Partner_Deals_Archive] (
    [ID]            INT            NOT NULL,
    [ClubID]        INT            NULL,
    [PartnerID]     INT            NULL,
    [ManagedBy]     VARCHAR (100)  NULL,
    [StartDate]     DATE           NULL,
    [EndDate]       DATE           NULL,
    [Override]      DECIMAL (5, 2) NULL,
    [Publisher]     DECIMAL (5, 2) NULL,
    [Reward]        DECIMAL (5, 2) NULL,
    [FixedOverride] BIT            NULL
);

