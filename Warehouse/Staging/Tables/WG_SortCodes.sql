CREATE TABLE [Staging].[WG_SortCodes] (
    [Sortcode] VARCHAR (6) NOT NULL,
    PRIMARY KEY CLUSTERED ([Sortcode] ASC),
    UNIQUE NONCLUSTERED ([Sortcode] ASC)
);

