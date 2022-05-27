CREATE TABLE [MI].[SomeTable] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] NVARCHAR (30) NULL,
    [IronOfferID]       INT           NULL,
    [ShopperSegmentID]  SMALLINT      NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

