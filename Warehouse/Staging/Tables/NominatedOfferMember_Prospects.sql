CREATE TABLE [Staging].[NominatedOfferMember_Prospects] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [Date]        DATETIME NULL,
    [IsControl]   BIT      NULL,
    CONSTRAINT [PK_NominatedOfferMemberP] PRIMARY KEY CLUSTERED ([ID] ASC)
);

