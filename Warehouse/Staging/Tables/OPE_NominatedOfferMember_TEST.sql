CREATE TABLE [Staging].[OPE_NominatedOfferMember_TEST] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [Date]        DATETIME CONSTRAINT [DF_NominatedOfferMember_Date] DEFAULT (getdate()) NULL,
    [IsControl]   BIT      CONSTRAINT [DF_NominatedOfferMember_IsControl] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_OPE_NominatedOfferMember_TEST] PRIMARY KEY CLUSTERED ([ID] ASC)
);

