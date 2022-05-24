CREATE TABLE [iron].[PrimaryRetailerIdentification] (
    [PartnerID]        INT NOT NULL,
    [PrimaryPartnerID] INT NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC),
    CONSTRAINT [ucPrimaryRetailerIdentication] UNIQUE NONCLUSTERED ([PartnerID] ASC, [PrimaryPartnerID] ASC)
);

