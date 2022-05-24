CREATE TABLE [Staging].[Headroom_ActInitialBase] (
    [RowNo]      INT IDENTITY (1, 1) NOT NULL,
    [CinID]      INT NOT NULL,
    [CBCustomer] BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([RowNo] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_Headroom_ActInitialBase_CinID]
    ON [Staging].[Headroom_ActInitialBase]([CinID] ASC);

