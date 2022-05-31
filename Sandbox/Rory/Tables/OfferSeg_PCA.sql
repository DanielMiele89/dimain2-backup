CREATE TABLE [Rory].[OfferSeg_PCA] (
    [ID]           UNIQUEIDENTIFIER NULL,
    [CustomerGUID] UNIQUEIDENTIFIER NOT NULL,
    [OfferGUID]    UNIQUEIDENTIFIER NULL,
    [StartDate]    VARCHAR (35)     NULL,
    [EndDate]      VARCHAR (35)     NULL,
    [FileNum]      BIGINT           NULL
);

