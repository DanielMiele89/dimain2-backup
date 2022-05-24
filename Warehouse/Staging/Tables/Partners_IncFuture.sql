CREATE TABLE [Staging].[Partners_IncFuture] (
    [PartnerID]      INT           NOT NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [BrandID]        INT           NULL,
    [BrandName]      VARCHAR (100) NULL,
    [SequenceNumber] INT           IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([SequenceNumber] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCIX_Partners_IncFuture]
    ON [Staging].[Partners_IncFuture]([PartnerID] ASC);

