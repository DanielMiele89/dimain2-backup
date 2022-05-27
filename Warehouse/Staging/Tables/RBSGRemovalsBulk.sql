CREATE TABLE [Staging].[RBSGRemovalsBulk] (
    [OIN]         INT  NULL,
    [RemovalDate] DATE NULL
);


GO
CREATE CLUSTERED INDEX [cix_RBSGRemovalsBulk_OIN]
    ON [Staging].[RBSGRemovalsBulk]([OIN] ASC);

