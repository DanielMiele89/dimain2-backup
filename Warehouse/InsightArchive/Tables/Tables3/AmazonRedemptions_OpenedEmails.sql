CREATE TABLE [InsightArchive].[AmazonRedemptions_OpenedEmails] (
    [FanID]     INT  NOT NULL,
    [EmailDate] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [EmailDate] ASC)
);

