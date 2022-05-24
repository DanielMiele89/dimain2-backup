CREATE TABLE [Staging].[BrandReporExcludelist] (
    [ID]   INT          IDENTITY (1, 1) NOT NULL,
    [Word] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Word]
    ON [Staging].[BrandReporExcludelist]([Word] ASC);

