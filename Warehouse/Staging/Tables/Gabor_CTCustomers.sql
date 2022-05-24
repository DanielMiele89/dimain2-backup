CREATE TABLE [Staging].[Gabor_CTCustomers] (
    [GroupID]     INT NOT NULL,
    [FanID]       INT NOT NULL,
    [Exposed]     BIT NOT NULL,
    [PublisherID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanIronEx]
    ON [Staging].[Gabor_CTCustomers]([FanID] ASC, [GroupID] ASC, [Exposed] ASC, [PublisherID] ASC);

