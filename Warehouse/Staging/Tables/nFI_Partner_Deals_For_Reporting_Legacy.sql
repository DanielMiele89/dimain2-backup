CREATE TABLE [Staging].[nFI_Partner_Deals_For_Reporting_Legacy] (
    [ID]           INT            NULL,
    [ClubID]       INT            NULL,
    [PartnerID]    INT            NULL,
    [IntroducedBy] VARCHAR (100)  NULL,
    [ManagedBy]    VARCHAR (100)  NULL,
    [CurrentDeal]  INT            NOT NULL,
    [StartDate]    DATE           NULL,
    [EndDate]      DATE           NULL,
    [Cashback]     DECIMAL (5, 4) NULL,
    [Publisher]    DECIMAL (5, 4) NULL,
    [Reward]       DECIMAL (5, 4) NULL
);

