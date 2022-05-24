CREATE TABLE [Staging].[OfferReport_AllOffers_Errors] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]        INT           NOT NULL,
    [IronOfferCyclesID]  INT           NULL,
    [ControlGroupID]     INT           NOT NULL,
    [ControlGroupTypeID] INT           NOT NULL,
    [OfferStartDate]     DATE          NOT NULL,
    [OfferEndDate]       DATE          NOT NULL,
    [ErrorNotes]         VARCHAR (200) NULL,
    CONSTRAINT [PK_AllOfferErrorsID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

