CREATE TABLE [Prototype].[nFI_Partner_Deals_V3] (
    [ID]              INT            NOT NULL,
    [ClubID]          INT            NULL,
    [PartnerID]       INT            NULL,
    [ManagedBy]       VARCHAR (100)  NULL,
    [StartDate]       DATE           NULL,
    [EndDate]         DATE           NULL,
    [Override]        DECIMAL (5, 2) NULL,
    [PlatformFee]     VARCHAR (20)   NULL,
    [AccMgmtFee]      VARCHAR (20)   NULL,
    [OfferSourceFee]  VARCHAR (20)   NULL,
    [DistributionFee] VARCHAR (20)   NULL,
    [FixedOverride]   BIT            NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

