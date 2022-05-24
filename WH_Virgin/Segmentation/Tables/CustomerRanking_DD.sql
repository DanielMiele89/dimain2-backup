CREATE TABLE [Segmentation].[CustomerRanking_DD] (
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    [Ranking]   INT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [PartnerID] ASC)
);

