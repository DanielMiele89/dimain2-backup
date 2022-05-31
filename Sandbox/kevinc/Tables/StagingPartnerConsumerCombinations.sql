CREATE TABLE [kevinc].[StagingPartnerConsumerCombinations] (
    [ConsumerCombinationID] INT NOT NULL,
    [PartnerID]             INT NOT NULL,
    [BrandID]               INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [StagingPartnerConsumerCombinations_ConsumerCombinationID]
    ON [kevinc].[StagingPartnerConsumerCombinations]([ConsumerCombinationID] ASC);

