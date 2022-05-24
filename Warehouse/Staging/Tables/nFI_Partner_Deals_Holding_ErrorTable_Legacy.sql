CREATE TABLE [Staging].[nFI_Partner_Deals_Holding_ErrorTable_Legacy] (
    [ID]                   INT           NULL,
    [ID_Check]             VARCHAR (100) NOT NULL,
    [ClubID]               VARCHAR (100) NOT NULL,
    [PartnerID]            VARCHAR (100) NOT NULL,
    [IntroducedBy]         VARCHAR (100) NOT NULL,
    [ManagedBy]            VARCHAR (100) NOT NULL,
    [StartDate]            VARCHAR (100) NOT NULL,
    [EndDate]              VARCHAR (100) NOT NULL,
    [Cashback]             VARCHAR (100) NOT NULL,
    [Publisher]            VARCHAR (100) NOT NULL,
    [Reward]               VARCHAR (100) NOT NULL,
    [TotalPercentage]      VARCHAR (100) NULL,
    [TotalExistingChanges] VARCHAR (100) NULL
);

