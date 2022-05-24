CREATE TABLE [Staging].[Gabor_CTCustomersCINID] (
    [GroupID]     INT NOT NULL,
    [CINID]       INT NOT NULL,
    [Exposed]     BIT NOT NULL,
    [PublisherID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CinGroup]
    ON [Staging].[Gabor_CTCustomersCINID]([CINID] ASC, [GroupID] ASC, [Exposed] ASC, [PublisherID] ASC);

