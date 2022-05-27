CREATE TABLE [Report].[IronOffer_References] (
    [ID]                   INT            IDENTITY (1, 1) NOT NULL,
    [IronOfferID]          INT            NOT NULL,
    [ClubID]               INT            NOT NULL,
    [OfferCyclesID]        INT            NULL,
    [IronOfferCyclesID]    INT            NULL,
    [ControlGroupID]       INT            NOT NULL,
    [ControlGroupTypeID]   INT            NOT NULL,
    [ControlGroupType]     VARCHAR (30)   NOT NULL,
    [StartDate]            DATE           NULL,
    [EndDate]              DATE           NULL,
    [SuperSegmentID]       SMALLINT       NULL,
    [SuperSegmentName]     VARCHAR (40)   NULL,
    [SegmentID]            SMALLINT       NULL,
    [SegmentName]          VARCHAR (40)   NULL,
    [OfferTypeID]          INT            NOT NULL,
    [OfferTypeDescription] VARCHAR (50)   NOT NULL,
    [CashbackRate]         REAL           NULL,
    [SpendStretch]         SMALLMONEY     NULL,
    [SpendStretchRate]     REAL           NULL,
    [IronOfferName]        NVARCHAR (200) NULL,
    [PartnerID]            SMALLINT       NULL,
    [OfferReportCyclesID]  INT            NULL,
    [OfferSetupStartDate]  DATE           NULL,
    [OfferSetupEndDate]    DATE           NULL,
    [ClientServicesRef]    VARCHAR (50)   NULL,
    [OfferTypeForReports]  VARCHAR (100)  NOT NULL,
    CONSTRAINT [PK_IronRefsID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_IronOffer_References]
    ON [Report].[IronOffer_References]([ControlGroupTypeID] ASC)
    INCLUDE([IronOfferID], [ClubID], [IronOfferCyclesID], [StartDate], [EndDate], [IronOfferName], [OfferReportCyclesID]);


GO
CREATE NONCLUSTERED INDEX [NCIX2_IronOffer_References]
    ON [Report].[IronOffer_References]([IronOfferID] ASC, [IronOfferCyclesID] ASC, [ControlGroupTypeID] ASC, [StartDate] ASC, [EndDate] ASC)
    INCLUDE([ClubID], [IronOfferName], [OfferReportCyclesID]);

