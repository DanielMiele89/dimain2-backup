CREATE TABLE [Selections].[__PartnerAccountManager_Archived] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT           NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [AccountManager] VARCHAR (100) NULL,
    [StartDate]      DATE          NULL,
    [EndDate]        DATE          NULL
);

