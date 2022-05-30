CREATE TABLE [Processing].[MerchantLocation] (
    [ConsumerCombinationID] INT          NULL,
    [LocationAddress]       VARCHAR (50) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Processing_merchantlocation]
    ON [Processing].[MerchantLocation]([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated table that holds the latest Location for each ConsumerCombinationID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantLocation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ConsumerCombinationID for linking between Client facing data and internal data', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantLocation', @level2type = N'COLUMN', @level2name = N'ConsumerCombinationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The address as found on the Processing.MerchantLocation table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'MerchantLocation', @level2type = N'COLUMN', @level2name = N'LocationAddress';

