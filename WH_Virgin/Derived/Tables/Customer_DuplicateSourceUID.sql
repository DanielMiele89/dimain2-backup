CREATE TABLE [Derived].[Customer_DuplicateSourceUID] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [SourceUID] VARCHAR (20) NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cx_CDS]
    ON [Derived].[Customer_DuplicateSourceUID]([ID] ASC);

