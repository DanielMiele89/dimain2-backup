CREATE TABLE [dbo].[TestSplitOwnership] (
    [Item]  INT      NOT NULL,
    [Owner] CHAR (1) NOT NULL,
    CONSTRAINT [PK_TestSplitOwnership] PRIMARY KEY CLUSTERED ([Item] ASC, [Owner] ASC)
);

