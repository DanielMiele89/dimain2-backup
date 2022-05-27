CREATE TABLE [Staging].[OfferReport_CardholdersAgg] (
    [ID]                 INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID]          INT  NULL,
    [Cardholders]        INT  NULL,
    [Cardholders_C]      INT  NULL,
    [ControlGroupTypeID] INT  NOT NULL,
    [StartDate]          DATE NULL,
    [EndDate]            DATE NULL,
    [ClubID]             INT  NULL,
    CONSTRAINT [PK_CardAggID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

