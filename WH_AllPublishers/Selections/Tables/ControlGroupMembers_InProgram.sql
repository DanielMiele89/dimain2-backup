CREATE TABLE [Selections].[ControlGroupMembers_InProgram] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [PublisherID]          INT          NOT NULL,
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (10) NOT NULL,
    [IronOfferID]          INT          NOT NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [FanID]                INT          NOT NULL,
    [PercentageTaken]      INT          NOT NULL,
    [ExcludeFromAnalysis]  BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_StartPubCSR]
    ON [Selections].[ControlGroupMembers_InProgram]([StartDate] ASC, [PublisherID] ASC, [ClientServicesRef] ASC) WITH (FILLFACTOR = 70);


GO
CREATE NONCLUSTERED INDEX [ix_ClientServicesRef_StartDate]
    ON [Selections].[ControlGroupMembers_InProgram]([ClientServicesRef] ASC, [StartDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_PublisherID_ClientServicesRef_StartDate]
    ON [Selections].[ControlGroupMembers_InProgram]([PublisherID] ASC, [ClientServicesRef] ASC, [StartDate] ASC) WITH (FILLFACTOR = 90);

