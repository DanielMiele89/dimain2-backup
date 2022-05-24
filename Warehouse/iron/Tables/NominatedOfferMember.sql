CREATE TABLE [iron].[NominatedOfferMember] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [Date]        DATETIME CONSTRAINT [DF_NominatedOfferMember_Date] DEFAULT (getdate()) NULL,
    [IsControl]   BIT      CONSTRAINT [DF_NominatedOfferMember_IsControl] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_NominatedOfferMember] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IUX_NominatedOfferMember_IronOfferIDCompositeID]
    ON [iron].[NominatedOfferMember]([IronOfferID] ASC, [CompositeID] ASC);

