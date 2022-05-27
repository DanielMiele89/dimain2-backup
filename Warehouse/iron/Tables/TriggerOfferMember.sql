CREATE TABLE [iron].[TriggerOfferMember] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NOT NULL,
    [Date]        DATETIME CONSTRAINT [DF_TriggerOfferMember_Date] DEFAULT (getdate()) NULL,
    [IsControl]   BIT      CONSTRAINT [DF_TriggerOfferMember_IsControl] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_TriggerOfferMember] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [IUX_TriggerOfferMember_IronOfferCompositeStartEnd] UNIQUE NONCLUSTERED ([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC, [EndDate] ASC)
);




GO
GRANT UPDATE
    ON OBJECT::[iron].[TriggerOfferMember] TO [DataMart]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[iron].[TriggerOfferMember] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[iron].[TriggerOfferMember] TO [DataMart]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[iron].[TriggerOfferMember] TO [DataMart]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[iron].[TriggerOfferMember] TO [DataMart]
    AS [dbo];

