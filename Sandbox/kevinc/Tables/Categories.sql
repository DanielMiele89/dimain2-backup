CREATE TABLE [kevinc].[Categories] (
    [categoryid]   INT            IDENTITY (1, 1) NOT NULL,
    [categoryname] NVARCHAR (15)  NOT NULL,
    [description]  NVARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([categoryid] ASC)
);


GO
CREATE NONCLUSTERED INDEX [categoryname]
    ON [kevinc].[Categories]([categoryname] ASC);

