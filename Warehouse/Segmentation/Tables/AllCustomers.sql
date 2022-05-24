CREATE TABLE [Segmentation].[AllCustomers] (
    [FanID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanIDSegment]
    ON [Segmentation].[AllCustomers]([FanID] ASC) WITH (FILLFACTOR = 90);

