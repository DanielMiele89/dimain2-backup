CREATE TABLE [MI].[SSAS_DimRetailerPublisher] (
    [RetailerPublisherID] INT          IDENTITY (1, 1) NOT NULL,
    [RetailerName]        VARCHAR (50) NOT NULL,
    [PublisherName]       VARCHAR (50) NOT NULL,
    [PartnerID]           INT          NOT NULL,
    [StartDate]           DATE         NOT NULL,
    [EndDate]             DATE         NULL,
    CONSTRAINT [PK_MI_SSAS_DimRetailerPublisher] PRIMARY KEY CLUSTERED ([RetailerPublisherID] ASC)
);

