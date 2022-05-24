CREATE TABLE [Staging].[Customer_TobeExcluded] (
    [FanID] INT NULL
);


GO
CREATE CLUSTERED INDEX [idx_Customer_TobeExcluded_FanID]
    ON [Staging].[Customer_TobeExcluded]([FanID] ASC);

