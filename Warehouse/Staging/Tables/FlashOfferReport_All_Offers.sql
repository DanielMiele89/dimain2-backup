CREATE TABLE [Staging].[FlashOfferReport_All_Offers] (
    [ID]                  INT            IDENTITY (1, 1) NOT NULL,
    [IronOfferID]         INT            NOT NULL,
    [StartDate]           DATE           NOT NULL,
    [EndDate]             DATE           NOT NULL,
    [OfferSetupStartDate] DATE           NOT NULL,
    [OfferSetupEndDate]   DATE           NULL,
    [IOCycleStartDate]    DATE           NOT NULL,
    [IOCycleEndDate]      DATE           NOT NULL,
    [PeriodType]          VARCHAR (25)   NOT NULL,
    [IronOfferName]       NVARCHAR (200) NULL,
    [PartnerID]           INT            NULL,
    [SubPartnerID]        INT            NULL,
    [PartnerName]         VARCHAR (100)  NULL,
    [ClubID]              INT            NULL,
    [IsWarehouse]         INT            NULL,
    [IronOfferCyclesID]   INT            NULL,
    [ControlGroupID]      INT            NOT NULL,
    [SpendStretch]        MONEY          NULL,
    [ControlGroupTypeID]  INT            NULL,
    [CalculationDate]     DATE           NOT NULL,
    CONSTRAINT [PK_FlashOfferReport_All_Offers] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [AK_FlashOfferReport_All_Offers_ControlGroup] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [ControlGroupID] ASC, [ControlGroupTypeID] ASC, [StartDate] ASC, [EndDate] ASC, [PeriodType] ASC, [IsWarehouse] ASC, [IronOfferCyclesID] ASC),
    CONSTRAINT [AK_FlashOfferReport_All_Offers_IOC] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [IronOfferCyclesID] ASC, [ControlGroupTypeID] ASC, [StartDate] ASC, [EndDate] ASC, [PeriodType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_FlashOfferReport_All_Offers]
    ON [Staging].[FlashOfferReport_All_Offers]([IronOfferID] ASC, [IsWarehouse] ASC, [ControlGroupTypeID] ASC, [StartDate] ASC, [EndDate] ASC, [PeriodType] ASC);

