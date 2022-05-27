CREATE TABLE [Segmentation].[ConsumerCombinationsToSegment] (
    [PartnerID]             INT NULL,
    [ConsumerCombinationID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_PartnerCC]
    ON [Segmentation].[ConsumerCombinationsToSegment]([PartnerID] ASC, [ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90);

