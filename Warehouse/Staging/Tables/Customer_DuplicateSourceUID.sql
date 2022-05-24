CREATE TABLE [Staging].[Customer_DuplicateSourceUID] (
    [SourceUID] VARCHAR (20) NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL,
    [ID]        INT          IDENTITY (1, 1) NOT NULL
);


GO
CREATE CLUSTERED INDEX [cx_SourceUID]
    ON [Staging].[Customer_DuplicateSourceUID]([SourceUID] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [uix_SourceUID]
    ON [Staging].[Customer_DuplicateSourceUID]([SourceUID] ASC);

