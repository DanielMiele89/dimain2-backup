CREATE TABLE [iron].[PrimaryRetailerIdentification_Accounts] (
    [PartnerID]        INT NOT NULL,
    [PrimaryPartnerID] INT NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC),
    CONSTRAINT [ucPrimaryRetailerIdentication_Accounts] UNIQUE NONCLUSTERED ([PartnerID] ASC, [PrimaryPartnerID] ASC)
);

