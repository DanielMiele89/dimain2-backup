CREATE TABLE [Reporting].[ERF_ClosedBuckets] (
    [Customers]         INT             NULL,
    [PublisherID]       SMALLINT        NOT NULL,
    [DeactivatedBandID] SMALLINT        NOT NULL,
    [DeactivatedBand]   VARCHAR (50)    NULL,
    [BucketName]        VARCHAR (9)     NOT NULL,
    [BucketID]          INT             NOT NULL,
    [isCreditCardOnly]  BIT             NULL,
    [TotalBalance]      DECIMAL (38, 2) NULL
);

