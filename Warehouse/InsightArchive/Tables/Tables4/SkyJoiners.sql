CREATE TABLE [InsightArchive].[SkyJoiners] (
    [SegmentationDate] DATE NULL,
    [BankAccountID]    INT  NULL
);


GO
CREATE CLUSTERED INDEX [cix_BankAccountID]
    ON [InsightArchive].[SkyJoiners]([BankAccountID] ASC);

